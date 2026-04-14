const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const serviceAccountPath = path.join(__dirname, '..', 'serviceAccountKey.json');

// Only initialize if the service account key exists, otherwise gracefully crash
if (fs.existsSync(serviceAccountPath)) {
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('✅ Firebase Admin SDK Initialized.');
} else {
  console.error('\n❌ ERROR: serviceAccountKey.json not found in backend directory!');
  console.error('Please download it from Firebase Console -> Project Settings -> Service Accounts');
  console.error('and place it at: ' + serviceAccountPath + '\n');
}

module.exports = admin;
