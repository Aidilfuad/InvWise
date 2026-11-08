import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, x-client-info, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const roles = [
  "Super Admin",
  "Inventory Administrator",
  "Warehouse Supervisor",
  "Storekeeper",
] as const;

type UserRole = typeof roles[number];
type UserProfile = {
  id: string;
  auth_user_id: string | null;
  employee_id: string | null;
  full_name: string | null;
  email: string | null;
  role: UserRole;
  is_active: boolean;
  last_login_at: string | null;
};

const jsonResponse = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

const messageOf = (error: unknown) =>
  error instanceof Error ? error.message : "Unexpected user management failure.";

const isUuid = (value: unknown): value is string =>
  typeof value === "string" &&
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);

const isRole = (value: unknown): value is UserRole =>
  typeof value === "string" && roles.includes(value as UserRole);

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
      error: "User management service configuration is incomplete.",
    }, 500);
  }

  const accessToken = request.headers
    .get("Authorization")
    ?.match(/^Bearer\s+(.+)$/i)?.[1];
  if (!accessToken) {
    return jsonResponse({ error: "Sign in as a Super Admin." }, 401);
  }

  const admin = createClient(serviceUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: authData, error: authError } =
    await admin.auth.getUser(accessToken);
  if (authError || !authData.user) {
    return jsonResponse({ error: "Your session is invalid or expired." }, 401);
  }

  const { data: caller, error: callerError } = await admin
    .from("profiles")
    .select("role, is_active")
    .eq("auth_user_id", authData.user.id)
    .maybeSingle();
  if (callerError) {
    return jsonResponse({
      error: `Unable to verify Super Admin access: ${callerError.message}`,
    }, 500);
  }
  if (caller?.role !== "Super Admin" || caller.is_active !== true) {
    return jsonResponse(
      { error: "Only an active Super Admin can manage users." },
      403,
    );
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

  const action = body.action;
  try {
    if (action === "list") {
      const users: UserProfile[] = [];
      const pageSize = 1000;
      for (let offset = 0; ; offset += pageSize) {
        const { data, error } = await admin
          .from("profiles")
          .select(
            "id, auth_user_id, employee_id, full_name, email, role, " +
              "is_active, last_login_at",
          )
          .order("full_name", { ascending: true })
          .range(offset, offset + pageSize - 1);
        if (error) throw error;
        users.push(...data as UserProfile[]);
        if (data.length < pageSize) break;
      }
      return jsonResponse({
        users: users.map((user) => ({
          id: user.id,
          auth_user_id: user.auth_user_id,
          employee_id: user.employee_id,
          full_name: user.full_name,
          email: user.email,
          role: user.role,
          is_active: user.is_active,
          last_login_at: user.last_login_at,
          is_self: user.auth_user_id === authData.user.id,
        })),
      });
    }

    if (!isUuid(body.user_id)) {
      return jsonResponse({ error: "A valid user_id is required." }, 400);
    }

    const { data: target, error: targetError } = await admin
      .from("profiles")
      .select("id, auth_user_id, role, is_active")
      .eq("id", body.user_id)
      .maybeSingle();
    if (targetError) throw targetError;
    if (!target || !target.auth_user_id) {
      return jsonResponse({ error: "The user account was not found." }, 404);
    }

    if (action === "change_role") {
      if (!isRole(body.role)) {
        return jsonResponse({ error: "Select a supported user role." }, 400);
      }
      const { error } = await admin.rpc("manage_user_account", {
        p_actor_auth_user_id: authData.user.id,
        p_target_profile_id: target.id,
        p_action: "change_role",
        p_role: body.role,
      });
      if (error) throw error;
      return jsonResponse({ updated: true });
    }

    if (action === "set_active") {
      if (typeof body.is_active !== "boolean") {
        return jsonResponse({ error: "An is_active boolean is required." }, 400);
      }
      if (target.is_active === body.is_active) {
        return jsonResponse({ updated: true });
      }

      if (body.is_active === false) {
        const { error: banError } = await admin.auth.admin.updateUserById(
          target.auth_user_id,
          { ban_duration: "876000h" },
        );
        if (banError) throw banError;
        const { error: profileError } = await admin.rpc(
          "manage_user_account",
          {
            p_actor_auth_user_id: authData.user.id,
            p_target_profile_id: target.id,
            p_action: "set_active",
            p_is_active: false,
          },
        );
        if (profileError) {
          const { error: rollbackError } = await admin.auth.admin
            .updateUserById(target.auth_user_id, { ban_duration: "none" });
          if (rollbackError) {
            throw new Error(
              `Account status update failed: ${profileError.message}. ` +
                `Auth rollback failed: ${rollbackError.message}`,
            );
          }
          throw profileError;
        }
      } else {
        const { error: unbanError } = await admin.auth.admin.updateUserById(
          target.auth_user_id,
          { ban_duration: "none" },
        );
        if (unbanError) throw unbanError;
        const { error: profileError } = await admin.rpc(
          "manage_user_account",
          {
            p_actor_auth_user_id: authData.user.id,
            p_target_profile_id: target.id,
            p_action: "set_active",
            p_is_active: true,
          },
        );
        if (profileError) {
          const { error: rollbackError } = await admin.auth.admin.updateUserById(
            target.auth_user_id,
            { ban_duration: "876000h" },
          );
          if (rollbackError) {
            throw new Error(
              `Profile activation failed: ${profileError.message}. ` +
                `Auth rollback failed: ${rollbackError.message}`,
            );
          }
          throw profileError;
        }
      }
      return jsonResponse({ updated: true });
    }

    return jsonResponse({ error: "Unsupported user management action." }, 400);
  } catch (error) {
    return jsonResponse({ error: messageOf(error) }, 500);
  }
});
