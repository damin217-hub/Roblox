# Release Manifest

Release candidate generated from Git commit:

`604b28d9230ba3cc2f30c6d9de8b16e59815b735`

## Place builds

| Experience | File | SHA-256 |
|---|---|---|
| All Ages | `build/ArtAcademy-AllAges.rbxlx` | `08CD1E81E092425BFBFDAA0F877564E0561639D7D0EA2171335F3B0EF351CC59` |
| Free Draw 16+ | `build/ArtAcademy-FreeDraw16Plus.rbxlx` | `326E558CAB63E56D35AAA98D25F8364DCF2D948E7EDDE64DDF94DA45EB4333A6` |

Release package:

`build/ArtAcademy-ReleaseCandidate.zip`

SHA-256: `01699D0C4E845340D5E30BD304B4214157CE228CD1D5A9D8C816D2B15680EB20`

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
