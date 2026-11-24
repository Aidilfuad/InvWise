export function getPasswordRequirements(password) {
  return [
    { label: "At least 8 characters", valid: password.length >= 8 },
    { label: "One uppercase letter", valid: /[A-Z]/.test(password) },
    { label: "One lowercase letter", valid: /[a-z]/.test(password) },
    { label: "One number", valid: /\d/.test(password) },
  ];
}

export function validatePassword(password, confirmation) {
  const requirements = getPasswordRequirements(password);
  if (requirements.some((requirement) => !requirement.valid)) {
    return "Choose a stronger password that meets all the requirements.";
  }
  if (password !== confirmation) {
    return "Your passwords do not match.";
  }
  return null;
}
