import assert from 'node:assert/strict'
import test from 'node:test'
import { establishAuthCallbackSession } from './authCallback.js'

test('establishes a session from hash access and refresh tokens', async () => {
  const session = { user: { id: 'invite-user' } }
  const calls = []
  const client = {
    auth: {
      async setSession(tokens) {
        calls.push(tokens)
        return { data: { session }, error: null }
      },
    },
  }

  const result = await establishAuthCallbackSession(
    client,
    new URL('https://app.example/#access_token=access&refresh_token=refresh&type=invite'),
  )

  assert.equal(result.session, session)
  assert.equal(result.type, 'invite')
  assert.deepEqual(calls, [{ access_token: 'access', refresh_token: 'refresh' }])
})

test('exchanges PKCE code query parameters', async () => {
  const session = { user: { id: 'recovery-user' } }
  const calls = []
  const client = {
    auth: {
      async exchangeCodeForSession(code) {
        calls.push(code)
        return { data: { session }, error: null }
      },
    },
  }

  const result = await establishAuthCallbackSession(
    client,
    new URL('https://app.example/?code=one-time-code&type=recovery'),
  )

  assert.equal(result.session, session)
  assert.equal(result.type, 'recovery')
  assert.deepEqual(calls, ['one-time-code'])
})

test('verifies query token hashes for invitation and recovery links', async () => {
  const calls = []
  const session = { user: { id: 'linked-user' } }
  const client = {
    auth: {
      async verifyOtp(payload) {
        calls.push(payload)
        return { data: { session }, error: null }
      },
    },
  }

  await establishAuthCallbackSession(
    client,
    new URL('https://app.example/?token_hash=invite-token&type=invite'),
  )
  await establishAuthCallbackSession(
    client,
    new URL('https://app.example/?token_hash=recovery-token&type=recovery'),
  )

  assert.deepEqual(calls, [
    { token_hash: 'invite-token', type: 'invite' },
    { token_hash: 'recovery-token', type: 'recovery' },
  ])
})

test('surfaces callback errors before attempting session restoration', async () => {
  let restored = false
  const client = {
    auth: {
      async getSession() {
        restored = true
        return { data: { session: null }, error: null }
      },
    },
  }

  await assert.rejects(
    establishAuthCallbackSession(
      client,
      new URL('https://app.example/#error=access_denied&error_description=otp_expired'),
    ),
    /expired|already been used/i,
  )
  assert.equal(restored, false)
})

test('rejects invite types without a token or PKCE code', async () => {
  const client = {
    auth: {
      async getSession() {
        return { data: { session: null }, error: null }
      },
    },
  }

  await assert.rejects(
    establishAuthCallbackSession(
      client,
      new URL('https://app.example/?type=invite'),
    ),
    /incomplete/i,
  )
})
