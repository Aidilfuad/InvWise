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

const errorMessage = (error: unknown) =>
  error instanceof Error
    ? error.message
    : error && typeof error === "object" && "message" in error &&
        typeof error.message === "string"
    ? error.message
    : "Unexpected registration request failure.";

const stringField = (value: unknown) =>
  typeof value === "string" ? value.trim() : "";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  const serviceUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceUrl || !serviceRoleKey) {
    return jsonResponse({
      error: "Registration request service configuration is incomplete.",
    }, 500);
  }

  let body: Record<string, unknown>;
  try {
    const parsed: unknown = await request.json();
    if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
      return jsonResponse({ error: "A JSON object is required." }, 400);
    }
    body = parsed as Record<string, unknown>;
  } catch {
    return jsonResponse({ error: "A valid JSON request body is required." }, 400);
  }

  const fullName = stringField(body.full_name);
  const email = stringField(body.email).toLowerCase();
  const employeeId = stringField(body.employee_id);
  const department = stringField(body.department);
  const requestedRole = stringField(body.requested_role);
  const reason = stringField(body.reason);
  const password = typeof body.password === "string" ? body.password : "";

  if (
    !fullName || fullName.length > 160 ||
    !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) || email.length > 254 ||
    !employeeId || employeeId.length > 64 ||
    !department || department.length > 120 ||
    !requestedRole || requestedRole.length > 100 ||
    reason.length > 1000
  ) {
    return jsonResponse({ error: "Complete each field with a valid value." }, 400);
  }
  if (
    password.length < 8 ||
    password.length > 256 ||
    !/[A-Za-z]/.test(password) ||
    !/\d/.test(password)
  ) {
    return jsonResponse({
      error: "Use a password of 8 to 256 characters with at least one letter and one number.",
    }, 400);
  }
  if (["super admin", "super user"].includes(requestedRole.toLowerCase())) {
    return jsonResponse({ error: "That role cannot be requested through this form." }, 400);
  }

  const admin = createClient(serviceUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  for (let page = 1; ; page += 1) {
    const { data: profiles, error: profilesError } = await admin
      .from("profiles")
      .select("id,email,employee_id")
      .range((page - 1) * 1000, page * 1000 - 1);
    if (profilesError) {
      return jsonResponse({
        error: `Unable to verify the requested email and employee ID: ${profilesError.message}`,
      }, 500);
    }
    if (!profiles) {
      return jsonResponse({
        error: "Unable to verify the requested email and employee ID.",
      }, 500);
    }
    const conflict = profiles.find((profile) =>
      profile.email?.trim().toLowerCase() === email ||
      profile.employee_id?.trim().toLowerCase() === employeeId.toLowerCase()
    );
    if (conflict) {
      return jsonResponse({
        error: "An account already uses this email or employee ID. Contact a workspace administrator.",
      }, 409);
    }
    if (profiles.length < 1000) break;
  }

  for (let page = 1; ; page += 1) {
    const { data: requests, error: requestsError } = await admin
      .from("registration_requests")
      .select("email,employee_id")
      .eq("status", "pending")
      .range((page - 1) * 1000, page * 1000 - 1);
    if (requestsError) {
      return jsonResponse({
        error: `Unable to check for a pending request with this identity: ${requestsError.message}`,
      }, 500);
    }
    if (!requests) {
      return jsonResponse({
        error: "Unable to check for a pending request with this identity.",
      }, 500);
    }
    const duplicate = requests.find((registration) =>
      registration.email.trim().toLowerCase() === email ||
      registration.employee_id.trim().toLowerCase() === employeeId.toLowerCase()
    );
    if (duplicate) {
      return jsonResponse({
        error: "A pending request already uses this email or employee ID.",
      }, 409);
    }
    if (requests.length < 1000) break;
  }

  const requestId = crypto.randomUUID();
  const { data: createdAuthUser, error: createAuthError } =
    await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: false,
      ban_duration: "876000h",
      user_metadata: {
        registration_request_id: requestId,
        registration_request_flow: true,
      },
    });
  if (createAuthError) {
    const duplicateAccount = /already registered|already exists/i.test(
      errorMessage(createAuthError),
    );
    return jsonResponse(
      { error: errorMessage(createAuthError) },
      duplicateAccount ? 409 : 500,
    );
  }
  if (!createdAuthUser.user) {
    return jsonResponse({ error: "Supabase did not return the Auth user." }, 500);
  }

  const { error: insertError } = await admin
    .from("registration_requests")
    .insert({
      id: requestId,
      full_name: fullName,
      email,
      employee_id: employeeId,
      department,
      requested_role: requestedRole,
      reason: reason || null,
      status: "pending",
      provisioning_auth_user_id: createdAuthUser.user.id,
    });
  if (insertError) {
    const { error: authCleanupError } = await admin.auth.admin.deleteUser(
      createdAuthUser.user.id,
    );
    const { error: requestCleanupError } = await admin
      .from("registration_requests")
      .delete()
      .eq("id", requestId);
    const cleanupErrors = [
      authCleanupError && `Auth cleanup failed: ${authCleanupError.message}`,
      requestCleanupError && `Request cleanup failed: ${requestCleanupError.message}`,
    ].filter(Boolean);
    return jsonResponse({
      error: [
        `Unable to save the registration request: ${insertError.message}`,
        ...cleanupErrors,
      ].join(" "),
    }, 500);
  }

  return jsonResponse({
    request_id: requestId,
    status: "pending",
    message: "Your request is pending Super Admin approval. Sign-in is enabled after approval; no invitation email is required.",
  }, 201);
});
