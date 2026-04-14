const express = require('express');
const { getDb } = require('../db/database');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// GET /api/experts
router.get('/', (req, res) => {
  try {
    const db = getDb();
    const experts = db.prepare('SELECT * FROM experts ORDER BY rating DESC').all();
    res.json(experts);
  } catch (err) {
    console.error('Get experts error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/experts/:id
router.get('/:id', (req, res) => {
  try {
    const db = getDb();
    const expert = db.prepare('SELECT * FROM experts WHERE id = ?').get(req.params.id);
    if (!expert) return res.status(404).json({ error: 'Expert not found' });
    res.json(expert);
  } catch (err) {
    console.error('Get expert error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
