# Release Manifest

Release candidate generated from Git commit:

`fd56d8b7899e9b7caf14b4e9e04d2d0cee50caab`

## Place builds

| Experience | File | SHA-256 |
|---|---|---|
| All Ages | `build/ArtAcademy-AllAges.rbxlx` | `5964B245A292DB7C8F8A8E1163CC137C5B02313B743D38D49CEF636FA511633A` |
| Free Draw 16+ | `build/ArtAcademy-FreeDraw16Plus.rbxlx` | `B933717BF70D5A3E57D6AEC3BD7E449F8E829DD2295EDC389A1183A446C4B52A` |

Release package:

`build/ArtAcademy-ReleaseCandidate.zip`

SHA-256: `5670A27FCEF06AC4B0D347F5FC28A0024AD04B275E4E95CC14E1CB745F6DDF4D`

## Verification

- Selene: 0 errors, 0 warnings, 0 parse errors
- Rojo: both place builds succeeded
- Studio RunScript smoke test: 52 checks passed for each place
- Studio server bootstrap integration: 28 checks passed for each place
- Runtime module loading errors: 0

## Configuration required before publishing

- Primary moderator `rangs0524` is configured in `Config.ADMIN_USER_IDS`.
- Create optional cosmetic Game Pass/Developer Products and enter IDs in `Config.MONETIZATION`.
- Complete the content maturity questionnaire separately for each Experience.
- Keep both Experiences private until DataStore and multiplayer QA are complete.
