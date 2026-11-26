import assert from "node:assert/strict";
import test from "node:test";

import { establishAuthCallbackSession } from "./auth-callback.js";

test("establishes an invite session from hash tokens", async () => {
  const session = { user: { id: "invite-user" } };
  const client = {
    async setSession(tokens) {
      assert.deepEqual(tokens, {
        access_token: "access",
        refresh_token: "refresh",
      });
      return { data: { session }, error: null };
    },
  };

  const result = await establishAuthCallbackSession(
    client,
    new URL(
      "https://activation.example/#access_token=access&refresh_token=refresh&type=invite",
    ),
  );

  assert.equal(result.session, session);
  assert.equal(result.type, "invite");
})

test("exchanges PKCE codes from query strings", async () => {
  const session = { user: { id: "recovery-user" } };
  const client = {
    async exchangeCodeForSession(code) {
      assert.equal(code, "pkce-code");
      return { data: { session }, error: null };
    },
  };

  const result = await establishAuthCallbackSession(
    client,
    new URL("https://activation.example/?code=pkce-code&type=recovery"),
  );

  assert.equal(result.session, session);
  assert.equal(result.type, "recovery");
})

test("surfaces authentication link errors", async () => {
  const client = {
    async getSession() {
      assert.fail("Should not restore a session after a callback error.");
    },
  };

  await assert.rejects(
    establishAuthCallbackSession(
      client,
      new URL("https://activation.example/?error_code=otp_expired"),
    ),
    /otp_expired/,
  );
})

test("rejects incomplete invitation callbacks", async () => {
  const client = {
    async getSession() {
      return { data: { session: null }, error: null };
    },
  };

  await assert.rejects(
    establishAuthCallbackSession(
      client,
      new URL("https://activation.example/?type=invite"),
    ),
    /incomplete/i,
  );
})
