const admin = require('./services/firebaseAdmin');

async function check() {
  const db = admin.firestore();
  const snap = await db.collection('experts').get();
  snap.docs.forEach(doc => {
    console.log(doc.id, "=> typeof schedule:", typeof doc.data().schedule, "isArray:", Array.isArray(doc.data().schedule));
  });
  process.exit(0);
}
check();
