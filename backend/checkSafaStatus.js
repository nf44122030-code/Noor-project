const admin = require('./services/firebaseAdmin');

async function check() {
  const db = admin.firestore();
  const auth = admin.auth();
  const email = 'safafayyad2033@gmail.com';
  
  console.log(`--- Checking status for ${email} ---`);
  
  // Check Auth
  try {
    const userRecord = await auth.getUserByEmail(email);
    console.log(`✅ Auth account: EXISTS (UID: ${userRecord.uid})`);
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      console.log(`❌ Auth account: DOES NOT EXIST`);
    } else {
      console.error(`Error checking auth: ${e.message}`);
    }
  }

  // Check Firestore experts
  const expertDoc = await db.collection('experts').doc('safa_fayyad').get();
  if (expertDoc.exists) {
    console.log(`✅ Firestore expert doc: EXISTS`);
    console.log(`   account_provisioned: ${expertDoc.data().account_provisioned}`);
  } else {
    console.log(`❌ Firestore expert doc: MISSING`);
  }

  // Check Firestore users
  const usersSnap = await db.collection('users').where('email', '==', email).limit(1).get();
  if (!usersSnap.empty) {
    console.log(`✅ Firestore user profile: EXISTS`);
    console.log(`   is_expert: ${usersSnap.docs[0].data().is_expert}`);
  } else {
    console.log(`❌ Firestore user profile: MISSING`);
  }

  process.exit(0);
}
check();
