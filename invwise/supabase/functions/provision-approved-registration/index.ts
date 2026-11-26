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

const errorField = (
  error: unknown,
  key: "code" | "details" | "hint" | "message",
) => {
  if (!error || typeof error !== "object" || !(key in error)) return undefined;
  const value = (error as Record<string, unknown>)[key];
  return typeof value === "string" && value.trim() ? value : undefined;
};

const messageOf = (error: unknown) => {
  const message = error instanceof Error
    ? error.message
    : typeof error === "string" && error.trim()
    ? error
    : errorField(error, "message") ??
      "The provisioning operation failed without a readable error message.";
  const details = errorField(error, "details");
  const hint = errorField(error, "hint");
  return [message, details && `Details: ${details}`, hint && `Hint: ${hint}`]
    .filter(Boolean)
    .join(" ");
};

const errorFields = (error: unknown) => ({
  ...(errorField(error, "code") ? { code: errorField(error, "code") } : {}),
  ...(errorField(error, "details") ? { details: errorField(error, "details") } : {}),
  ...(errorField(error, "hint") ? { hint: errorField(error, "hint") } : {}),
});

const isEmailRateLimitError = (error: unknown) =>
  /email.*rate.?limit|rate.?limit.*email|too many requests/i.test(messageOf(error));

const isMissingEmailRateLimitColumnError = (error: unknown) =>
  errorField(error, "code") === "PGRST204" &&
  messageOf(error).includes("invite_email_rate_limited");

const isPasswordPolicyError = (error: unknown) =>
  /weak.?password|(?:password|weak).*(?:minimum|short|length|least|character|strength|contain|policy)|(?:minimum|short|length|least|character|strength|contain|policy).*(?:password|weak)/i
    .test(messageOf(error));

