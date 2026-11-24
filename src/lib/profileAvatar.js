import { supabase } from './supabase'

export const PROFILE_PHOTO_BUCKET = 'profile-photos'

export function getProfileAvatarUrl(value) {
  const avatar = String(value ?? '').trim()
  if (!avatar) return ''
  if (/^https?:\/\//i.test(avatar)) return avatar
  if (!supabase) return ''
  return supabase.storage.from(PROFILE_PHOTO_BUCKET).getPublicUrl(avatar).data.publicUrl
}

export function getOwnedProfilePhotoPath(value, authUserId) {
  const avatar = String(value ?? '').trim()
  if (!avatar || !authUserId) return ''

  let path = avatar
  if (/^https?:\/\//i.test(avatar)) {
    try {
      const segments = new URL(avatar).pathname.split('/').filter(Boolean)
      const bucketIndex = segments.indexOf(PROFILE_PHOTO_BUCKET)
      if (bucketIndex < 0) return ''
      path = segments.slice(bucketIndex + 1).join('/')
    } catch {
      return ''
    }
  }

  const escapedUserId = authUserId.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  const ownedPathPattern = new RegExp(
    `^${escapedUserId}/[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\\.(jpg|png|webp)$`,
    'i',
  )
  return ownedPathPattern.test(path) ? path : ''
}
