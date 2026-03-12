import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { JWT } from 'https://cdn.jsdelivr.net/gh/GJZwille/deno-googleapis/mod.ts'

serve(async (req) => {
  try {
    const { tokens, title, body, data } = await req.json()

    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ error: 'No tokens provided' }), { status: 400 })
    }

    // Load Firebase Service Account from Supabase secrets
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY')
    if (!serviceAccountJson) {
      return new Response(JSON.stringify({ error: 'Missing FIREBASE_SERVICE_ACCOUNT_KEY' }), { status: 500 })
    }

    const serviceAccount = JSON.parse(serviceAccountJson)

    // Generate Google OAuth token
    const jwt = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key.replace(/\\n/g, '\n'),
      scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    })

    const accessToken = (await jwt.getToken()).token

    // Send notifications via HTTP v1 API
    const projectId = serviceAccount.project_id
    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

    const successes = []
    const failures = []

    for (const token of tokens) {
      const fcmMessage = {
        message: {
          token: token,
          notification: {
            title: title,
            body: body,
          },
          data: data,
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
            },
            payload: {
              aps: {
                'content-available': 1,
                'mutable-content': 1,
                sound: 'default',
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
      if (response.ok) {
        successes.push(resData)
      } else {
        failures.push(resData)
      }
    }

    return new Response(
      JSON.stringify({ successes, failures }),
      { headers: { 'Content-Type': 'application/json' }, status: 200 }
    )
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
