const express = require('express');
const { getDb } = require('../db/database');

const router = express.Router();

// GET /api/support/faq
router.get('/faq', (req, res) => {
  try {
    const db = getDb();
    const categories = db.prepare('SELECT * FROM faq_categories ORDER BY sort_order ASC').all();
    const result = categories.map(cat => {
      const questions = db.prepare('SELECT * FROM faq_items WHERE category_id = ? ORDER BY sort_order ASC').all(cat.id);
      return { category: cat.name, questions };
    });
    res.json(result);
  } catch (err) {
    console.error('Get FAQ error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/support/quick-help
router.get('/quick-help', (req, res) => {
  res.json([
    { icon: 'book', title: 'User Guide', subtitle: 'Complete documentation' },
    { icon: 'video_library', title: 'Video Tutorials', subtitle: 'Step-by-step guides' },
    { icon: 'chat_bubble_outline', title: 'Live Chat', subtitle: 'Chat with support' },
    { icon: 'description', title: 'Release Notes', subtitle: "What's new" },
  ]);
});

module.exports = router;
