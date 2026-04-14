const express = require('express');
const { getDb } = require('../db/database');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// GET /api/ai/sessions — list user's AI chat sessions
router.get('/sessions', authMiddleware, (req, res) => {
  try {
    const db = getDb();
    const sessions = db.prepare('SELECT * FROM ai_sessions WHERE user_id = ? ORDER BY created_at DESC').all(req.userId);
    res.json(sessions);
  } catch (err) {
    console.error('Get AI sessions error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/ai/sessions — create new chat session
router.post('/sessions', authMiddleware, (req, res) => {
  try {
    const { title } = req.body;
    const db = getDb();
    const result = db.prepare('INSERT INTO ai_sessions (user_id, title) VALUES (?, ?)').run(req.userId, title || 'New Chat');
    const session = db.prepare('SELECT * FROM ai_sessions WHERE id = ?').get(result.lastInsertRowid);
    res.status(201).json(session);
  } catch (err) {
    console.error('Create AI session error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/ai/sessions/:id/messages
router.get('/sessions/:id/messages', authMiddleware, (req, res) => {
  try {
    const db = getDb();
    const session = db.prepare('SELECT * FROM ai_sessions WHERE id = ? AND user_id = ?').get(req.params.id, req.userId);
    if (!session) return res.status(404).json({ error: 'Session not found' });

    const messages = db.prepare('SELECT * FROM ai_messages WHERE session_id = ? ORDER BY created_at ASC').all(req.params.id);
    res.json(messages);
  } catch (err) {
    console.error('Get messages error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/ai/sessions/:id/messages — send message and get AI response
router.post('/sessions/:id/messages', authMiddleware, (req, res) => {
  try {
    const { content } = req.body;
    if (!content) return res.status(400).json({ error: 'Content is required' });

    const db = getDb();
    const session = db.prepare('SELECT * FROM ai_sessions WHERE id = ? AND user_id = ?').get(req.params.id, req.userId);
    if (!session) return res.status(404).json({ error: 'Session not found' });

    // Save user message
    db.prepare('INSERT INTO ai_messages (session_id, role, content) VALUES (?, ?, ?)').run(req.params.id, 'user', content);

    // Generate AI response (simulated — in production, call OpenAI/Gemini API here)
    const aiResponse = generateAIResponse(content);
    db.prepare('INSERT INTO ai_messages (session_id, role, content) VALUES (?, ?, ?)').run(req.params.id, 'ai', aiResponse);

    // Get the two new messages
    const messages = db.prepare('SELECT * FROM ai_messages WHERE session_id = ? ORDER BY created_at DESC LIMIT 2').all(req.params.id);
    res.status(201).json(messages.reverse());
  } catch (err) {
    console.error('Send message error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

function generateAIResponse(userMessage) {
  const lowerMsg = userMessage.toLowerCase();

  if (lowerMsg.includes('revenue') || lowerMsg.includes('sales')) {
    return "📊 Based on your recent data, revenue has shown a **12.5% increase** over the past month. Key growth drivers include:\n\n1. **Electronics category** (+18% MoM)\n2. **New customer acquisition** up 23%\n3. **Average order value** increased by $12\n\nI recommend focusing on your top-performing product lines and considering seasonal promotions to maintain momentum.";
  }
  if (lowerMsg.includes('marketing') || lowerMsg.includes('growth')) {
    return "🚀 Here are data-driven marketing recommendations:\n\n1. **Content Marketing** — Your blog traffic shows 15.7% growth; double down on SEO-optimized content\n2. **Social Media** — Instagram posts with product demos get 3x engagement\n3. **Email Campaigns** — Segmented emails show 42% higher open rates\n4. **Paid Ads** — Consider retargeting campaigns for cart abandoners (estimated 8% conversion)\n\nWould you like me to create a detailed marketing plan?";
  }
  if (lowerMsg.includes('team') || lowerMsg.includes('employee') || lowerMsg.includes('hire')) {
    return "👥 Based on your growth metrics, here's my analysis:\n\n• Current team efficiency is at **87%** — above industry average\n• Key hiring priorities should be: Data Analyst, Marketing Manager\n• Consider outsourcing: Graphic Design, Content Writing\n• Team satisfaction survey shows areas for improvement in work-life balance\n\nShall I break down the ROI analysis for each potential hire?";
  }
  if (lowerMsg.includes('trend') || lowerMsg.includes('forecast')) {
    return "📈 Here's your trends forecast for the next quarter:\n\n1. **Revenue Projection**: $52K-$58K (conservative to optimistic)\n2. **User Growth**: Expected 15-20% increase\n3. **Market Trends**: AI integration demand up 40% in your sector\n4. **Risk Factors**: Supply chain delays may impact 2 product lines\n\nI'd recommend preparing contingency inventory for your top 3 products.";
  }

  return "Thanks for your question! Here's my analysis:\n\n🔍 I've examined your business data and identified several insights:\n\n1. **Performance Overview**: Your key metrics are trending positively\n2. **Opportunities**: There are untapped segments in your customer base\n3. **Recommendations**: Focus on customer retention and upselling strategies\n4. **Next Steps**: I can provide detailed reports on any specific area\n\nWhat specific aspect would you like me to analyze further?";
}

module.exports = router;
