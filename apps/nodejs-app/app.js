const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    version: process.env.APP_VERSION || '1.0.0'
  });
});

// Main application endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to MultiCloud Node.js Application!',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    version: process.env.APP_VERSION || '1.0.0',
    platform: process.env.CLOUD_PLATFORM || 'unknown'
  });
});

// API endpoints
app.get('/api/info', (req, res) => {
  res.json({
    app: 'multicloud-nodejs-app',
    version: process.env.APP_VERSION || '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    platform: process.env.CLOUD_PLATFORM || 'unknown',
    region: process.env.CLUSTER_REGION || 'unknown',
    cluster: process.env.CLUSTER_NAME || 'unknown'
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Something went wrong!',
    message: err.message
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Route not found',
    path: req.originalUrl
  });
});

app.listen(PORT, () => {
  console.log(`MultiCloud Node.js app listening on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`Platform: ${process.env.CLOUD_PLATFORM || 'unknown'}`);
});

module.exports = app; 