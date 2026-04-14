const admin = require('./firebaseAdmin');

// Generates a random alphanumeric password
const generatePassword = (length = 10) => {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
};

// Starts a real-time listener on the experts collection
const startExpertProvisioner = () => {
  if (admin.apps.length === 0) return; // Skip if admin SDK isn't initialized

  const db = admin.firestore();
  
  console.log('👀 Expert Provisioner listening for new experts...');

  db.collection('experts').onSnapshot(async (snapshot) => {
    // Only process added/modified documents, ignore removals
    for (const change of snapshot.docChanges()) {
      if (change.type === 'added' || change.type === 'modified') {
        const doc = change.doc;
        const data = doc.data();
        const email = data.email;
        const name = data.name || 'Expert';

        if (!email) continue;
        if (data.account_provisioned === true) continue;

        console.log(`⏳ Detected unprovisioned expert: ${email}. Provisioning...`);

        const password = generatePassword(10);

        try {
          // 1. Create Firebase Auth Account
          const userRecord = await admin.auth().createUser({
            email: email,
            password: password,
            displayName: name,
            emailVerified: true // Let's mark verified since we control this account
          });

          // 2. Mark account_provisioned as true to prevent endless looping
          await doc.ref.update({
            account_provisioned: true,
            provisioned_at: admin.firestore.FieldValue.serverTimestamp()
          });

          // 3. Add to the generic users collection so the client app recognizes them properly
          await db.collection('users').doc(userRecord.uid).set({
            id: Date.now(),
            name: name,
            email: email,
            sessions_count: 0,
            queries_count: 0,
            reports_count: 0,
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            current_plan_id: 'free',
            current_plan_name: 'Starter',
            is_yearly_plan: false,
            plan_expiration: null,
            is_expert: true
          });

          // 4. Send the credential email via Firestore trigger extension
          await db.collection('mail').add({
            to: email,
            from: 'Intellix <noorfayyad25122@gmail.com>',
            message: {
              subject: '🔑 Your Intellix Expert Portal Credentials',
              html: `
<div style="font-family:sans-serif;max-width:600px;margin:auto;">
  <h2 style="color:#0284C7;">Welcome to Intellix Expert Portal</h2>
  <p>Hi <strong>${name}</strong>,</p>
  <p>Your Expert Portal account has been created. Use the credentials below to log in:</p>
  <table style="border-collapse:collapse;width:100%;margin:16px 0;">
    <tr><td style="padding:12px;border:1px solid #E0F2FE;color:#6B7280;">Email</td>
        <td style="padding:12px;border:1px solid #E0F2FE;"><strong>${email}</strong></td></tr>
    <tr><td style="padding:12px;border:1px solid #E0F2FE;color:#6B7280;">Password</td>
        <td style="padding:12px;border:1px solid #E0F2FE;background-color:#F0F9FF;text-align:center;">
          <strong style="font-size:20px;color:#0284C7;letter-spacing:2px;">${password}</strong>
        </td></tr>
  </table>
  <p>After logging in, you can change your password from the Settings page.</p>
  <p style="color:#6B7280;font-size:12px;">This email was sent by Intellix. Please do not share your credentials.</p>
</div>
              `
            }
          });

          console.log(`✅ Successfully provisioned and emailed: ${email}`);
          
        } catch (error) {
          if (error.code === 'auth/email-already-exists') {
            // Already manually signed up, just mark provisioned flag
            console.log(`ℹ️ ${email} already has an Auth account. Marking provisioned...`);
            await doc.ref.update({ account_provisioned: true });
          } else {
            console.error(`❌ Error provisioning expert ${email}:`, error);
          }
        }
      }
    }
  }, (err) => {
    console.error('❌ Expert Provisioner listener error:', err);
  });
};

module.exports = { startExpertProvisioner };
