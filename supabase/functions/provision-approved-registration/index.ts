import { createClient, type User } from "npm:@supabase/supabase-js@2";

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

const messageOf = (error: unknown) =>
  error instanceof Error ? error.message : "Unexpected provisioning failure.";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  const serviceUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const inviteRedirectUrl = Deno.env.get("INVITE_REDIRECT_URL");
  const missingSecrets = [
    !serviceUrl && "SUPABASE_URL",
    !serviceRoleKey && "SUPABASE_SERVICE_ROLE_KEY",
    !inviteRedirectUrl && "INVITE_REDIRECT_URL",
  ].filter(Boolean);
  if (missingSecrets.length > 0) {
    return jsonResponse({
      error: `Provisioning configuration is missing: ${missingSecrets.join(", ")}.`,
      stage: "configuration",
    }, 500);
  }

  const authorization = request.headers.get("Authorization");
  const accessToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
  if (!accessToken) {
    return jsonResponse({ error: "Sign in as an Inventory Administrator." }, 401);
  }

  const admin = createClient(serviceUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: userData, error: userError } =
    await admin.auth.getUser(accessToken);
  if (userError || !userData.user) {
    return jsonResponse({ error: "Your session is invalid or expired." }, 401);
  }

  const { data: profile, error: profileError } = await admin
    .from("profiles")
    .select("role")
    .eq("auth_user_id", userData.user.id)
    .maybeSingle();
  if (profileError) {
    return jsonResponse({
      error: `Unable to verify administrator role: ${profileError.message}`,
      stage: "administrator-role-check",
    }, 500);
  }
  if (profile?.role !== "Inventory Administrator") {
    return jsonResponse(
      {
        error: "Only an Inventory Administrator can provision accounts.",
        stage: "administrator-role-check",
      },
      403,
    );
  }

  let requestId: string;
  try {
    const body = await request.json();
    requestId = body.request_id;
    if (
      typeof requestId !== "string" ||
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
        .test(requestId)
    ) {
      return jsonResponse({ error: "A valid request_id is required." }, 400);
    }
  } catch {
    return jsonResponse({ error: "A valid JSON request body is required." }, 400);
  }

  const { data: claim, error: claimError } = await admin.rpc(
    "claim_registration_provisioning",
    { p_request_id: requestId },
  );
  if (claimError || !claim) {
    return jsonResponse(
      { error: claimError?.message ?? "Unable to claim this request." },
      409,
    );
  }

  const status = claim.provisioning_status as string;
  if (claim.claimed !== true) {
    if (status === "invited" || status === "completed") {
      return jsonResponse({ status, message: "This request is already provisioned." });
    }
    return jsonResponse(
      { error: "Provisioning is already in progress. Try again shortly." },
      409,
    );
  }

  let stage = "load-approved-request";
  try {
    const email = String(claim.email).trim().toLowerCase();
    let authUserId = claim.provisioning_auth_user_id as string | null;
    let invitedUser: User | null = null;

    if (authUserId) {
      stage = "verify-existing-auth-user";
      const { data, error } = await admin.auth.admin.getUserById(authUserId);
      if (error || !data.user || data.user.email?.toLowerCase() !== email) {
        throw new Error("The previously invited Auth user could not be verified.");
      }
      invitedUser = data.user;
    } else {
      stage = "check-for-existing-auth-user";
      for (let page = 1; ; page += 1) {
        const { data, error } = await admin.auth.admin.listUsers({
          page,
          perPage: 1000,
        });
        if (error) throw error;
        const existing = data.users.find(
          (candidate) => candidate.email?.toLowerCase() === email,
        );
        if (existing) {
          if (existing.user_metadata?.registration_request_id !== requestId) {
            throw new Error(
              "An Auth account already exists for this email and cannot be linked automatically.",
            );
          }
          invitedUser = existing;
          break;
        }
        if (data.users.length < 1000) break;
      }

      if (!invitedUser) {
        stage = "send-auth-invitation";
        const { data, error } = await admin.auth.admin.inviteUserByEmail(email, {
          data: { registration_request_id: requestId },
          redirectTo: inviteRedirectUrl,
        });
        if (error) throw error;
        invitedUser = data.user;
      }
      authUserId = invitedUser?.id ?? null;
    }

    if (!authUserId) throw new Error("Supabase did not return an invited user.");

    stage = "link-auth-user-to-request";
    const { error: linkError } = await admin
      .from("registration_requests")
      .update({ provisioning_auth_user_id: authUserId })
      .eq("id", requestId)
      .eq("provisioning_status", "in_progress");
    if (linkError) throw linkError;

    stage = "create-profile-and-mark-invited";
    const { error: profileCreationError } = await admin.rpc(
      "create_registration_profile",
      { p_request_id: requestId, p_auth_user_id: authUserId },
    );
    if (profileCreationError) throw profileCreationError;

    return jsonResponse({
      status: "invited",
      message: "The account was created and an invitation email was sent.",
    });
  } catch (error) {
    const message = messageOf(error);
    const { error: failureStateError } = await admin
      .from("registration_requests")
      .update({
        provisioning_status: "failed",
        provisioning_error: message.slice(0, 1000),
        provisioning_started_at: null,
      })
      .eq("id", requestId)
      .eq("provisioning_status", "in_progress");
    if (failureStateError) {
      return jsonResponse({
        error: `${stage}: ${message}. The failure status also could not be saved: ${failureStateError.message}`,
        stage,
      }, 500);
    }
    return jsonResponse({ error: `${stage}: ${message}`, stage }, 500);
  }
});
