const admin = require('./services/firebaseAdmin');

const safaData = {
  name: 'Safa Fayyad',
  email: 'safafayyad2033@gmail.com',
  title: 'Business & Strategy Consultant',
  specialty: 'Business Strategy',
  rating: 4.9,
  reviews: 0,
  hourly_rate: 90,
  image: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=400',
  availability: 'Available',
  years_experience: 5,
  sessions_completed: 0,
  bio: 'Safa Fayyad is a passionate business and strategy consultant focused on helping individuals and organizations reach their full potential. Specialising in strategic planning, operational efficiency, and growth accelerators.',
  schedule: [
    { day: 'Monday', slots: ['09:00', '11:00', '14:00', '16:00'] },
    { day: 'Wednesday', slots: ['10:00', '12:00', '15:00'] },
    { day: 'Friday', slots: ['09:00', '11:00', '13:00'] }
  ],
  account_provisioned: false // This triggers the background worker!
};

async function addSafa() {
  if (admin.apps.length === 0) {
    console.error("❌ Admin SDK not initialized. Ensure serviceAccountKey.json is in the backend folder.");
    return;
  }

  const db = admin.firestore();
  const docId = 'safa_fayyad';

  try {
    console.log(`⏳ Adding ${safaData.name} to Firestore...`);
    await db.collection('experts').doc(docId).set(safaData);
    console.log(`✅ ${safaData.name} added successfully!`);
    console.log(`🚀 Your background worker (node server.js) will now provision her account automatically.`);
    process.exit(0);
  } catch (error) {
    console.error("❌ Error adding expert:", error);
    process.exit(1);
  }
}

addSafa();
