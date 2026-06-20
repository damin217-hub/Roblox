# Release Manifest

Release candidate generated from Git commit:

`6d7e491`

## Place builds

| Experience | File | SHA-256 |
|---|---|---|
| All Ages | `build/ArtAcademy-AllAges.rbxlx` | `B7C06C2E515512236535DD23574B0438F5C87C54A90BDE79096AC618DD81D1BA` |
| Free Draw 16+ | `build/ArtAcademy-FreeDraw16Plus.rbxlx` | `3FB45A2900C422ED2E1876EB8F29CD8CDDE085DAAD3671C6AA184936A447AC84` |

The release ZIP is intentionally not regenerated yet. Package generation remains gated on interactive Studio, mobile and multiplayer QA.

## Verification

- Selene: 0 errors, 0 warnings, 0 parse errors
- Rojo: both place builds succeeded
- Studio RunScript smoke test: 70 checks passed for each place
- Studio server bootstrap integration: 28 checks passed for each place
- Full five-round match lifecycle: 24 checks passed for each place
- Mid-match artist departure recovery: 15 checks passed for each place
- Runtime module loading errors: 0

## Configuration required before publishing

- Primary moderator `rangs0524` is configured in `Config.ADMIN_USER_IDS`.
- Create optional cosmetic Game Pass/Developer Products and enter IDs in `Config.MONETIZATION`.
- Complete the content maturity questionnaire separately for each Experience.
- Keep both Experiences private until DataStore and multiplayer QA are complete.
