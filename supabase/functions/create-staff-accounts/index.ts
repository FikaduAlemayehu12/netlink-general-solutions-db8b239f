import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface StaffMember {
  full_name: string;
  email: string;
  position: string;
  department: string;
  role: string;
}

const STAFF_LIST: StaffMember[] = [
  { full_name: "Fikadu Alemayehu", email: "fikadu@netlink-gs.com", position: "Founder & CEO", department: "Executive", role: "ceo" },
  { full_name: "Haftu Girmay", email: "haftu@netlink-gs.com", position: "Chief Technology Officer", department: "Executive", role: "cto" },
  { full_name: "Feyisa Bekele", email: "feyisa@netlink-gs.com", position: "Chief Information Officer", department: "Executive", role: "cio" },
  { full_name: "Oumer Kasaw", email: "oumer@netlink-gs.com", position: "Chief Operating Officer", department: "Executive", role: "coo" },
  { full_name: "Ysak Alemayehu", email: "ysak@netlink-gs.com", position: "Head of Business Development", department: "Business Development", role: "bd_head" },
  { full_name: "Hana Alemu", email: "hana@netlink-gs.com", position: "Lead Software Engineer", department: "Software", role: "staff" },
  { full_name: "Haftu Girmay", email: "haftu2@netlink-gs.com", position: "Senior Technical Engineer", department: "Engineering", role: "staff" },
  { full_name: "Kirubel Asrat", email: "kirubel@netlink-gs.com", position: "Technical Team Member", department: "Engineering", role: "staff" },
  { full_name: "Getachew Adamu", email: "getachew@netlink-gs.com", position: "Technical Team Member", department: "Engineering", role: "staff" },
  { full_name: "Lalisa", email: "lalisa@netlink-gs.com", position: "Software Engineer", department: "Software", role: "staff" },
  { full_name: "Fayera", email: "fayera@netlink-gs.com", position: "IT & Network Engineer", department: "Infrastructure", role: "network_engineer" },
  { full_name: "Lalisa", email: "lalisa2@netlink-gs.com", position: "IT & Network Engineer", department: "Infrastructure", role: "network_engineer" },
  { full_name: "Henok", email: "henok@netlink-gs.com", position: "IT & Network Engineer", department: "Infrastructure", role: "network_engineer" },
  { full_name: "Endale", email: "endale@netlink-gs.com", position: "Data Center & Facility Engineer", department: "Infrastructure", role: "support_tech" },
  { full_name: "Abebe", email: "abebe@netlink-gs.com", position: "Data Center & Facility Engineer", department: "Infrastructure", role: "support_tech" },
  { full_name: "Abdi", email: "abdi@netlink-gs.com", position: "Data Center & Facility Engineer", department: "Infrastructure", role: "support_tech" },
];

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    const results: { email: string; status: string; error?: string }[] = [];

    for (const staff of STAFF_LIST) {
      try {
        // Check if user already exists
        const { data: existingProfiles } = await supabaseAdmin
          .from("profiles")
          .select("user_id")
          .eq("email", staff.email)
          .maybeSingle();

        if (existingProfiles) {
          // Update existing profile and reset password
          await supabaseAdmin.from("profiles").update({
            full_name: staff.full_name,
            position: staff.position,
            department: staff.department,
            must_change_password: true,
          }).eq("email", staff.email);

          // Reset password back to default
          await supabaseAdmin.auth.admin.updateUserById(existingProfiles.user_id, {
            password: "netlink123",
          });

          results.push({ email: staff.email, status: "already_exists_updated" });
          continue;
        }

        // Create auth user
        const { data: userData, error: createError } = await supabaseAdmin.auth.admin.createUser({
          email: staff.email,
          password: "netlink123",
          email_confirm: true,
          user_metadata: { full_name: staff.full_name },
        });

        if (createError || !userData.user) {
          results.push({ email: staff.email, status: "error", error: createError?.message });
          continue;
        }

        // Update profile with position and department
        await supabaseAdmin.from("profiles").update({
          full_name: staff.full_name,
          position: staff.position,
          department: staff.department,
          must_change_password: true,
        }).eq("user_id", userData.user.id);

        // Assign role
        await supabaseAdmin.from("user_roles").insert({
          user_id: userData.user.id,
          role: staff.role,
        });

        results.push({ email: staff.email, status: "created" });
      } catch (e) {
        results.push({ email: staff.email, status: "error", error: String(e) });
      }
    }

    return new Response(JSON.stringify({ results }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
