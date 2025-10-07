const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const { Pool } = require('pg');
const redis = require('redis');
const winston = require('winston');

const app = express();
const PORT = process.env.PORT || 3000;

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

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    await redisClient.ping();
    res.status(200).json({ 
      status: 'healthy', 
      timestamp: new Date().toISOString(),
      service: 'registration-api'
    });
  } catch (error) {
    logger.error('Health check failed:', error);
    res.status(503).json({ 
      status: 'unhealthy', 
      timestamp: new Date().toISOString(),
      service: 'registration-api'
    });
  }
});

// Farmer registration endpoint
app.post('/api/farmers/register', async (req, res) => {
  try {
    const { name, email, phone, farm_location, farm_size, crop_types } = req.body;
    
    const result = await pool.query(
      'INSERT INTO farmers (name, email, phone, farm_location, farm_size, crop_types, created_at) VALUES ($1, $2, $3, $4, $5, $6, NOW()) RETURNING *',
      [name, email, phone, farm_location, farm_size, JSON.stringify(crop_types)]
    );
    
    logger.info('Farmer registered:', { farmerId: result.rows[0].id, email });
    res.status(201).json({ 
      success: true, 
      farmer: result.rows[0] 
    });
  } catch (error) {
    logger.error('Registration error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Registration failed' 
    });
  }
});

// Get farmer profile
app.get('/api/farmers/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM farmers WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Farmer not found' });
    }
    
    res.json({ success: true, farmer: result.rows[0] });
  } catch (error) {
    logger.error('Get farmer error:', error);
    res.status(500).json({ success: false, message: 'Failed to get farmer' });
  }
});

// Grant application endpoint
app.post('/api/grants/apply', async (req, res) => {
  try {
    const { farmer_id, grant_type, amount_requested, purpose, documents } = req.body;
    
    const result = await pool.query(
      'INSERT INTO grant_applications (farmer_id, grant_type, amount_requested, purpose, documents, status, created_at) VALUES ($1, $2, $3, $4, $5, $6, NOW()) RETURNING *',
      [farmer_id, grant_type, amount_requested, purpose, JSON.stringify(documents), 'pending']
    );
    
    logger.info('Grant application submitted:', { applicationId: result.rows[0].id, farmerId: farmer_id });
    res.status(201).json({ 
      success: true, 
      application: result.rows[0] 
    });
  } catch (error) {
    logger.error('Grant application error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Grant application failed' 
    });
  }
});

// Get grant applications
app.get('/api/grants/farmer/:farmerId', async (req, res) => {
  try {
    const { farmerId } = req.params;
    const result = await pool.query(
      'SELECT * FROM grant_applications WHERE farmer_id = $1 ORDER BY created_at DESC',
      [farmerId]
    );
    
    res.json({ success: true, applications: result.rows });
  } catch (error) {
    logger.error('Get applications error:', error);
    res.status(500).json({ success: false, message: 'Failed to get applications' });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  logger.error('Unhandled error:', error);
  res.status(500).json({ success: false, message: 'Internal server error' });
});

// Start server
app.listen(PORT, () => {
  logger.info(`Registration API server running on port ${PORT}`);
});

module.exports = app;