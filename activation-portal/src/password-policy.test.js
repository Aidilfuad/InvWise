import test from "node:test";
import assert from "node:assert/strict";

import {
  getPasswordRequirements,
  validatePassword,
} from "./password-policy.js";

test("password policy reports each requirement", () => {
  const requirements = getPasswordRequirements("GoodPass1");

  assert.equal(requirements.length, 4);
  assert.ok(requirements.every((requirement) => requirement.valid));
});

test("password validation rejects weak or mismatched passwords", () => {
  assert.match(validatePassword("weak", "weak"), /stronger password/);
  assert.match(
    validatePassword("GoodPass1", "OtherPass1"),
    /do not match/,
  );
  assert.equal(validatePassword("GoodPass1", "GoodPass1"), null);
});
