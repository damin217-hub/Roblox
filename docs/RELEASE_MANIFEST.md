# Release Manifest

Release candidate generated from Git commit:

`47d2f7f82df9e4bcb83af97d255b1a6386d72e4e`

## Place builds

| Experience | File | SHA-256 |
|---|---|---|
| All Ages | `build/ArtAcademy-AllAges.rbxlx` | `5A6417169C3C323223340DBF75149CDF0ABAFA1A4E234BFF21EAF1BBEABB730D` |
| Free Draw 16+ | `build/ArtAcademy-FreeDraw16Plus.rbxlx` | `D3C752167ED20F0EC24807614B4F33E50D2DAC4746BFEC9C37EEF1E4FE83E9F6` |

The release ZIP is intentionally not regenerated yet. Package generation remains gated on interactive Studio, mobile and multiplayer QA.

## Verification

- Selene: 0 errors, 0 warnings, 0 parse errors
- Rojo: both place builds succeeded
- Studio RunScript smoke test: 55 checks passed for each place
- Studio server bootstrap integration: 28 checks passed for each place
- Full five-round match lifecycle: 24 checks passed for each place
- Runtime module loading errors: 0

## Configuration required before publishing

- Primary moderator `rangs0524` is configured in `Config.ADMIN_USER_IDS`.
- Create optional cosmetic Game Pass/Developer Products and enter IDs in `Config.MONETIZATION`.
- Complete the content maturity questionnaire separately for each Experience.
- Keep both Experiences private until DataStore and multiplayer QA are complete.
