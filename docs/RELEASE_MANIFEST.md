# Release Manifest

Release candidate generated from Git commit:

`d2d3b4dd91a714fc2c18dd6f5b8de2c555c7e83e`

## Place builds

| Experience | File | SHA-256 |
|---|---|---|
| All Ages | `build/ArtAcademy-AllAges.rbxlx` | `6EFDF5AF1D5E9E863F4146ED2C79AF962C247D321F18CA75F75C4DBC14E95524` |
| Free Draw 16+ | `build/ArtAcademy-FreeDraw16Plus.rbxlx` | `EE7364EFD99262B114F8B92A856AA7FF4DC361CC254369DBB79743A21A7E4905` |

Release package:

`build/ArtAcademy-ReleaseCandidate.zip`

SHA-256: `C941207DED6572885482F63CF1EEDE198A2B83901A14F0F45148AB6F6A66E030`

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
