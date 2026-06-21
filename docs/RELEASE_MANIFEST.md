# Release Manifest

전체연령 단일 빌드만 배포합니다.

| Experience | File | 상태 |
|---|---|---|
| All Ages | `build/ArtAcademy-AllAges.rbxlx` | `84A82766685EC4EC6339B58C870E0FD99D73808868020BC732DA8C7DB175128F` |

릴리스 ZIP은 실제 PC·모바일·멀티플레이 QA가 모두 통과할 때만 다시 생성합니다.

## 자동 검증

- Selene: 오류 0, 경고 0, 파싱 오류 0
- Studio 스모크: 134개 통과
- 런타임 부팅: 31개 통과
- 12인 5라운드 전체 매치: 35개 통과
- 출제자 중도 이탈 복구: 15개 통과

## 배포 전 필수 설정

- All Ages Universe ID와 Place ID
- `universe-places:write` Open Cloud API 키
- 사용자 그림 기능을 포함한 콘텐츠 성숙도 설문
- 운영자 계정과 신고·갤러리 승인 절차
- 실제 기기 및 8–12인 비공개 서버 검증
