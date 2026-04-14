const express = require('express');
const { getDb } = require('../db/database');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// GET /api/settings
router.get('/', authMiddleware, (req, res) => {
  try {
    const db = getDb();
    let settings = db.prepare('SELECT * FROM user_settings WHERE user_id = ?').get(req.userId);
    if (!settings) {
      db.prepare('INSERT INTO user_settings (user_id) VALUES (?)').run(req.userId);
      settings = db.prepare('SELECT * FROM user_settings WHERE user_id = ?').get(req.userId);
    }
    res.json(settings);
  } catch (err) {
    console.error('Get settings error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// PUT /api/settings
router.put('/', authMiddleware, (req, res) => {
  try {
    const { notifications_enabled, email_notifications, push_notifications, auto_save, language, dark_mode } = req.body;
    const db = getDb();

    const updates = [];
    const params = [];

    if (notifications_enabled !== undefined) { updates.push('notifications_enabled = ?'); params.push(notifications_enabled ? 1 : 0); }
    if (email_notifications !== undefined) { updates.push('email_notifications = ?'); params.push(email_notifications ? 1 : 0); }
    if (push_notifications !== undefined) { updates.push('push_notifications = ?'); params.push(push_notifications ? 1 : 0); }
    if (auto_save !== undefined) { updates.push('auto_save = ?'); params.push(auto_save ? 1 : 0); }
    if (language !== undefined) { updates.push('language = ?'); params.push(language); }
    if (dark_mode !== undefined) { updates.push('dark_mode = ?'); params.push(dark_mode ? 1 : 0); }

    if (updates.length === 0) return res.status(400).json({ error: 'No fields to update' });

    params.push(req.userId);
    db.prepare(`UPDATE user_settings SET ${updates.join(', ')} WHERE user_id = ?`).run(...params);

    const settings = db.prepare('SELECT * FROM user_settings WHERE user_id = ?').get(req.userId);
    res.json(settings);
  } catch (err) {
    console.error('Update settings error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
