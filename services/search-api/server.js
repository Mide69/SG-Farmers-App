const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const { Pool } = require('pg');
const redis = require('redis');
const winston = require('winston');
const { Client } = require('@elastic/elasticsearch');

const app = express();
const PORT = process.env.PORT || 3001;

// Logger setup
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// Redis connection
const redisClient = redis.createClient({
  url: process.env.REDIS_URL
});

redisClient.on('error', (err) => logger.error('Redis Client Error', err));
redisClient.connect();

// Elasticsearch connection
const esClient = new Client({
  node: process.env.ELASTICSEARCH_URL || 'http://localhost:9200'
});

// Initialize Elasticsearch index
async function initializeElasticsearch() {
  try {
    const indexExists = await esClient.indices.exists({ index: 'farmers' });
    if (!indexExists) {
      await esClient.indices.create({
        index: 'farmers',
        body: {
          mappings: {
            properties: {
              name: { type: 'text', analyzer: 'standard' },
              email: { type: 'keyword' },
              farm_location: { type: 'text', analyzer: 'standard' },
              crop_types: { type: 'text', analyzer: 'standard' },
              suggest: {
                type: 'completion',
                analyzer: 'simple',
                preserve_separators: true,
                preserve_position_increments: true,
                max_input_length: 50
              }
            }
          }
        }
      });
      logger.info('Elasticsearch farmers index created');
    }
  } catch (error) {
    logger.error('Elasticsearch initialization error:', error);
  }
}

initializeElasticsearch();

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200
});
app.use(limiter);

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    await redisClient.ping();
    await esClient.ping();
    res.status(200).json({ 
      status: 'healthy', 
      timestamp: new Date().toISOString(),
      service: 'search-api',
      elasticsearch: 'connected'
    });
  } catch (error) {
    logger.error('Health check failed:', error);
    res.status(503).json({ 
      status: 'unhealthy', 
      timestamp: new Date().toISOString(),
      service: 'search-api'
    });
  }
});

// Search farmers
app.get('/api/search/farmers', async (req, res) => {
  try {
    const { q, location, crop_type, farm_size, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    
    // Check cache first
    const cacheKey = `search:farmers:${JSON.stringify(req.query)}`;
    const cached = await redisClient.get(cacheKey);
    
    if (cached) {
      return res.json(JSON.parse(cached));
    }
    
    let query = 'SELECT * FROM farmers WHERE 1=1';
    const params = [];
    let paramCount = 0;
    
    if (q) {
      paramCount++;
      query += ` AND (name ILIKE $${paramCount} OR email ILIKE $${paramCount})`;
      params.push(`%${q}%`);
    }
    
    if (location) {
      paramCount++;
      query += ` AND farm_location ILIKE $${paramCount}`;
      params.push(`%${location}%`);
    }
    
    if (crop_type) {
      paramCount++;
      query += ` AND crop_types::text ILIKE $${paramCount}`;
      params.push(`%${crop_type}%`);
    }
    
    if (farm_size) {
      paramCount++;
      query += ` AND farm_size = $${paramCount}`;
      params.push(farm_size);
    }
    
    query += ` ORDER BY created_at DESC LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}`;
    params.push(limit, offset);
    
    const result = await pool.query(query, params);
    
    // Get total count
    let countQuery = 'SELECT COUNT(*) FROM farmers WHERE 1=1';
    const countParams = [];
    let countParamCount = 0;
    
    if (q) {
      countParamCount++;
      countQuery += ` AND (name ILIKE $${countParamCount} OR email ILIKE $${countParamCount})`;
      countParams.push(`%${q}%`);
    }
    
    if (location) {
      countParamCount++;
      countQuery += ` AND farm_location ILIKE $${countParamCount}`;
      countParams.push(`%${location}%`);
    }
    
    if (crop_type) {
      countParamCount++;
      countQuery += ` AND crop_types::text ILIKE $${countParamCount}`;
      countParams.push(`%${crop_type}%`);
    }
    
    if (farm_size) {
      countParamCount++;
      countQuery += ` AND farm_size = $${countParamCount}`;
      countParams.push(farm_size);
    }
    
    const countResult = await pool.query(countQuery, countParams);
    const total = parseInt(countResult.rows[0].count);
    
    const response = {
      success: true,
      farmers: result.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    };
    
    // Cache for 5 minutes
    await redisClient.setEx(cacheKey, 300, JSON.stringify(response));
    
    res.json(response);
  } catch (error) {
    logger.error('Search farmers error:', error);
    res.status(500).json({ success: false, message: 'Search failed' });
  }
});

// Search grants
app.get('/api/search/grants', async (req, res) => {
  try {
    const { q, grant_type, status, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    
    const cacheKey = `search:grants:${JSON.stringify(req.query)}`;
    const cached = await redisClient.get(cacheKey);
    
    if (cached) {
      return res.json(JSON.parse(cached));
    }
    
    let query = `
      SELECT ga.*, f.name as farmer_name, f.email as farmer_email 
      FROM grant_applications ga 
      JOIN farmers f ON ga.farmer_id = f.id 
      WHERE 1=1
    `;
    const params = [];
    let paramCount = 0;
    
    if (q) {
      paramCount++;
      query += ` AND (ga.purpose ILIKE $${paramCount} OR f.name ILIKE $${paramCount})`;
      params.push(`%${q}%`);
    }
    
    if (grant_type) {
      paramCount++;
      query += ` AND ga.grant_type = $${paramCount}`;
      params.push(grant_type);
    }
    
    if (status) {
      paramCount++;
      query += ` AND ga.status = $${paramCount}`;
      params.push(status);
    }
    
    query += ` ORDER BY ga.created_at DESC LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}`;
    params.push(limit, offset);
    
    const result = await pool.query(query, params);
    
    const response = {
      success: true,
      grants: result.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit)
      }
    };
    
    await redisClient.setEx(cacheKey, 300, JSON.stringify(response));
    
    res.json(response);
  } catch (error) {
    logger.error('Search grants error:', error);
    res.status(500).json({ success: false, message: 'Search failed' });
  }
});

