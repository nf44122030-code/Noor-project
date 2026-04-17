const express = require('express');
const router = express.Router();
const { RtcTokenBuilder, RtcRole } = require('agora-token');

// Need to match the client
const APP_ID = process.env.AGORA_APP_ID || 'c1e946d412a4440c8fa0d51e481544c6';
const APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE || 'c1a88f42995e47458d0e442a29943fdb';

router.post('/token', (req, res) => {
  res.header("Access-Control-Allow-Origin", "*");
  const { channelName, uid } = req.body;

  if (!channelName) {
    return res.status(400).json({ error: 'channel is required' });
  }

  // Get UID from request, default to 0 for generating tokens allowing any uid
  let uidVal = uid || 0;
  
  // Role
  const role = RtcRole.PUBLISHER;

  // Token expires in 24 hours
  const expireTime = 86400;
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
    res.json({ token });
  } catch (err) {
    console.error('Error generating token:', err);
    res.status(500).json({ error: 'Failed to generate token' });
  }
});

module.exports = router;
