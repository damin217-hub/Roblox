# Release Manifest

Release candidate generated from Git commit:

`3b44aa4be9fb0a9704771e2b88288b0726ccf6ac`

## Place builds

| Experience | File | SHA-256 |
|---|---|---|
| All Ages | `build/ArtAcademy-AllAges.rbxlx` | `880EE9473C5BA6FE6CE68CA3FC301B81832611BBA729A27AEFA4D08B88E747CC` |
| Free Draw 16+ | `build/ArtAcademy-FreeDraw16Plus.rbxlx` | `8BADDA2DEF4B66B22C2F25172864FBCC65FE61CE0E8F4AD3FC78004ED7C4E06D` |

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
