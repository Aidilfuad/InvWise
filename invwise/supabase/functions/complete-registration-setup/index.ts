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

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  const serviceUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const missingSecrets = [
    !serviceUrl && "SUPABASE_URL",
    !serviceRoleKey && "SUPABASE_SERVICE_ROLE_KEY",
  ].filter(Boolean);
  if (missingSecrets.length > 0) {
    return jsonResponse({
      error: `Account setup configuration is missing: ${missingSecrets.join(", ")}.`,
      stage: "configuration",
    }, 500);
  }

  const accessToken = request.headers
    .get("Authorization")
    ?.match(/^Bearer\s+(.+)$/i)?.[1];
  if (!accessToken) {
    return jsonResponse({ error: "Accept the invitation before continuing." }, 401);
  }

  const admin = createClient(serviceUrl, serviceRoleKey, {
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
    if (typeof requestId !== "string") {
      return jsonResponse({ error: "A valid request_id is required." }, 400);
    }
  } catch {
    return jsonResponse({ error: "A valid JSON request body is required." }, 400);
  }

  const { data: registration, error: requestError } = await admin
    .from("registration_requests")
    .select("id, provisioning_status, provisioning_auth_user_id, invited_at")
    .eq("id", requestId)
    .maybeSingle();
  if (
    requestError ||
    !registration ||
    registration.provisioning_auth_user_id !== authData.user.id ||
    !["invited", "completed"].includes(registration.provisioning_status)
  ) {
    return jsonResponse(
      { error: "This invitation is not linked to the signed-in account." },
      403,
    );
  }

  const tokenPayload = accessToken.split(".")[1];
  let hasRecentPasswordAuthentication = false;
  try {
    const encodedClaims = tokenPayload.replace(/-/g, "+").replace(/_/g, "/");
    const claims = JSON.parse(
      atob(encodedClaims.padEnd(Math.ceil(encodedClaims.length / 4) * 4, "=")),
    );
    const invitationTime = Date.parse(registration.invited_at);
    hasRecentPasswordAuthentication = Array.isArray(claims.amr) &&
      claims.amr.some((method: { method?: string; timestamp?: number }) =>
        method.method === "password" &&
        typeof method.timestamp === "number" &&
        method.timestamp * 1000 >= invitationTime
      );
  } catch {
    hasRecentPasswordAuthentication = false;
  }
  if (!hasRecentPasswordAuthentication) {
    return jsonResponse(
      { error: "Set your password and sign in again before completing setup." },
      403,
    );
  }

  if (registration.provisioning_status === "invited") {
    const { error: updateError } = await admin
      .from("registration_requests")
      .update({
        provisioning_status: "completed",
        completed_at: new Date().toISOString(),
      })
      .eq("id", requestId)
      .eq("provisioning_auth_user_id", authData.user.id)
      .eq("provisioning_status", "invited");
    if (updateError) {
      return jsonResponse({ error: "Unable to complete account setup." }, 500);
    }
  }

  const metadata = { ...authData.user.user_metadata };
  delete metadata.registration_request_id;
  const { error: metadataError } = await admin.auth.admin.updateUserById(
    authData.user.id,
    { user_metadata: metadata },
  );
  if (metadataError) {
    return jsonResponse(
      { error: "Account setup completed, but the invitation marker could not be cleared. Retry to finish." },
      500,
    );
  }

  return jsonResponse({ status: "completed" });
});
