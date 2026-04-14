const admin = require('./services/firebaseAdmin');

async function run() {
  const db = admin.firestore();
  const doc = await db.collection('experts').doc('safa_fayyad').get();
  if (doc.exists) {
    console.log("Found Safa:");
    console.log(doc.data().account_provisioned);
  } else {
    console.log("Safa not found");
  }
  process.exit(0);
}
run();
