function getAuthParams(url) {
  const query = url.searchParams
  const fragment = new URLSearchParams(url.hash.slice(1))
  const get = (key) => query.get(key) ?? fragment.get(key)
  return { query, fragment, get }
}

const authParameterNames = [
  'access_token',
  'refresh_token',
  'code',
  'token_hash',
  'type',
  'error',
  'error_code',
  'error_description',
]

export function hasAuthCallbackUrl(url) {
  const { get } = getAuthParams(url)
  return authParameterNames.some((key) => get(key))
}

export async function establishAuthCallbackSession(client, url) {
  const { get } = getAuthParams(url)
  const type = get('type')
  const error = get('error_description') ?? get('error')
  const errorCode = get('error_code')
  const hasCallback = hasAuthCallbackUrl(url)

  if (error || errorCode) {
    const details = [errorCode, error].filter(Boolean).join(': ')
    throw new Error(
      /expired|invalid|used|otp/i.test(details)
        ? 'This invite or password link has expired, is invalid, or has already been used. Ask your administrator for a new invite or request another password reset.'
        : details,
    )
  }

  let session = null
  const code = get('code')
  const tokenHash = get('token_hash')
  const accessToken = get('access_token')
  const refreshToken = get('refresh_token')
  const hasSessionCredentials = Boolean(
    code || tokenHash || (accessToken && refreshToken),
  )

  if ((type === 'invite' || type === 'recovery') && !hasSessionCredentials) {
    throw new Error(
      'This authentication link is incomplete. Request a new invite or password reset and try again.',
    )
  }

  if (code) {
    const { data, error: exchangeError } = await client.auth.exchangeCodeForSession(code)
    if (exchangeError) throw exchangeError
    session = data.session
  } else if (tokenHash) {
    if (type !== 'invite' && type !== 'recovery') {
      throw new Error('This authentication link has an unsupported link type.')
    }
    const { data, error: verifyError } = await client.auth.verifyOtp({
      token_hash: tokenHash,
      type,
    })
    if (verifyError) throw verifyError
    session = data.session
  } else if (accessToken && refreshToken) {
    const { data, error: sessionError } = await client.auth.setSession({
      access_token: accessToken,
      refresh_token: refreshToken,
    })
    if (sessionError) throw sessionError
    session = data.session
  }

  if (!session) {
    const { data, error: sessionError } = await client.auth.getSession()
    if (sessionError) throw sessionError
    session = data.session
  }

  if (hasCallback && (type === 'invite' || type === 'recovery') && !session) {
    throw new Error(
      'This invite or password link is invalid or expired. Ask your administrator for a new invite or request another password reset.',
    )
  }

  return { hasCallback, session, type }
}

export function clearAuthCallbackUrl() {
  window.history.replaceState({}, document.title, window.location.pathname)
}
