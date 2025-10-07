const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const { Pool } = require('pg');
const redis = require('redis');
const winston = require('winston');
const OpenAI = require('openai');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

const PORT = process.env.PORT || 3002;

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

// OpenAI setup
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
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
      service: 'chat-api'
    });
  } catch (error) {
    logger.error('Health check failed:', error);
    res.status(503).json({ 
      status: 'unhealthy', 
      timestamp: new Date().toISOString(),
      service: 'chat-api'
    });
  }
});

// Chat with AI assistant
app.post('/api/chat', async (req, res) => {
  try {
    const { message, farmerId, context } = req.body;
    
    if (!message) {
      return res.status(400).json({ success: false, message: 'Message is required' });
    }
    
    // Get farmer context if provided
    let farmerContext = '';
    if (farmerId) {
      const farmerResult = await pool.query('SELECT * FROM farmers WHERE id = $1', [farmerId]);
      if (farmerResult.rows.length > 0) {
        const farmer = farmerResult.rows[0];
        farmerContext = `Farmer Profile: ${farmer.name}, Location: ${farmer.farm_location}, Farm Size: ${farmer.farm_size}, Crops: ${farmer.crop_types?.join(', ') || 'N/A'}`;
      }
    }
    
    // Prepare system message
    const systemMessage = `You are an AI assistant for Singapore farmers. You help with farming advice, grant applications, and agricultural best practices. 
    ${farmerContext ? `Current farmer context: ${farmerContext}` : ''}
    Provide helpful, accurate, and practical advice specific to Singapore's agricultural context.`;
    
    const completion = await openai.chat.completions.create({
      model: "gpt-3.5-turbo",
      messages: [
        { role: "system", content: systemMessage },
        { role: "user", content: message }
      ],
      max_tokens: 500,
      temperature: 0.7
    });
    
    const aiResponse = completion.choices[0].message.content;
    
    // Store chat history
    if (farmerId) {
      await pool.query(
        'INSERT INTO chat_history (farmer_id, user_message, ai_response, created_at) VALUES ($1, $2, $3, NOW())',
        [farmerId, message, aiResponse]
      );
    }
    
    logger.info('Chat interaction:', { farmerId, messageLength: message.length });
    
    res.json({
      success: true,
      response: aiResponse,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    logger.error('Chat error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to process chat message' 
    });
  }
});

// Get chat history
app.get('/api/chat/history/:farmerId', async (req, res) => {
  try {
    const { farmerId } = req.params;
    const { limit = 50 } = req.query;
    
    const result = await pool.query(
      'SELECT * FROM chat_history WHERE farmer_id = $1 ORDER BY created_at DESC LIMIT $2',
      [farmerId, limit]
    );
    
    res.json({
      success: true,
      history: result.rows.reverse() // Return in chronological order
    });
    
  } catch (error) {
    logger.error('Get chat history error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to get chat history' 
    });
  }
});

// Socket.IO for real-time chat
io.on('connection', (socket) => {
  logger.info('User connected:', socket.id);
  
  socket.on('join_room', (farmerId) => {
    socket.join(`farmer_${farmerId}`);
    logger.info(`Farmer ${farmerId} joined room`);
  });
  
  socket.on('send_message', async (data) => {
    try {
      const { farmerId, message } = data;
      
      // Broadcast to room
      socket.to(`farmer_${farmerId}`).emit('receive_message', {
        message,
        sender: 'user',
        timestamp: new Date().toISOString()
      });
      
      // Get AI response
      const completion = await openai.chat.completions.create({
        model: "gpt-3.5-turbo",
        messages: [
          { 
            role: "system", 
            content: "You are an AI assistant for Singapore farmers. Provide helpful farming advice." 
          },
          { role: "user", content: message }
        ],
        max_tokens: 300,
        temperature: 0.7
      });
      
      const aiResponse = completion.choices[0].message.content;
      
      // Send AI response
      io.to(`farmer_${farmerId}`).emit('receive_message', {
        message: aiResponse,
        sender: 'ai',
        timestamp: new Date().toISOString()
      });
      
      // Store in database
      await pool.query(
        'INSERT INTO chat_history (farmer_id, user_message, ai_response, created_at) VALUES ($1, $2, $3, NOW())',
        [farmerId, message, aiResponse]
      );
      
    } catch (error) {
      logger.error('Socket message error:', error);
      socket.emit('error', { message: 'Failed to process message' });
    }
  });
  
  socket.on('disconnect', () => {
    logger.info('User disconnected:', socket.id);
  });
});

// Error handling middleware
app.use((error, req, res, next) => {
  logger.error('Unhandled error:', error);
  res.status(500).json({ success: false, message: 'Internal server error' });
});

// Start server
server.listen(PORT, () => {
  logger.info(`Chat API server running on port ${PORT}`);
});

module.exports = app;