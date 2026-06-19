# Release Manifest

Release candidate generated from Git commit:

`57bd9401759c3a0592c676088b07c780a617d937`

## Place builds

| Experience | File | SHA-256 |
|---|---|---|
| All Ages | `build/ArtAcademy-AllAges.rbxlx` | `1D826B871F2D04CE3F995171DC3EB1ED2BB2889A132A6914ED10BEBC1B3273AE` |
| Free Draw 16+ | `build/ArtAcademy-FreeDraw16Plus.rbxlx` | `C4669A41C2365337837100620A8402449CBC125A7E2922F8F6B88C741734ED0C` |

Release package:

`build/ArtAcademy-ReleaseCandidate.zip`

SHA-256: `94C5016F14605A36AD2AFECFDCACF6421615696D2B13BC56335F7CD4C944E4A1`

## Verification

- Selene: 0 errors, 0 warnings, 0 parse errors
- Rojo: both place builds succeeded
- Studio RunScript smoke test: 52 checks passed for each place
- Runtime module loading errors: 0

## Configuration required before publishing

- Primary moderator `rangs0524` is configured in `Config.ADMIN_USER_IDS`.
- Create optional cosmetic Game Pass/Developer Products and enter IDs in `Config.MONETIZATION`.
- Complete the content maturity questionnaire separately for each Experience.
- Keep both Experiences private until DataStore and multiplayer QA are complete.
