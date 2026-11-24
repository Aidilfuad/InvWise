export const THEME_STORAGE_KEY = 'invwise.theme'

export function getStoredThemeMode() {
  try {
    const value = localStorage.getItem(THEME_STORAGE_KEY)
    return value === 'light' || value === 'dark' || value === 'system' ? value : 'system'
  } catch {
    return 'system'
  }
}

export function resolveThemeMode(mode) {
  if (mode === 'dark') return 'dark'
  if (mode === 'light') return 'light'
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
}

export function applyThemeMode(mode) {
  const resolved = resolveThemeMode(mode)
  document.documentElement.classList.toggle('dark', resolved === 'dark')
  document.documentElement.dataset.theme = resolved
  document.documentElement.style.colorScheme = resolved
  return resolved
}

export function setThemeMode(mode) {
  try {
    localStorage.setItem(THEME_STORAGE_KEY, mode)
  } catch {
    // Theme application should still work when storage is unavailable.
  }
  applyThemeMode(mode)
  return mode
}

export function initializeTheme() {
  const mode = getStoredThemeMode()
  applyThemeMode(mode)

  const media = window.matchMedia('(prefers-color-scheme: dark)')
  const syncSystemTheme = () => {
    if (getStoredThemeMode() === 'system') applyThemeMode('system')
  }
  media.addEventListener?.('change', syncSystemTheme)
  return () => media.removeEventListener?.('change', syncSystemTheme)
}
