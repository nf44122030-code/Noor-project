module.exports = (req, res) => {
  // Try to load agora-token safely
  let RtcTokenBuilder, RtcRole;
  try {
    const agoraLib = require('agora-token');
    RtcTokenBuilder = agoraLib.RtcTokenBuilder;
    RtcRole = agoraLib.RtcRole;
  } catch(e) {
    return res.status(500).json({ error: 'Agora library missing on Vercel backend. ' + e.message });
  }

  // Set CORS headers
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  const { channelName, uid } = req.body || {};

  if (!channelName) {
    return res.status(400).json({ error: 'channelName is required' });
  }

  const APP_ID = process.env.AGORA_APP_ID || 'c1e946d412a4440c8fa0d51e481544c6';
  const APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE || 'c1a88f42995e47458d0e442a29943fdb';

  let uidVal = uid || 0;
  const role = RtcRole.PUBLISHER;
  const expireTime = 86400; // 24 hours
  const currentTime = Math.floor(Date.now() / 1000);
  const privilegeExpireTime = currentTime + expireTime;

  try {
    const token = RtcTokenBuilder.buildTokenWithUid(
      APP_ID,
      APP_CERTIFICATE,
      channelName,
      uidVal,
      role,
      privilegeExpireTime,
      privilegeExpireTime
    );
    res.status(200).json({ token });
  } catch (err) {
    console.error('Error generating token:', err);
    res.status(500).json({ error: 'Failed to generate token' });
  }
};
