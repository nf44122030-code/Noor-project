const express = require('express');
const { getDb } = require('../db/database');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// GET /api/trends/metrics
router.get('/metrics', authMiddleware, (req, res) => {
  try {
    const { timeframe } = req.query;
    const db = getDb();
    const metrics = db.prepare('SELECT * FROM trend_metrics WHERE (user_id = ? OR user_id IS NULL) AND timeframe = ?').all(req.userId, timeframe || 'month');

    // If no user-specific metrics, return default data
    if (metrics.length === 0) {
      const defaults = db.prepare('SELECT * FROM trend_metrics WHERE user_id = 2 AND timeframe = ?').all(timeframe || 'month');
      return res.json(defaults);
    }
    res.json(metrics);
  } catch (err) {
    console.error('Get metrics error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/trends/revenue
router.get('/revenue', authMiddleware, (req, res) => {
  try {
    const { timeframe } = req.query;
    const db = getDb();
    let data = db.prepare('SELECT * FROM revenue_data WHERE (user_id = ? OR user_id IS NULL) AND timeframe = ? ORDER BY id ASC').all(req.userId, timeframe || 'month');

    if (data.length === 0) {
      data = db.prepare('SELECT * FROM revenue_data WHERE user_id = 2 AND timeframe = ? ORDER BY id ASC').all(timeframe || 'month');
    }
    res.json(data);
  } catch (err) {
    console.error('Get revenue error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/trends/categories
router.get('/categories', authMiddleware, (req, res) => {
  try {
    const db = getDb();
    let data = db.prepare('SELECT * FROM category_sales WHERE user_id = ? ORDER BY percentage DESC').all(req.userId);

    if (data.length === 0) {
      data = db.prepare('SELECT * FROM category_sales WHERE user_id = 2 ORDER BY percentage DESC').all();
    }
    res.json(data);
  } catch (err) {
    console.error('Get category sales error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/trends/products
router.get('/products', authMiddleware, (req, res) => {
  try {
    const db = getDb();
    let data = db.prepare('SELECT * FROM top_products WHERE user_id = ? ORDER BY id ASC').all(req.userId);

    if (data.length === 0) {
      data = db.prepare('SELECT * FROM top_products WHERE user_id = 2 ORDER BY id ASC').all();
    }
    res.json(data);
  } catch (err) {
    console.error('Get products error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