const employeeIdPasswordFailure = (error: unknown) => {
  const reason = messageOf(error);
  if (!isPasswordPolicyError(error)) {
    return new Error(
      `Unable to set the Employee ID as the initial password: ${reason}`,
    );
  }
  return new Error(
    "Supabase Auth rejected the Employee ID as the initial password: " +
      `${reason} Ensure the Employee ID meets the project's configured ` +
      "minimum password length and password requirements.",
  );
};

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
    .select("role, is_active")
    .eq("auth_user_id", userData.user.id)
    .maybeSingle();
  if (profileError) {
    return jsonResponse({
      error: `Unable to verify administrator role: ${profileError.message}`,
      stage: "administrator-role-check",
    }, 500);
  }
  const isLegacyAdministrator = profile?.role === "Inventory Administrator";
  const isSuperAdmin = profile?.role === "Super Admin";
  const { data: permissions, error: permissionError } = profile?.role
    ? await admin
      .from("role_permissions")
      .select("permission_key,granted")
      .eq("role_name", profile.role)
      .eq("permission_key", "manage_registration_requests")
      .eq("granted", true)
    : { data: [], error: null };
  if (permissionError) {
    return jsonResponse({
      error: `Unable to verify registration approval access: ${permissionError.message}`,
      stage: "administrator-permission-check",
    }, 500);
  }
  if (
    !profile?.is_active ||
    !(isLegacyAdministrator || isSuperAdmin || permissions?.length)
  ) {
    return jsonResponse(
      {
        error: "Only an active Inventory Administrator or Super Admin can provision accounts.",
        stage: "administrator-role-check",
      },
      403,
    );
  }

  let requestId: string;
  let inviteRedirectUrl: string;
  try {
    const body = await request.json();
    requestId = body.request_id;
    const redirectTarget = body.redirect_target ?? "web";
    if (redirectTarget !== "web" && redirectTarget !== "mobile") {
      return jsonResponse({
        error: "redirect_target must be either web or mobile.",
      }, 400);
    }
    inviteRedirectUrl = redirectTarget === "mobile"
      ? Deno.env.get("MOBILE_INVITE_REDIRECT_URL")?.trim() ||
        "invwise://auth/registration-setup"
      : Deno.env.get("INVITE_REDIRECT_URL")?.trim() ||
        "https://invwise-activation.vercel.app";
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
      {
        error: claimError?.message ?? "Unable to claim this request.",
        stage: "claim-provisioning",
        ...errorFields(claimError),
      },
      409,
    );
  }

  const status = claim.provisioning_status as string;
  if (claim.claimed !== true) {
    if (status === "invited" || status === "completed") {
      const emailRateLimited = claim.invite_email_rate_limited === true;
      const authUserId = claim.provisioning_auth_user_id as string | null;
      if (!authUserId) {
        return jsonResponse({
          error: "The completed request has no linked Auth user.",
          stage: "verify-existing-provisioning",
        }, 500);
      }

      const { data: authData, error: authLookupError } =
        await admin.auth.admin.getUserById(authUserId);
      if (authLookupError || !authData.user) {
        return jsonResponse({
          error: `Unable to verify the provisioned Auth user: ${authLookupError?.message ?? "The user was not found."}`,
          stage: "verify-existing-provisioning",
          ...errorFields(authLookupError),
        }, 500);
      }

      const { data: profile, error: profileError } = await admin
        .from("profiles")
        .select("id,auth_user_id,employee_id,email,role")
        .eq("auth_user_id", authUserId)
        .maybeSingle();
      if (profileError) {
        return jsonResponse({
          error: `Unable to verify the provisioned profile: ${profileError.message}`,
          stage: "verify-existing-provisioning",
          ...errorFields(profileError),
        }, 500);
      }
      if (
        !profile ||
        profile.employee_id !== claim.employee_id ||
        profile.email?.toLowerCase() !== String(claim.email).toLowerCase() ||
        profile.role !== claim.requested_role
      ) {
        return jsonResponse({
          error: "The request was marked provisioned, but its Auth user and profile do not match.",
          stage: "verify-existing-provisioning",
        }, 500);
      }

      return jsonResponse({
        status,
        message: emailRateLimited
          ? "The user is provisioned in the directory, but invitation email delivery was rate-limited. After the email limit clears, use Forgot password on the sign-in page or send a password reset from Supabase Auth > Users."
          : "This request is already provisioned.",
        profile_id: profile.id,
        auth_user_id: authUserId,
        email_rate_limited: emailRateLimited,
        email_invitation_sent: false,
        account_activated_without_email:
          authData.user.user_metadata?.registration_request_flow === false &&
          Boolean(authData.user.email_confirmed_at),
      });
    }
    return jsonResponse(
      {
        error: "Provisioning is already in progress. Try again shortly.",
        stage: "claim-provisioning",
      },
      409,
    );
  }

  let stage = "load-approved-request";
  try {
    const email = String(claim.email).trim().toLowerCase();
    const employeeId = typeof claim.employee_id === "string"
      ? claim.employee_id.trim()
      : "";
    if (!employeeId) {
      throw new Error("The approved request has no valid Employee ID.");
    }
    let authUserId = claim.provisioning_auth_user_id as string | null;
    let invitedUser: User | null = null;
    let initialPasswordAlreadySet = false;
    let emailRateLimited = claim.invite_email_rate_limited === true ||
      isEmailRateLimitError(claim.provisioning_error);
    let emailInvitationSent = false;
    let accountActivatedWithoutEmail = false;
    let emailRateLimitStateColumnAvailable = true;
    const saveEmailRateLimitState = async (
      rateLimited: boolean,
      expectedStatus: "in_progress" | "invited",
    ) => {
      if (!emailRateLimitStateColumnAvailable) return;

      const { data: savedState, error: saveError } = await admin
        .from("registration_requests")
        .update({ invite_email_rate_limited: rateLimited })
        .eq("id", requestId)
        .eq("provisioning_status", expectedStatus)
        .select("id")
        .maybeSingle();
      if (saveError) {
        if (isMissingEmailRateLimitColumnError(saveError)) {
          emailRateLimitStateColumnAvailable = false;
          console.warn(
            "The invite_email_rate_limited migration is not available in the PostgREST schema cache; continuing provisioning without saved email state.",
          );
          return;
        }
        throw saveError;
      }
      if (!savedState) {
        throw new Error("The invitation email state could not be saved.");
      }
    };

    if (authUserId) {
      stage = "verify-existing-auth-user";
      const { data, error } = await admin.auth.admin.getUserById(authUserId);
      if (error || !data.user || data.user.email?.toLowerCase() !== email) {
        throw new Error("The previously invited Auth user could not be verified.");
      }
      invitedUser = data.user;
      initialPasswordAlreadySet =
        invitedUser.user_metadata?.initial_password_from_employee_id === true;
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
          initialPasswordAlreadySet =
            invitedUser.user_metadata?.initial_password_from_employee_id === true;
          break;
        }
        if (data.users.length < 1000) break;
      }

      if (!invitedUser) {
        stage = "send-auth-invitation";
        const { data, error } = await admin.auth.admin.inviteUserByEmail(email, {
          data: {
            registration_request_id: requestId,
            initial_password_from_employee_id: false,
          },
          redirectTo: inviteRedirectUrl,
        });
        if (error) {
          if (!isEmailRateLimitError(error)) throw error;
          emailRateLimited = true;

          stage = "save-email-rate-limit-state";
          await saveEmailRateLimitState(true, "in_progress");

          stage = "recover-auth-user-after-email-rate-limit";
          for (let page = 1; ; page += 1) {
            const { data: users, error: listError } = await admin.auth.admin
              .listUsers({ page, perPage: 1000 });
            if (listError) throw listError;
            const existing = users.users.find(
              (candidate) => candidate.email?.toLowerCase() === email,
            );
            if (existing) {
              if (existing.user_metadata?.registration_request_id !== requestId) {
                throw new Error(
                  "An Auth account already exists for this email and cannot be linked automatically.",
                );
              }
              invitedUser = existing;
              initialPasswordAlreadySet =
                invitedUser.user_metadata?.initial_password_from_employee_id === true;
              break;
            }
            if (users.users.length < 1000) break;
          }

          if (!invitedUser) {
            stage = "create-auth-user-after-email-rate-limit";
            const { data: createdUser, error: createError } =
              await admin.auth.admin.createUser({
                email,
                password: employeeId,
                email_confirm: false,
                user_metadata: {
                  registration_request_id: requestId,
                  initial_password_from_employee_id: true,
                },
              });
            if (createError) {
              throw isPasswordPolicyError(createError)
                ? employeeIdPasswordFailure(createError)
                : createError;
            }
            invitedUser = createdUser.user;
            initialPasswordAlreadySet = true;
          }
        } else {
          invitedUser = data.user;
          emailInvitationSent = true;
        }
      }
      authUserId = invitedUser?.id ?? null;
    }

    if (!authUserId) throw new Error("Supabase did not return an invited user.");

    if (!initialPasswordAlreadySet) {
      stage = "set-initial-employee-id-password";
      const { data: updatedUser, error: initialPasswordError } =
        await admin.auth.admin.updateUserById(authUserId, {
          password: employeeId,
          user_metadata: {
            ...invitedUser?.user_metadata,
            initial_password_from_employee_id: true,
          },
        });
      if (initialPasswordError) {
        throw employeeIdPasswordFailure(initialPasswordError);
      }
      if (!updatedUser.user) {
        throw new Error(
          "Supabase did not return the Auth user after setting the initial password.",
        );
      }
      invitedUser = updatedUser.user;
    }

    stage = "link-auth-user-to-request";
    const { error: linkError } = await admin
      .from("registration_requests")
      .update({ provisioning_auth_user_id: authUserId })
      .eq("id", requestId)
      .eq("provisioning_status", "in_progress");
    if (linkError) throw linkError;

    stage = "create-profile-and-mark-invited";
    const { data: profileCreation, error: profileCreationError } = await admin.rpc(
      "create_registration_profile",
      { p_request_id: requestId, p_auth_user_id: authUserId },
    );
    if (profileCreationError) throw profileCreationError;
    if (
      !profileCreation ||
      typeof profileCreation !== "object" ||
      profileCreation.auth_user_id !== authUserId ||
      profileCreation.provisioning_status !== "invited" ||
      typeof profileCreation.profile_id !== "string"
    ) {
      throw new Error("The profile creation RPC did not confirm a created profile.");
    }

    stage = "verify-provisioned-profile";
    const { data: profile, error: verificationError } = await admin
      .from("profiles")
      .select("id,auth_user_id,employee_id,email,role")
      .eq("id", profileCreation.profile_id)
      .eq("auth_user_id", authUserId)
      .maybeSingle();
    if (verificationError) throw verificationError;
    if (
      !profile ||
      profile.employee_id !== claim.employee_id ||
      profile.email?.toLowerCase() !== email ||
      profile.role !== claim.requested_role
    ) {
      throw new Error("The created profile could not be verified against the approved request.");
    }

    if (invitedUser?.user_metadata?.registration_request_flow === true) {
      stage = "activate-registration-request-account";
      const { data: activatedUser, error: activationError } =
        await admin.auth.admin.updateUserById(authUserId, {
          email_confirm: true,
          ban_duration: "none",
          user_metadata: {
            ...invitedUser.user_metadata,
            registration_request_flow: false,
          },
        });
      if (activationError) throw activationError;
      if (!activatedUser.user?.email_confirmed_at) {
        throw new Error("The approved registration account could not be activated.");
      }
      accountActivatedWithoutEmail = true;
    }

    stage = "save-invitation-email-state";
    await saveEmailRateLimitState(emailRateLimited, "invited");

    return jsonResponse({
      status: "invited",
      message: accountActivatedWithoutEmail
        ? "The registration request was approved. The user's initial password is their Employee ID; they should change it after signing in. No invitation email is required."
        : emailRateLimited
        ? "The user is provisioned in the directory, but invitation email delivery was rate-limited. The initial password is the Employee ID. After the email limit clears, use Forgot password on the sign-in page or send a password reset from Supabase Auth > Users."
        : emailInvitationSent
        ? "The account was provisioned and an invitation email was sent. The initial password is the Employee ID; the user can replace it from the invitation link or after signing in."
        : "The user is provisioned in the directory.",
      profile_id: profile.id,
      auth_user_id: authUserId,
      email_rate_limited: emailRateLimited,
      email_invitation_sent: emailInvitationSent,
      account_activated_without_email: accountActivatedWithoutEmail,
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
      .in("provisioning_status", ["in_progress", "invited"]);
    if (failureStateError) {
      return jsonResponse({
        error: `${stage}: ${message}. The failure status also could not be saved: ${failureStateError.message}`,
        stage,
        ...errorFields(error),
        failure_state_error: failureStateError.message,
      }, 500);
    }
    return jsonResponse({
      error: `${stage}: ${message}`,
      stage,
      ...errorFields(error),
    }, 500);
  }
});
