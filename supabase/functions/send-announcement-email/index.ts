import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');
  if (!RESEND_API_KEY) {
    return new Response(JSON.stringify({ error: 'RESEND_API_KEY not configured' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  try {
    const { title, content, recipients } = await req.json();

    if (!title || !content || !recipients?.length) {
      return new Response(JSON.stringify({ error: 'Missing title, content, or recipients' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const results = [];
    for (const email of recipients) {
      const res = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${RESEND_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: 'Netlink GS <onboarding@resend.dev>',
          to: email,
          subject: `📢 ${title}`,
          html: `
            <div style="font-family: 'Segoe UI', sans-serif; max-width: 600px; margin: 0 auto;">
              <div style="background: linear-gradient(135deg, #1B5EB5, #2196F3); padding: 28px 24px; border-radius: 12px 12px 0 0;">
                <h1 style="color: white; margin: 0; font-size: 22px; font-weight: 700;">NETLINK General Solutions</h1>
                <p style="color: rgba(255,255,255,0.7); margin: 6px 0 0; font-size: 13px;">Company Announcement</p>
              </div>
              <div style="background: white; padding: 28px 24px; border: 1px solid #e5e7eb; border-top: 0; border-radius: 0 0 12px 12px;">
                <h2 style="margin: 0 0 16px; color: #1B5EB5; font-size: 20px;">${title}</h2>
                <p style="color: #4b5563; line-height: 1.7; font-size: 15px; white-space: pre-wrap;">${content}</p>
                <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 24px 0;" />
                <p style="color: #9ca3af; font-size: 12px; margin: 0;">This is an automated announcement from the Netlink Staff Portal.</p>
              </div>
            </div>
          `,
        }),
      });
      const data = await res.json();
      results.push({ email, status: res.ok ? 'sent' : 'failed', data });
    }

    return new Response(JSON.stringify({ success: true, results }), {
      status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Error sending announcement email:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
