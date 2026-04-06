import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { applicant_name, applicant_email, position, cover_message, cv_url, vacancy_id } = await req.json();

    if (!applicant_name || !applicant_email) {
      return new Response(JSON.stringify({ error: 'Name and email are required' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, serviceKey);

    // Insert application
    const { data: application, error: insertError } = await supabase
      .from('job_applications')
      .insert({
        applicant_name,
        applicant_email,
        position: position || null,
        cover_message: cover_message || null,
        cv_url: cv_url || null,
        vacancy_id: vacancy_id || null,
      })
      .select('id')
      .single();

    if (insertError) {
      console.error('Insert error:', insertError);
      return new Response(JSON.stringify({ error: 'Failed to save application' }), {
        status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Find CEO user(s) to notify
    const { data: ceoRoles } = await supabase
      .from('user_roles')
      .select('user_id')
      .eq('role', 'ceo');

    if (ceoRoles?.length) {
      // Create in-app notifications for CEO
      const notifications = ceoRoles.map((r: any) => ({
        user_id: r.user_id,
        type: 'application',
        title: '📄 New Job Application',
        message: `${applicant_name} (${applicant_email}) applied for ${position || 'a position'}`,
        related_id: application.id,
      }));
      await supabase.from('notifications').insert(notifications);

      // Send email to CEO
      const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');
      if (RESEND_API_KEY) {
        const { data: ceoProfiles } = await supabase
          .from('profiles')
          .select('email')
          .in('user_id', ceoRoles.map((r: any) => r.user_id));

        for (const profile of (ceoProfiles || [])) {
          await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${RESEND_API_KEY}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              from: 'Netlink GS <onboarding@resend.dev>',
              to: profile.email,
              subject: `📄 New Job Application: ${applicant_name} — ${position || 'General'}`,
              html: `
                <div style="font-family: 'Segoe UI', sans-serif; max-width: 600px; margin: 0 auto;">
                  <div style="background: linear-gradient(135deg, #1B5EB5, #2196F3); padding: 28px 24px; border-radius: 12px 12px 0 0;">
                    <h1 style="color: white; margin: 0; font-size: 22px; font-weight: 700;">NETLINK General Solutions</h1>
                    <p style="color: rgba(255,255,255,0.7); margin: 6px 0 0; font-size: 13px;">Job Application Received</p>
                  </div>
                  <div style="background: white; padding: 28px 24px; border: 1px solid #e5e7eb; border-top: 0; border-radius: 0 0 12px 12px;">
                    <h2 style="margin: 0 0 16px; color: #1B5EB5; font-size: 20px;">New Application</h2>
                    <table style="width: 100%; border-collapse: collapse; font-size: 14px; color: #4b5563;">
                      <tr><td style="padding: 8px 0; font-weight: 600; width: 140px;">Applicant</td><td>${applicant_name}</td></tr>
                      <tr><td style="padding: 8px 0; font-weight: 600;">Email</td><td><a href="mailto:${applicant_email}">${applicant_email}</a></td></tr>
                      <tr><td style="padding: 8px 0; font-weight: 600;">Position</td><td>${position || 'Not specified'}</td></tr>
                      ${cv_url ? `<tr><td style="padding: 8px 0; font-weight: 600;">CV/Resume</td><td><a href="${cv_url}" style="color: #1B5EB5;">Download CV</a></td></tr>` : ''}
                    </table>
                    ${cover_message ? `
                      <div style="margin-top: 20px; padding: 16px; background: #f9fafb; border-radius: 8px; border: 1px solid #e5e7eb;">
                        <p style="font-weight: 600; margin: 0 0 8px; font-size: 13px; color: #374151;">Cover Message</p>
                        <p style="color: #4b5563; line-height: 1.6; font-size: 14px; margin: 0; white-space: pre-wrap;">${cover_message}</p>
                      </div>
                    ` : ''}
                    <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 24px 0;" />
                    <p style="color: #9ca3af; font-size: 12px; margin: 0;">This is an automated notification from the Netlink Careers page.</p>
                  </div>
                </div>
              `,
            }),
          });
        }
      }
    }

    return new Response(JSON.stringify({ success: true, id: application.id }), {
      status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Error handling application:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