// Elasticsearch autocomplete endpoint
app.get('/api/search/autocomplete', async (req, res) => {
  try {
    const { q, type = 'all' } = req.query;
    
    if (!q || q.length < 2) {
      return res.json({ success: true, suggestions: [] });
    }
    
    const cacheKey = `autocomplete:${type}:${q}`;
    const cached = await redisClient.get(cacheKey);
    
    if (cached) {
      return res.json(JSON.parse(cached));
    }
    
    let searchBody = {
      suggest: {
        farmer_suggest: {
          prefix: q,
          completion: {
            field: 'suggest',
            size: 10
          }
        }
      }
    };
    
    if (type !== 'all') {
      searchBody.query = {
        match: {
          [type]: {
            query: q,
            fuzziness: 'AUTO'
          }
        }
      };
    }
    
    const result = await esClient.search({
      index: 'farmers',
      body: searchBody
    });
    
    const suggestions = result.body.suggest.farmer_suggest[0].options.map(option => ({
      text: option.text,
      score: option._score
    }));
    
    const response = { success: true, suggestions };
    await redisClient.setEx(cacheKey, 300, JSON.stringify(response));
    
    res.json(response);
  } catch (error) {
    logger.error('Autocomplete error:', error);
    res.status(500).json({ success: false, message: 'Autocomplete failed' });
  }
});

// Get search suggestions (legacy endpoint)
app.get('/api/search/suggestions', async (req, res) => {
  try {
    const { type, q } = req.query;
    
    if (!q || q.length < 2) {
      return res.json({ success: true, suggestions: [] });
    }
    
    const cacheKey = `suggestions:${type}:${q}`;
    const cached = await redisClient.get(cacheKey);
    
    if (cached) {
      return res.json(JSON.parse(cached));
    }
    
    let suggestions = [];
    
    if (type === 'location') {
      const result = await pool.query(
        'SELECT DISTINCT farm_location FROM farmers WHERE farm_location ILIKE $1 LIMIT 10',
        [`%${q}%`]
      );
      suggestions = result.rows.map(row => row.farm_location);
    } else if (type === 'crop') {
      const result = await pool.query(
        'SELECT DISTINCT unnest(crop_types) as crop FROM farmers WHERE crop_types::text ILIKE $1 LIMIT 10',
        [`%${q}%`]
      );
      suggestions = result.rows.map(row => row.crop);
    }
    
    const response = { success: true, suggestions };
    await redisClient.setEx(cacheKey, 600, JSON.stringify(response));
    
    res.json(response);
  } catch (error) {
    logger.error('Suggestions error:', error);
    res.status(500).json({ success: false, message: 'Failed to get suggestions' });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  logger.error('Unhandled error:', error);
  res.status(500).json({ success: false, message: 'Internal server error' });
});

// Start server
app.listen(PORT, () => {
  logger.info(`Search API server running on port ${PORT}`);
});

module.exports = app;