# Release Checklist

- [ ] All Ages와 Free Draw 16+를 서로 다른 Experience로 생성
- [ ] `universe-places:write` API 키와 두 Experience의 Universe/Place ID를 환경변수로 설정
- [ ] `scripts/publish.ps1 -VersionType Saved`로 비공개 QA 버전 업로드
- [x] 열려 있는 Studio 작업을 저장·종료한 뒤 `scripts/verify.ps1 -RunStudio` 1회 실행
- [ ] 콘텐츠 성숙도 설문을 각 Experience에 맞게 제출
- [x] 아이콘 512×512, 썸네일 1920×1080 제작 및 로컬 검수
- [ ] Creator Dashboard에 아이콘과 썸네일 업로드
- [ ] API Services/DataStore 테스트 후 Studio API 접근 다시 제한
- [ ] 12인 서버 30분 플레이 테스트
- [ ] PC 및 Android/iOS 터치 테스트
- [ ] 신고, 숨김, 건너뛰기 투표, 재접속 테스트
- [x] 자동 시나리오에서 건너뛰기 중복 투표, 재접속 보상 복구, 출제자 중도 이탈 검증
- [x] ASSET_REGISTER에 없는 외부 자산 제거
- [x] `Config.ADMIN_USER_IDS`에 실제 운영자 UserId 등록
- [ ] 전체 연령판 서버 크기를 12명으로 설정
- [ ] 16+판 Free-form User Creation 및 연령 제한 정확히 설정
- [ ] 비공개 QA → 제한 공개 베타 → 전체 공개
