# Release Manifest

Release candidate generated from Git commit:

`237f65a3c5898a959bca65256173c2322a6054bb`

## Place builds

| Experience | File | SHA-256 |
|---|---|---|
| All Ages | `build/ArtAcademy-AllAges.rbxlx` | `05DB39338134D9F5453FC27197193287CB2320489AD2994E660958E79911E91F` |
| Free Draw 16+ | `build/ArtAcademy-FreeDraw16Plus.rbxlx` | `36E5EC5BF0F407F20875F794E4381D253439C50371E888E782B24AE21A49CFC4` |

Release package:

`build/ArtAcademy-ReleaseCandidate.zip`

SHA-256: `20BA3C40FA4FB10AAE92F4631939D1BACF3CA37FF4E2D133C5A6FC41FE9C0ACB`

## Verification

- Selene: 0 errors, 0 warnings, 0 parse errors
- Rojo: both place builds succeeded
- Studio RunScript smoke test: 48 checks passed for each place
- Runtime module loading errors: 0

## Configuration required before publishing

- Add real moderator UserIds to `Config.ADMIN_USER_IDS`.
- Create optional cosmetic Game Pass/Developer Products and enter IDs in `Config.MONETIZATION`.
- Complete the content maturity questionnaire separately for each Experience.
- Keep both Experiences private until DataStore and multiplayer QA are complete.
