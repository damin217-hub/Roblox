# Publishing Copy

## All Ages

**Name**

Momo's Art Academy: Guess & Draw

**Korean name**

모모의 아트 아카데미: 그림 퀴즈

**Description**

Choose a prompt, create it with safe shapes and stamps, and race to guess your friends' artwork.
Complete daily missions, unlock cosmetic palettes, and react to gallery-worthy drawings.
Supports English and Korean on PC and mobile.

안전한 도형과 스탬프로 단어를 표현하고 친구들의 그림을 빠르게 맞혀보세요.
일일 미션을 완료하고 꾸미기 팔레트를 모으며 멋진 작품에 반응할 수 있습니다.
PC와 모바일, 한국어와 영어를 지원합니다.

## Free Draw 16+

**Name**

Momo's Art Academy: Free Draw 16+

**Description**

The freehand edition of Momo's multiplayer drawing-and-guessing party game.
Draw with brushes, colors, eraser and undo tools, guess quickly, earn coins, and submit
community favorites to a moderator-curated gallery. English and Korean supported.

This experience contains free-form user creation and must be published with the appropriate
content maturity and age restrictions.

## Search terms

drawing, guessing, party game, art, friends, 그림, 그림퀴즈, 드로잉, 파티게임

## Creator Dashboard settings

- Server size: 12
- Supported devices at launch: Computer, Phone, Tablet
- Console: disabled for v1
- Genre: Party / Social
- Private servers: enable for friend groups
- API Services: enable only for published QA environments that test DataStore

## Analytics events

The game records aggregate-only custom events: `queue_joined`, `queue_left`, `match_started`,
`correct_guess`, `match_completed`, `drawing_reported`, and `cosmetic_purchased`.
Review them in Creator Dashboard Analytics after the private QA build receives traffic.

## Cosmetic monetization setup

Create one cosmetic bundle Game Pass and optional coin-pack Developer Products. Enter their numeric IDs in
`Config.MONETIZATION`. The bundle grants only cosmetic items; coin packs can only accelerate cosmetic unlocks.
Keep all IDs at `0` until the products exist and have been reviewed.
