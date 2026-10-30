import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, x-client-info, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const jsonResponse = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  const serviceUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const resendApiKey = Deno.env.get("RESEND_API_KEY");
  const adminEmail = Deno.env.get("SUPPORT_ADMIN_EMAIL");
  const fromEmail = Deno.env.get("SUPPORT_FROM_EMAIL");
  const missingSecrets = [
    !serviceUrl && "SUPABASE_URL",
    !serviceRoleKey && "SUPABASE_SERVICE_ROLE_KEY",
    !resendApiKey && "RESEND_API_KEY",
    !adminEmail && "SUPPORT_ADMIN_EMAIL",
    !fromEmail && "SUPPORT_FROM_EMAIL",
  ].filter(Boolean);
  if (missingSecrets.length > 0) {
    return jsonResponse({
      error: `Support email configuration is missing: ${missingSecrets.join(", ")}.`,
    }, 500);
  }

  const accessToken = request.headers
    .get("Authorization")
    ?.match(/^Bearer\s+(.+)$/i)?.[1];
  if (!accessToken) {
    return jsonResponse({ error: "Sign in to notify IT Support." }, 401);
  }

  const admin = createClient(serviceUrl!, serviceRoleKey!, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: authData, error: authError } =
    await admin.auth.getUser(accessToken);
  if (authError || !authData.user) {
    return jsonResponse({ error: "Your session is invalid or expired." }, 401);
  }

  let requestId: string;
  try {
    const body = await request.json();
    requestId = body.request_id;
    if (typeof requestId !== "string" || !uuidPattern.test(requestId)) {
      return jsonResponse({ error: "A valid request_id is required." }, 400);
    }
  } catch {
    return jsonResponse({ error: "A valid JSON request body is required." }, 400);
  }

  const { data: profile, error: profileError } = await admin
    .from("profiles")
    .select("id")
    .eq("auth_user_id", authData.user.id)
    .maybeSingle();
  if (profileError || !profile) {
    return jsonResponse({ error: "Unable to verify your support request." }, 403);
  }

  const { data: supportRequest, error: requestError } = await admin
    .from("support_requests")
    .select("id,profile_id,subject,message,notification_status")
    .eq("id", requestId)
    .maybeSingle();
  if (requestError || !supportRequest || supportRequest.profile_id !== profile.id) {
    return jsonResponse({ error: "Support request not found." }, 404);
  }
  if (supportRequest.notification_status === "sent") {
    return jsonResponse({ notification_sent: true, already_sent: true });
  }
  if (supportRequest.notification_status === "sending") {
    return jsonResponse({ notification_sent: false, status: "sending" }, 409);
  }

  const { data: claimedRequest, error: claimError } = await admin
    .from("support_requests")
    .update({
      notification_status: "sending",
      notification_error: null,
    })
    .eq("id", requestId)
    .in("notification_status", ["not_sent", "failed"])
    .select("id")
    .maybeSingle();
  if (claimError || !claimedRequest) {
    return jsonResponse({
      error: claimError?.message ?? "The notification is already being processed.",
    }, 409);
  }

  let providerError: string | null = null;
  try {
    const emailResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
        "Idempotency-Key": `support-request-${requestId}`,
      },
      body: JSON.stringify({
        from: fromEmail,
        to: [adminEmail],
        subject: `InvWise support request: ${supportRequest.subject}`,
        text: [
          `Support request ID: ${requestId}`,
          `Subject: ${supportRequest.subject}`,
          "",
          supportRequest.message,
        ].join("\n"),
      }),
    });
    if (!emailResponse.ok) {
      providerError = (await emailResponse.text()).slice(0, 1000);
    }
  } catch (error) {
    providerError = error instanceof Error ? error.message : String(error);
  }
  if (providerError !== null) {
    const { error: statusError } = await admin
      .from("support_requests")
      .update({
        notification_status: "failed",
        notification_error: providerError,
      })
      .eq("id", requestId);
    if (statusError) {
      return jsonResponse({
        error: `Email notification failed, and its failure status could not be saved: ${statusError.message}`,
      }, 500);
    }
    return jsonResponse({
      error: `Email notification failed: ${providerError}`,
    }, 502);
  }

  const { error: updateError } = await admin
    .from("support_requests")
    .update({
      notification_status: "sent",
      notification_sent_at: new Date().toISOString(),
      notification_error: null,
    })
    .eq("id", requestId);
  if (updateError) {
    return jsonResponse({
      error: "The email was sent, but its delivery status could not be saved.",
    }, 500);
  }

  return jsonResponse({ notification_sent: true });
});
