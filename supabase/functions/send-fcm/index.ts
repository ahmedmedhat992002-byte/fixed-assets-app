import { JWT } from 'npm:google-auth-library';

Deno.serve(async (req) => {
  console.log(`--- Edge Function Invoked (${req.method}) ---`)
  
  // Load Firebase Service Account from Supabase secrets
  const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY') || Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
  if (!serviceAccountJson) {
    return new Response(JSON.stringify({ error: 'Missing FIREBASE_SERVICE_ACCOUNT_KEY or FIREBASE_SERVICE_ACCOUNT secret' }), { status: 500 })
  }

  let serviceAccount: any
  try {
    serviceAccount = typeof serviceAccountJson === 'string' ? JSON.parse(serviceAccountJson) : serviceAccountJson
  } catch (e: any) {
    return new Response(JSON.stringify({ error: 'Failed to parse FIREBASE_SERVICE_ACCOUNT. Ensure it is a valid JSON string.', details: e.message }), { status: 500 })
  }

  // Generate Google OAuth token
  const jwt = new JWT({
    email: serviceAccount.client_email,
    key: serviceAccount.private_key.replace(/\\n/g, '\n'),
    scopes: ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/datastore'],
  })

  const tokenResponse = await jwt.getAccessToken()
  const accessToken = tokenResponse.token

  if (!accessToken) {
    return new Response(JSON.stringify({ error: 'Failed to generate access token' }), { status: 500 })
  }

  const projectId = serviceAccount.project_id

  // Handle GET request to retrieve diagnostic logs
  if (req.method === 'GET') {
    try {
      // Fetch Logs
      const logsEndpoint = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/debug_logs?pageSize=50`
      const logsRes = await fetch(logsEndpoint, {
        headers: { 'Authorization': `Bearer ${accessToken}` },
      })
      const logsData = await logsRes.json()

      // Fetch sample Tokens (just to verify they exist)
      // This is a bit complex as they are in subcollections. 
      // We'll use a collectionGroup query if enabled, or just list users and then tokens.
      // For now, let's just return the logs and a status.
      return new Response(JSON.stringify({
        logs: logsData,
        status: 'online',
        projectId: projectId,
        envAnonKeyDigest: Deno.env.get('SUPABASE_ANON_KEY')?.substring(0, 15) + '...'
      }), { headers: { 'Content-Type': 'application/json' }, status: 200 })
    } catch (error: any) {
      return new Response(JSON.stringify({ error: error.message }), { status: 500 })
    }
  }

  try {
    const { tokens, title, body, data } = await req.json()

    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ error: 'No tokens provided' }), { status: 400 })
    }
    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

    console.log(`Sending to project: ${projectId}`)
    console.log(`Payload title: ${title}`)
    console.log(`Tokens count: ${tokens.length}`)

    const successes = []
    const failures = []

    for (const token of tokens) {
      console.log(`Processing token: ${token.substring(0, 10)}...`)
      const fcmMessage = {
        message: {
          token: token,
          notification: {
            title: title,
            body: body,
          },
          data: {
            ...data,
            channel_id: 'high_importance_channel',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          android: {
            priority: 'high',
            notification: {
              channel_id: 'high_importance_channel',
              sound: 'default',
            },
          },
          apns: {
            headers: {
              'apns-priority': '10',
              'apns-push-type': 'alert',
            },
            payload: {
              aps: {
                'content-available': 1,
                'mutable-content': 1,
                sound: 'default',
                alert: {
                  title: title,
                  body: body,
                },
              },
            },
          },
        },
      }

      const response = await fetch(fcmEndpoint, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(fcmMessage),
      })

      const resData = await response.json()
      console.log(`FCM Response status: ${response.status}`)
      if (response.ok) {
        console.log(`FCM Success: ${JSON.stringify(resData)}`)
        successes.push(resData)
      } else {
        console.error(`FCM Failure: ${JSON.stringify(resData)}`)
        failures.push({ token: token.substring(0, 10) + '...', error: resData })
      }
    }

    return new Response(
      JSON.stringify({ successes, failures }),
      { headers: { 'Content-Type': 'application/json' }, status: 200 }
    )
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
