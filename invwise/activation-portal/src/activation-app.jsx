import { useEffect, useState } from "react";

import { establishAuthCallbackSession } from "./auth-callback.js";
import { getPasswordRequirements, validatePassword } from "./password-policy.js";
import { supabase, supabaseConfigError } from "./supabase.js";

function getErrorMessage(error) {
  let message = error?.message ?? "Something went wrong. Please try again.";
  if (error?.details && typeof error.details === "object") {
    message =
      error.details.error ??
      error.details.message ??
      JSON.stringify(error.details);
  } else if (typeof error?.details === "string" && error.details.trim()) {
    try {
      const details = JSON.parse(error.details);
      message = details.error ?? details.message ?? error.details;
    } catch {
      message = error.details;
    }
  }
  if (/expired|invalid|already been used|otp/i.test(message)) {
    return "This invite or password link is invalid, expired, or has already been used. Ask your InvWise administrator for a new invite or request another password reset.";
  }
  return message;
}

function clearInvitationUrl() {
  window.history.replaceState(
    {},
    document.title,
    window.location.pathname,
  );
}

function Brand() {
  return (
    <header className="brand">
      <div className="brand-mark" aria-hidden="true">
        <span />
        <span />
        <span />
      </div>
      <span className="brand-name">InvWise</span>
      <span className="brand-divider" />
      <span className="brand-caption">ACCOUNT ACTIVATION</span>
    </header>
  );
}

function SuccessView({ isRecovery }) {
  return (
    <section className="activation-card success-card" aria-live="polite">
      <div className="success-icon" aria-hidden="true">
        <svg viewBox="0 0 24 24">
          <path d="m5 12.5 4.5 4.5L19 7" />
        </svg>
      </div>
      <p className="eyebrow">{isRecovery ? "PASSWORD UPDATED" : "YOU’RE ALL SET"}</p>
      <h1>{isRecovery ? "Your password is ready" : "Welcome to InvWise"}</h1>
      <p className="success-message">
        {isRecovery
          ? "Your password was updated successfully. You may now sign in to InvWise."
          : "Account activated successfully. You may now log in to InvWise."}
      </p>
      <div className="success-note">
        You can close this page and sign in to the InvWise app with your email
        and new password.
      </div>
    </section>
  );
}

function ActivationForm({ user, flowType, onSuccess }) {
  const [password, setPassword] = useState("");
  const [confirmation, setConfirmation] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmation, setShowConfirmation] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const requirements = getPasswordRequirements(password);

  async function handleSubmit(event) {
    event.preventDefault();
    const validationError = validatePassword(password, confirmation);
    if (validationError) {
      setErrorMessage(validationError);
      return;
    }

    const requestId = user.user_metadata?.registration_request_id;
    if (flowType === "invite" && !requestId) {
      setErrorMessage(
        "This invitation is not linked to a registration request. Contact InvWise support.",
      );
      return;
    }

    setIsSubmitting(true);
    setErrorMessage("");
    try {
      const email = user.email;
      if (!email) throw new Error("The invitation does not contain an email.");

      const { error: updateError } = await supabase.auth.updateUser({
        password,
      });
      if (updateError) throw updateError;

      if (flowType === "invite") {
        const { data: signInData, error: signInError } =
          await supabase.auth.signInWithPassword({ email, password });
        if (signInError) throw signInError;
        if (signInData.user?.id !== user.id) {
          throw new Error("Unable to verify the invited account after sign-in.");
        }

        const { data, error: completionError } = await supabase.functions.invoke(
          "complete-registration-setup",
          { body: { request_id: requestId } },
        );
        if (completionError) throw completionError;
        if (data?.status !== "completed") {
          throw new Error(
            data?.error ?? "The account activation was not confirmed.",
          );
        }
      }
      onSuccess(flowType === "recovery");
    } catch (error) {
      setErrorMessage(getErrorMessage(error));
      setIsSubmitting(false);
    }
  }

  return (
    <section className="activation-card">
      <div className="card-heading">
        <div className="heading-icon" aria-hidden="true">
          <svg viewBox="0 0 24 24">
            <rect x="4" y="10" width="16" height="11" rx="2" />
            <path d="M8 10V7a4 4 0 0 1 8 0v3m-4 5v2" />
          </svg>
        </div>
        <p className="eyebrow">SECURE ACCOUNT SETUP</p>
        <h1>{flowType === "recovery" ? "Choose a new password" : "Create your password"}</h1>
        <p className="card-description">
          {flowType === "recovery"
            ? <>Choose a new password for {user.email ? <strong>{user.email}</strong> : "your InvWise account"}.</>
            : <>Your initial password is your Employee ID. Set a new password here before entering your InvWise workspace. {user.email && <>Account: <strong>{user.email}</strong>.</>}</>}
        </p>
      </div>

      <form className="activation-form" onSubmit={handleSubmit}>
        <label htmlFor="password">New password</label>
        <div className="password-field">
          <input
            autoComplete="new-password"
            disabled={isSubmitting}
            id="password"
            onChange={(event) => setPassword(event.target.value)}
            placeholder="Create a strong password"
            required
            type={showPassword ? "text" : "password"}
            value={password}
          />
          <button
            aria-label={showPassword ? "Hide password" : "Show password"}
            className="visibility-button"
            onClick={() => setShowPassword((shown) => !shown)}
            type="button"
          >
            {showPassword ? "Hide" : "Show"}
          </button>
        </div>
        <div className="password-requirements" aria-live="polite">
          {requirements.map((requirement) => (
            <span
              className={requirement.valid ? "requirement valid" : "requirement"}
              key={requirement.label}
            >
              <span aria-hidden="true">{requirement.valid ? "✓" : "○"}</span>
              {requirement.label}
            </span>
          ))}
        </div>

        <label htmlFor="confirmation">Confirm password</label>
        <div className="password-field">
          <input
            autoComplete="new-password"
            disabled={isSubmitting}
            id="confirmation"
            onChange={(event) => setConfirmation(event.target.value)}
            placeholder="Enter your password again"
            required
            type={showConfirmation ? "text" : "password"}
            value={confirmation}
          />
          <button
            aria-label={
              showConfirmation ? "Hide confirmation" : "Show confirmation"
            }
            className="visibility-button"
            onClick={() => setShowConfirmation((shown) => !shown)}
            type="button"
          >
            {showConfirmation ? "Hide" : "Show"}
          </button>
        </div>

        {errorMessage ? (
          <div className="error-message" role="alert">
            <span aria-hidden="true">!</span>
            {errorMessage}
          </div>
        ) : null}

        <button className="submit-button" disabled={isSubmitting} type="submit">
          {isSubmitting ? (
            <>
              <span className="spinner" aria-hidden="true" />
              Activating account…
            </>
          ) : (
            <>
              {flowType === "recovery" ? "Update password" : "Activate account"}
              <span aria-hidden="true">→</span>
            </>
          )}
        </button>
      </form>

      <div className="security-note">
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path d="M12 3 4.5 6v5.5c0 4.7 3.2 7.7 7.5 9.5 4.3-1.8 7.5-4.8 7.5-9.5V6L12 3Z" />
          <path d="m9 12 2 2 4-4" />
        </svg>
        Your password is encrypted and never shared.
      </div>
    </section>
  );
}

