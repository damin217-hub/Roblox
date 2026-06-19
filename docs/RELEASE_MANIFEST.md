# Release Manifest

Release candidate generated from Git commit:

`1f05eba5a753515643ea3106cdc932929566a843`

## Place builds

| Experience | File | SHA-256 |
|---|---|---|
| All Ages | `build/ArtAcademy-AllAges.rbxlx` | `F51EBAD2317AE9AF350B0B7FCF8FB03FA47D40AF4B7CE66AF141432B1E2F6971` |
| Free Draw 16+ | `build/ArtAcademy-FreeDraw16Plus.rbxlx` | `D707A89A5E4FA49DA8AB87C0C877EBD579501C9333DD153E0F267B4AB0A9E39B` |

Release package:

`build/ArtAcademy-ReleaseCandidate.zip`

SHA-256: `EF1B7342003234B0237240761B9B8052E8ABF92AF31EC7ADA143B51CBCE87F97`

## Verification

- Selene: 0 errors, 0 warnings, 0 parse errors
- Rojo: both place builds succeeded
- Studio RunScript smoke test: 35 checks passed for each place
- Runtime module loading errors: 0

## Configuration required before publishing

- Add real moderator UserIds to `Config.ADMIN_USER_IDS`.
- Create optional cosmetic Game Pass/Developer Products and enter IDs in `Config.MONETIZATION`.
- Complete the content maturity questionnaire separately for each Experience.
- Keep both Experiences private until DataStore and multiplayer QA are complete.
