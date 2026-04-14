const express = require('express');
const { getDb } = require('../db/database');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// GET /api/plans
router.get('/', (req, res) => {
  try {
    const db = getDb();
    const plans = db.prepare('SELECT * FROM plans ORDER BY sort_order ASC').all();
    // Parse features JSON
    const parsed = plans.map(p => ({ ...p, features: JSON.parse(p.features_json) }));
    res.json(parsed);
  } catch (err) {
    console.error('Get plans error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/plans/subscribe
router.post('/subscribe', authMiddleware, (req, res) => {
  try {
    const { plan_id, billing_cycle } = req.body;
    if (!plan_id) return res.status(400).json({ error: 'plan_id is required' });

    const db = getDb();
    const plan = db.prepare('SELECT * FROM plans WHERE id = ?').get(plan_id);
    if (!plan) return res.status(404).json({ error: 'Plan not found' });

    // Deactivate current subscription
    db.prepare('UPDATE user_subscriptions SET status = ? WHERE user_id = ? AND status = ?').run('cancelled', req.userId, 'active');

    // Create new subscription
    const result = db.prepare('INSERT INTO user_subscriptions (user_id, plan_id, billing_cycle, status) VALUES (?, ?, ?, ?)').run(
      req.userId, plan_id, billing_cycle || 'monthly', 'active'
    );

    const subscription = db.prepare('SELECT * FROM user_subscriptions WHERE id = ?').get(result.lastInsertRowid);
    res.status(201).json(subscription);
  } catch (err) {
    console.error('Subscribe error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
