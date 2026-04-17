require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const { initDb, closeDb } = require('./db/database');
const { seed } = require('./db/seed');
const { startExpertProvisioner } = require('./services/expertProvisioner');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Initialize database & workers
initDb();
seed();
startExpertProvisioner();

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/experts', require('./routes/experts'));
app.use('/api/bookings', require('./routes/bookings'));
app.use('/api/ai', require('./routes/ai'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/explore', require('./routes/explore'));
app.use('/api/trends', require('./routes/trends'));
app.use('/api/plans', require('./routes/plans'));
app.use('/api/support', require('./routes/support'));
app.use('/api/settings', require('./routes/settings'));
app.use('/api/agora', require('./routes/agora'));

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Error handling
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
const server = app.listen(PORT, () => {
  console.log(`🚀 Intellix API running on http://localhost:${PORT}`);
  console.log(`📋 Health check: http://localhost:${PORT}/api/health`);
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🔄 Shutting down...');
  closeDb();
  server.close();
  process.exit(0);
});

module.exports = app;
