# Release Manifest

Release candidate generated from Git commit:

`f1c51ff19aa26b7a7b16cfb9f160126cc73e379c`

## Place builds

| Experience | File | SHA-256 |
|---|---|---|
| All Ages | `build/ArtAcademy-AllAges.rbxlx` | `9FDB58723AB20F1618CA4872B36BAD50D0DFCB52FC82A66B32B87287D0C40271` |
| Free Draw 16+ | `build/ArtAcademy-FreeDraw16Plus.rbxlx` | `827DE596D3E463E3474D31EAF89A0B39AF4BF423C1D013823A4734A81A6C3063` |

The release ZIP is intentionally not regenerated yet. Package generation remains gated on interactive Studio, mobile and multiplayer QA.

## Verification

- Selene: 0 errors, 0 warnings, 0 parse errors
- Rojo: both place builds succeeded
- Studio RunScript smoke test: 55 checks passed for each place
- Studio server bootstrap integration: 28 checks passed for each place
- Full five-round match lifecycle: 22 checks passed for each place
- Runtime module loading errors: 0

## Configuration required before publishing

- Primary moderator `rangs0524` is configured in `Config.ADMIN_USER_IDS`.
- Create optional cosmetic Game Pass/Developer Products and enter IDs in `Config.MONETIZATION`.
- Complete the content maturity questionnaire separately for each Experience.
- Keep both Experiences private until DataStore and multiplayer QA are complete.
