import { useCallback, useEffect, useState } from 'react'

export const DEFAULT_WORKSPACE_NAME = 'Acme Operations'
const WORKSPACE_NAME_STORAGE_KEY = 'invwise.workspaceName'
const WORKSPACE_NAME_EVENT = 'invwise:workspace-name-changed'

export function getWorkspaceName() {
  try {
    return localStorage.getItem(WORKSPACE_NAME_STORAGE_KEY) ?? DEFAULT_WORKSPACE_NAME
  } catch {
    return DEFAULT_WORKSPACE_NAME
  }
}

export function setWorkspaceName(name) {
  const value = String(name ?? '')
  try {
    localStorage.setItem(WORKSPACE_NAME_STORAGE_KEY, value)
  } catch {
    // Keep the in-app workspace name in sync even when storage is unavailable.
  }
  window.dispatchEvent(new CustomEvent(WORKSPACE_NAME_EVENT, { detail: value }))
}

export function useWorkspaceName() {
  const [workspaceName, setWorkspaceNameState] = useState(getWorkspaceName)

  useEffect(() => {
    const handleWorkspaceNameChange = (event) => {
      setWorkspaceNameState(event.detail)
    }
    const handleStorageChange = (event) => {
      if (event.key === WORKSPACE_NAME_STORAGE_KEY) {
        setWorkspaceNameState(event.newValue ?? DEFAULT_WORKSPACE_NAME)
      }
    }

    window.addEventListener(WORKSPACE_NAME_EVENT, handleWorkspaceNameChange)
    window.addEventListener('storage', handleStorageChange)
    return () => {
      window.removeEventListener(WORKSPACE_NAME_EVENT, handleWorkspaceNameChange)
      window.removeEventListener('storage', handleStorageChange)
    }
  }, [])

  const updateWorkspaceName = useCallback((name) => {
    setWorkspaceName(name)
    setWorkspaceNameState(String(name ?? ''))
  }, [])

  return [workspaceName, updateWorkspaceName]
}
