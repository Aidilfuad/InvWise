# InvWise

## Publishing app updates

InvWise checks the latest stable release from the public GitHub Releases API for
`Aidilfuad/InvWise`. Publish a GitHub Release with a semantic version tag
(for example, `v2.0.1`) and attach the release APK. The app uses that APK asset
URL, the release body, and the published date for update prompts and release
history; no `app_versions` database row is needed.

To require an update, include a standalone line `force_update: true` in the
release body. The marker is hidden from the displayed release notes. Omitting
it (or setting it to `false`) keeps the update optional.

The legacy Supabase `app_versions` table and migrations are intentionally left
in place for compatibility with older app versions, but InvWise 2.0.0 no
longer reads from or writes to that table.
