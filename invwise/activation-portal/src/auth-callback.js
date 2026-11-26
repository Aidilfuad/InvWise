function getParameters(url) {
  const query = url.searchParams;
  const fragment = new URLSearchParams(url.hash.slice(1));
  const get = (name) => query.get(name) ?? fragment.get(name);
  return get;
}

export async function establishAuthCallbackSession(auth, url) {
  const get = getParameters(url);
  const type = get("type");
  const hasCallback = [
    "access_token",
    "refresh_token",
    "code",
    "token_hash",
    "type",
    "error",
    "error_code",
    "error_description",
  ].some((name) => get(name));
  const error = get("error_description") ?? get("error_code") ?? get("error");
  if (error) throw new Error(error);

  let session = null;
  const code = get("code");
  const tokenHash = get("token_hash");
  const accessToken = get("access_token");
  const refreshToken = get("refresh_token");
  if (
    (type === "invite" || type === "recovery") &&
    !code &&
    !tokenHash &&
    !(accessToken && refreshToken)
  ) {
    throw new Error(
      "This authentication link is incomplete. Request a new invite or password reset and try again.",
    );
  }

  if (code) {
    const { data, error: exchangeError } = await auth.exchangeCodeForSession(code);
    if (exchangeError) throw exchangeError;
    session = data.session;
  } else if (tokenHash) {
    if (type !== "invite" && type !== "recovery") {
      throw new Error("This authentication link has an unsupported link type.");
    }
    const { data, error: verifyError } = await auth.verifyOtp({
      token_hash: tokenHash,
      type,
    });
    if (verifyError) throw verifyError;
    session = data.session;
  } else if (accessToken && refreshToken) {
    const { data, error: sessionError } = await auth.setSession({
      access_token: accessToken,
      refresh_token: refreshToken,
    });
    if (sessionError) throw sessionError;
    session = data.session;
  }

  if (!session) {
    const { data, error: getSessionError } = await auth.getSession();
    if (getSessionError) throw getSessionError;
    session = data.session;
  }

  return { hasCallback, session, type };
}