function ActivationApp() {
  const [user, setUser] = useState(null);
  const [flowType, setFlowType] = useState("invite");
  const [isActivated, setIsActivated] = useState(false);
  const [isRecovery, setIsRecovery] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState("");

  useEffect(() => {
    if (!supabase) {
      setErrorMessage(supabaseConfigError);
      setIsLoading(false);
      return undefined;
    }

    let active = true;
    const subscription = supabase.auth.onAuthStateChange((event, session) => {
      if (!active) return;
      if (session?.user) setUser(session.user);
      if (event === "SIGNED_OUT") setUser(null);
    }).data.subscription;

    async function loadInvitation() {
      const url = new URL(window.location.href);
      try {
        const callback = await establishAuthCallbackSession(
          supabase.auth,
          url,
        );
        if (callback.hasCallback) clearInvitationUrl();
        if (!active) return;

        const session = callback.session;
        if (!session?.user) {
          throw new Error(
            "This invite or password link is invalid, expired, or has already been used. Ask your InvWise administrator for a new invite or request another password reset.",
          );
        }
        const resolvedFlowType =
          callback.type === "invite" || callback.type === "recovery"
          ? callback.type
          : session.user.user_metadata?.registration_request_id
            ? "invite"
            : null;
        if (!resolvedFlowType) {
          throw new Error(
            "This link is not an InvWise invite or password recovery link.",
          );
        }
        if (
          resolvedFlowType === "invite" &&
          !session.user.user_metadata?.registration_request_id
        ) {
          throw new Error(
            "This invitation is not linked to an InvWise registration request. Contact InvWise support.",
          );
        }
        setFlowType(resolvedFlowType);
        setUser(session.user);
      } catch (error) {
        clearInvitationUrl();
        if (active) setErrorMessage(getErrorMessage(error));
      } finally {
        if (active) setIsLoading(false);
      }
    }

    loadInvitation();
    return () => {
      active = false;
      subscription.unsubscribe();
    };
  }, []);

  return (
    <main className="page-shell">
      <div className="ambient ambient-one" aria-hidden="true" />
      <div className="ambient ambient-two" aria-hidden="true" />
      <div className="page-content">
        <Brand />
        {isLoading ? (
          <section className="activation-card loading-card" aria-live="polite">
            <span className="large-spinner" aria-hidden="true" />
            <h1>Verifying your invitation</h1>
            <p>Please wait while we securely confirm your account.</p>
          </section>
        ) : isActivated ? (
          <SuccessView isRecovery={isRecovery} />
        ) : errorMessage ? (
          <section className="activation-card error-card" role="alert">
            <div className="error-symbol" aria-hidden="true">
              !
            </div>
            <p className="eyebrow">AUTHENTICATION LINK ISSUE</p>
            <h1>We couldn’t continue</h1>
            <p className="card-description">{errorMessage}</p>
            <p className="support-hint">
              If your link has expired or was already used, request a new one
              from your InvWise administrator.
            </p>
          </section>
        ) : user ? (
          <ActivationForm
            flowType={flowType}
            user={user}
            onSuccess={(recovery) => {
              setIsRecovery(recovery);
              setIsActivated(true);
            }}
          />
        ) : null}
        <footer className="page-footer">
          <span>InvWise</span> · Secure inventory management
        </footer>
      </div>
    </main>
  );
}

export default ActivationApp;
