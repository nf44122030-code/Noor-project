const express = require('express');
const { getDb } = require('../db/database');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// GET /api/bookings
router.get('/', authMiddleware, (req, res) => {
  try {
    const db = getDb();
    const bookings = db.prepare(`
      SELECT b.*, e.name as expert_name, e.title as expert_title, e.image_url as expert_image
      FROM bookings b
      JOIN experts e ON b.expert_id = e.id
      WHERE b.user_id = ?
      ORDER BY b.scheduled_at DESC
    `).all(req.userId);
    res.json(bookings);
  } catch (err) {
    console.error('Get bookings error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/bookings
router.post('/', authMiddleware, (req, res) => {
  try {
    const { expert_id, scheduled_at, duration_minutes } = req.body;
    if (!expert_id || !scheduled_at) {
      return res.status(400).json({ error: 'expert_id and scheduled_at are required' });
    }

    const db = getDb();
    const expert = db.prepare('SELECT id FROM experts WHERE id = ?').get(expert_id);
    if (!expert) return res.status(404).json({ error: 'Expert not found' });

    const result = db.prepare('INSERT INTO bookings (user_id, expert_id, scheduled_at, duration_minutes, status) VALUES (?, ?, ?, ?, ?)').run(
      req.userId, expert_id, scheduled_at, duration_minutes || 60, 'confirmed'
    );

    const booking = db.prepare('SELECT * FROM bookings WHERE id = ?').get(result.lastInsertRowid);
    res.status(201).json(booking);
  } catch (err) {
    console.error('Create booking error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
