const bcrypt = require('bcryptjs');
const { getDb, initDb } = require('./database');

function seed() {
  const db = initDb();

  // Check if already seeded
  const userCount = db.prepare('SELECT COUNT(*) as count FROM users').get();
  if (userCount.count > 0) {
    console.log('⚠️  Database already seeded, skipping...');
    return;
  }

  console.log('🌱 Seeding database...');

  // ── Users ──
  const hash = (pw) => bcrypt.hashSync(pw, 10);
  const insertUser = db.prepare('INSERT INTO users (name, email, password_hash, phone, location, bio) VALUES (?, ?, ?, ?, ?, ?)');
  insertUser.run('Admin User', 'admin@intellix.com', hash('admin123'), '+1 555-0100', 'San Francisco, CA', 'Platform administrator');
  insertUser.run('Noor', 'noor@intellix.com', hash('password123'), '+1 555-0101', 'New York, NY', 'Business analyst passionate about data-driven decisions');
  insertUser.run('Demo User', 'demo@intellix.com', hash('demo123'), '+1 555-0102', 'London, UK', 'Exploring the Intellix platform');

  // ── User Settings ──
  const insertSettings = db.prepare('INSERT INTO user_settings (user_id) VALUES (?)');
  insertSettings.run(1);
  insertSettings.run(2);
  insertSettings.run(3);

  // ── Plans ──
  const insertPlan = db.prepare('INSERT INTO plans (id, name, icon_name, price_monthly, price_yearly, period, description, is_popular, features_json, gradient_from, gradient_to, sort_order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
  insertPlan.run('basic', 'Basic', 'auto_awesome', 0, 0, 'Forever', 'Perfect for getting started with Intellix', 0,
    JSON.stringify(['AI Assistant (Limited)', '5 Expert Sessions/month', 'Basic Analytics', 'Community Access', 'Mobile App Access', 'Email Support']),
    '#9CA3AF', '#6B7280', 1);
  insertPlan.run('pro', 'Pro', 'flash_on', 29, 278, 'per month', 'For professionals who need more power', 1,
    JSON.stringify(['Unlimited AI Assistant', '20 Expert Sessions/month', 'Advanced Analytics', 'Priority Support', 'Custom Reports', 'Team Collaboration (up to 5)', 'API Access', 'Data Export']),
    '#5B9FF3', '#7DB6F7', 2);
  insertPlan.run('enterprise', 'Enterprise', 'workspace_premium', 99, 950, 'per month', 'For teams and organizations', 0,
    JSON.stringify(['Everything in Pro', 'Unlimited Expert Sessions', 'Custom AI Training', 'Dedicated Account Manager', 'Advanced Security', 'Unlimited Team Members', 'Custom Integrations', 'SLA Guarantee', 'White-label Options', 'On-premise Deployment']),
    '#0284C7', '#06B6D4', 3);

  // ── User Subscriptions ──
  const insertSub = db.prepare('INSERT INTO user_subscriptions (user_id, plan_id, billing_cycle, status) VALUES (?, ?, ?, ?)');
  insertSub.run(1, 'enterprise', 'yearly', 'active');
  insertSub.run(2, 'pro', 'monthly', 'active');
  insertSub.run(3, 'basic', 'monthly', 'active');

  // ── Experts ──
  const insertExpert = db.prepare('INSERT INTO experts (name, title, specialty, rating, reviews, hourly_rate, image_url, availability, years_experience, sessions_completed, bio) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
  insertExpert.run('Dr. Sarah Johnson', 'Business Strategy Consultant', 'Business Growth & Strategy', 4.9, 127, 150, 'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=400', 'Available Today', 12, 450, 'Expert in business strategy with over 12 years helping companies scale and optimize their operations.');
  insertExpert.run('Michael Chen', 'Data Analytics Expert', 'Data Science & Analytics', 4.8, 98, 120, 'https://images.unsplash.com/photo-1701463387028-3947648f1337?w=400', 'Available Tomorrow', 8, 320, 'Specialized in advanced analytics, machine learning, and turning data into actionable insights.');
  insertExpert.run('Emily Rodriguez', 'Marketing Strategist', 'Digital Marketing & Growth', 5.0, 156, 140, 'https://images.unsplash.com/photo-1689600944138-da3b150d9cb8?w=400', 'Available Today', 10, 520, 'Digital marketing expert helping businesses increase online presence and customer engagement.');
  insertExpert.run('David Kumar', 'Financial Advisor', 'Finance & Investment', 4.7, 89, 180, 'https://images.unsplash.com/photo-1651684215020-f7a5b6610f23?w=400', 'Available Next Week', 15, 380, 'Financial planning and investment strategies for businesses looking to optimize their capital.');
  insertExpert.run('Lisa Anderson', 'AI & Technology Consultant', 'AI Implementation', 4.9, 112, 160, 'https://images.unsplash.com/photo-1590563152569-bd0b2dae4418?w=400', 'Available Today', 9, 290, 'Helping organizations implement AI solutions and leverage technology for competitive advantage.');
  insertExpert.run('James Wilson', 'Operations Expert', 'Operations & Efficiency', 4.8, 95, 130, 'https://images.unsplash.com/photo-1738750908048-14200459c3c9?w=400', 'Available Tomorrow', 11, 410, 'Optimizing business operations and implementing efficient processes for maximum productivity.');

  // ── Notifications (for user 2 = Noor) ──
  const insertNotif = db.prepare('INSERT INTO notifications (user_id, type, title, description, icon_name, is_read, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)');
  const now = new Date();
  const ago = (h) => new Date(now - h * 3600000).toISOString();

  insertNotif.run(2, 'session', 'Session Reminder', 'Your session with Dr. Sarah Johnson starts in 30 minutes', 'event', 0, ago(0.5));
  insertNotif.run(2, 'message', 'New Message', 'Michael Chen sent you a follow-up message', 'chat', 0, ago(2));
  insertNotif.run(2, 'update', 'App Update Available', 'Version 2.0 is now available with new features', 'system_update', 0, ago(5));
  insertNotif.run(2, 'achievement', 'Achievement Unlocked!', 'You completed 10 expert sessions. Keep going!', 'emoji_events', 1, ago(24));
  insertNotif.run(2, 'reminder', 'Weekly Report Ready', 'Your weekly analytics report is ready to view', 'assessment', 1, ago(48));
  insertNotif.run(2, 'session', 'Session Completed', 'Your session with Emily Rodriguez has been saved', 'check_circle', 1, ago(72));
  insertNotif.run(2, 'update', 'New Expert Available', 'James Wilson has joined the platform', 'person_add', 1, ago(96));
  insertNotif.run(2, 'message', 'AI Insight', 'New business insight detected in your data trends', 'lightbulb', 0, ago(1));

  // Also add some for user 1 and 3
  insertNotif.run(1, 'update', 'Welcome to Intellix!', 'Start exploring AI-powered business intelligence', 'rocket_launch', 0, ago(1));
  insertNotif.run(3, 'update', 'Welcome to Intellix!', 'Start exploring AI-powered business intelligence', 'rocket_launch', 0, ago(1));

  // ── Categories ──
  const insertCat = db.prepare('INSERT INTO categories (id, name, icon_name, gradient_from, gradient_to, post_count) VALUES (?, ?, ?, ?, ?, ?)');
  insertCat.run('business', 'Business', 'business_center', '#3B82F6', '#2563EB', 142);
  insertCat.run('analytics', 'Analytics', 'bar_chart', '#06B6D4', '#0891B2', 98);
  insertCat.run('marketing', 'Marketing', 'campaign', '#EC4899', '#DB2777', 76);
  insertCat.run('technology', 'Technology', 'code', '#10B981', '#059669', 124);
  insertCat.run('leadership', 'Leadership', 'groups', '#F97316', '#EA580C', 89);
  insertCat.run('innovation', 'Innovation', 'lightbulb', '#F59E0B', '#D97706', 67);

  // ── Articles ──
  const insertArticle = db.prepare('INSERT INTO articles (title, category, read_time, views, is_featured, image_url) VALUES (?, ?, ?, ?, ?, ?)');
  insertArticle.run('10 Data-Driven Strategies to Scale Your Business in 2025', 'Business Strategy', '8 min read', '12.5K', 1, 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800&q=80');
  insertArticle.run('Effective Marketing Strategies for Digital Transformation', 'Marketing', '5 min read', '6.7K', 0, 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400&q=80');
  insertArticle.run('Building High-Performance Teams in Remote Environments', 'Leadership', '7 min read', '9.1K', 0, 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400&q=80');
  insertArticle.run('Innovation Through Design Thinking Methodologies', 'Innovation', '9 min read', '7.4K', 0, 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400&q=80');

  // ── Topics ──
  const insertTopic = db.prepare('INSERT INTO topics (name, post_count, is_trending) VALUES (?, ?, ?)');
  insertTopic.run('AI & Machine Learning', 234, 1);
  insertTopic.run('Business Growth', 189, 1);
  insertTopic.run('Data Visualization', 156, 0);
  insertTopic.run('Customer Experience', 142, 0);
  insertTopic.run('Digital Strategy', 128, 0);
  insertTopic.run('Product Management', 115, 0);

  // ── Trend Metrics (for user 2) ──
  const insertMetric = db.prepare('INSERT INTO trend_metrics (user_id, metric_name, metric_value, change_percent, is_positive, icon_name, icon_color, timeframe) VALUES (?, ?, ?, ?, ?, ?, ?, ?)');
  insertMetric.run(2, 'Revenue', '$47.2K', 12.5, 1, 'attach_money', '#10B981', 'month');
  insertMetric.run(2, 'Active Users', '2,847', 8.3, 1, 'people', '#3B82F6', 'month');
  insertMetric.run(2, 'Orders', '1,284', -3.2, 0, 'shopping_cart', '#06B6D4', 'month');
  insertMetric.run(2, 'Page Views', '18.9K', 15.7, 1, 'visibility', '#F97316', 'month');

  // ── Revenue Data ──
  const insertRevenue = db.prepare('INSERT INTO revenue_data (user_id, period_label, amount, timeframe) VALUES (?, ?, ?, ?)');
  insertRevenue.run(2, 'Jan', 4200, 'month');
  insertRevenue.run(2, 'Feb', 3800, 'month');
  insertRevenue.run(2, 'Mar', 5100, 'month');
  insertRevenue.run(2, 'Apr', 4600, 'month');
  insertRevenue.run(2, 'May', 6200, 'month');
  insertRevenue.run(2, 'Jun', 7100, 'month');

  // ── Category Sales ──
  const insertCatSales = db.prepare('INSERT INTO category_sales (user_id, category_name, percentage, color_hex) VALUES (?, ?, ?, ?)');
  insertCatSales.run(2, 'Electronics', 35, '#0284C7');
  insertCatSales.run(2, 'Fashion', 28, '#0EA5E9');
  insertCatSales.run(2, 'Home', 20, '#06B6D4');
  insertCatSales.run(2, 'Sports', 17, '#67E8F9');

  // ── Top Products ──
  const insertProduct = db.prepare('INSERT INTO top_products (user_id, name, sales) VALUES (?, ?, ?)');
  insertProduct.run(2, 'Wireless Headphones', '$12,450');
  insertProduct.run(2, 'Smart Watch Pro', '$9,830');
  insertProduct.run(2, 'Laptop Stand', '$7,290');
  insertProduct.run(2, 'USB-C Hub', '$6,140');

  // ── FAQ Categories & Items ──
  const insertFaqCat = db.prepare('INSERT INTO faq_categories (name, sort_order) VALUES (?, ?)');
  insertFaqCat.run('Getting Started', 1);
  insertFaqCat.run('AI Assistant', 2);
  insertFaqCat.run('Features', 3);
  insertFaqCat.run('Account & Privacy', 4);

  const insertFaq = db.prepare('INSERT INTO faq_items (category_id, question, answer, sort_order) VALUES (?, ?, ?, ?)');
  insertFaq.run(1, 'How do I create an account?', 'Tap on "Sign Up" from the login screen and fill in your details. Verify your email to complete registration.', 1);
  insertFaq.run(1, 'How do I reset my password?', 'Click "Forgot Password" on the login screen and follow the instructions sent to your email.', 2);
  insertFaq.run(1, 'What is Intellix?', 'Intellix is an AI-powered business intelligence platform that helps you analyze trends, gain insights, and make data-driven decisions.', 3);
  insertFaq.run(2, 'How do I use the AI Assistant?', 'Navigate to the AI Chat tab and type your question. The AI will provide intelligent responses based on your business data.', 1);
  insertFaq.run(2, 'What can I ask the AI?', 'You can ask about business metrics, trends, forecasts, data analysis, and get recommendations for improving your business.', 2);
  insertFaq.run(2, 'Is my data secure with AI?', 'Yes, all conversations are encrypted and your data is processed securely. We never share your information with third parties.', 3);
  insertFaq.run(3, 'How do I view trends?', 'Navigate to the Trends page from the home screen or sidebar. You can filter by timeframe (week, month, year) to see different data views.', 1);
  insertFaq.run(3, 'Can I export my data?', 'Yes, you can export reports and data from the Settings page under Data Management.', 2);
  insertFaq.run(3, 'How do I customize my dashboard?', 'Go to Settings > Preferences to customize your dashboard layout and widgets.', 3);
  insertFaq.run(4, 'How do I delete my account?', 'Go to Settings > Danger Zone > Delete Account. Note that this action is permanent and cannot be undone.', 1);
  insertFaq.run(4, 'How is my data protected?', 'We use industry-standard encryption and security measures to protect your data. Read our Privacy Policy for more details.', 2);
  insertFaq.run(4, 'Can I change my email address?', 'Yes, go to Settings > Account > Change Email and follow the verification process.', 3);

  // ── AI Sessions with sample messages (for user 2) ──
  const insertSession = db.prepare('INSERT INTO ai_sessions (user_id, title, created_at) VALUES (?, ?, ?)');
  insertSession.run(2, 'Business Growth Analysis', ago(24));

  const insertMsg = db.prepare('INSERT INTO ai_messages (session_id, role, content, created_at) VALUES (?, ?, ?, ?)');
  insertMsg.run(1, 'user', 'What are the top strategies for scaling a SaaS business?', ago(24));
  insertMsg.run(1, 'ai', 'Here are the top strategies for scaling a SaaS business:\n\n1. **Product-Led Growth** — Let users experience value before purchasing\n2. **Customer Success Focus** — Reduce churn by investing in onboarding\n3. **Data-Driven Decisions** — Use analytics to guide product development\n4. **Strategic Partnerships** — Build an ecosystem of integrations\n5. **Content Marketing** — Establish thought leadership in your niche\n\nWould you like me to dive deeper into any of these strategies?', ago(23.9));

  console.log('✅ Database seeded successfully');
}

// Run directly
if (require.main === module) {
  seed();
  process.exit(0);
}

module.exports = { seed };
