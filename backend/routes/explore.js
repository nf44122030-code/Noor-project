const express = require('express');
const { getDb } = require('../db/database');

const router = express.Router();

// GET /api/explore/categories
router.get('/categories', (req, res) => {
  try {
    const db = getDb();
    const categories = db.prepare('SELECT * FROM categories ORDER BY post_count DESC').all();
    res.json(categories);
  } catch (err) {
    console.error('Get categories error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/explore/articles
router.get('/articles', (req, res) => {
  try {
    const db = getDb();
    const featured = db.prepare('SELECT * FROM articles WHERE is_featured = 1 LIMIT 1').get();
    const recent = db.prepare('SELECT * FROM articles WHERE is_featured = 0 ORDER BY created_at DESC').all();
    res.json({ featured, recent });
  } catch (err) {
    console.error('Get articles error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/explore/topics
router.get('/topics', (req, res) => {
  try {
    const db = getDb();
    const topics = db.prepare('SELECT * FROM topics ORDER BY post_count DESC').all();
    res.json(topics);
  } catch (err) {
    console.error('Get topics error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
