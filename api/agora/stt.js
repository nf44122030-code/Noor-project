// Vercel serverless function for Agora Real-Time Speech-To-Text
// POST /api/agora/stt  — body: { action: "start"|"stop", channelName, agentId? }

export default async function handler(req, res) {
  // CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const APP_ID = 'c1e946d412a4440c8fa0d51e481544c6';
  const CUSTOMER_KEY = '36eac3424b0b471f8dab41189c5bc87e';
  const CUSTOMER_SECRET = 'f66f2083079d48a49e12943116bca44d';

  // Basic Auth: base64(key:secret)
  const credentials = Buffer.from(`${CUSTOMER_KEY}:${CUSTOMER_SECRET}`).toString('base64');
  const authHeader = `Basic ${credentials}`;

  const APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE || 'c1a88f42995e47458d0e442a29943fdb';

  const { action, channelName, agentId } = req.body || {};

  try {
    if (action === 'start') {
      if (!channelName) return res.status(400).json({ error: 'channelName is required' });

      // Generate tokens for the STT bots
      let subBotToken = '';
      let pubBotToken = '';
      try {
        const agoraLib = require('agora-token');
        const role = agoraLib.RtcRole.PUBLISHER;
        const privilegeExpireTime = Math.floor(Date.now() / 1000) + 86400;
        
        subBotToken = agoraLib.RtcTokenBuilder.buildTokenWithUid(
          APP_ID, APP_CERTIFICATE, channelName, 47091, role, privilegeExpireTime, privilegeExpireTime
        );
        pubBotToken = agoraLib.RtcTokenBuilder.buildTokenWithUid(
          APP_ID, APP_CERTIFICATE, channelName, 88222, role, privilegeExpireTime, privilegeExpireTime
        );
      } catch (e) {
        console.error('STT Token generation failed:', e);
      }

      // Start STT agent
      const response = await fetch(
        `https://api.agora.io/api/speech-to-text/v1/projects/${APP_ID}/join`,
        {
          method: 'POST',
          headers: {
            'Authorization': authHeader,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            languages: ['en-US'],
            name: `stt-${channelName}`,
            maxIdleTime: 120,
            rtcConfig: {
              channelName: channelName,
              subBotUid: '47091',
              subBotToken: subBotToken,
              pubBotUid: '88222',
              pubBotToken: pubBotToken,
            },
          }),
        }
      );

      const data = await response.json();
      if (!response.ok) {
        console.error('Agora STT start error:', data);
        return res.status(response.status).json({ error: 'Failed to start STT', details: data });
      }

      return res.status(200).json({
        agentId: data.agent_id,
        status: data.status,
        pubBotUid: 88222,
        subBotUid: 47091,
      });

    } else if (action === 'stop') {
      if (!agentId) return res.status(400).json({ error: 'agentId is required' });

      // Stop STT agent
      const response = await fetch(
        `https://api.agora.io/api/speech-to-text/v1/projects/${APP_ID}/agents/${agentId}/leave`,
        {
          method: 'POST',
          headers: {
            'Authorization': authHeader,
            'Content-Type': 'application/json',
          },
        }
      );

      const data = await response.json();
      return res.status(200).json({ status: 'stopped', details: data });

    } else {
      return res.status(400).json({ error: 'action must be "start" or "stop"' });
    }
  } catch (error) {
    console.error('STT API error:', error);
    return res.status(500).json({ error: error.message });
  }
}
