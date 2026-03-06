# Tasks
- [x] Task 1: 회전 핸들을 회전 오버레이 그룹에 포함
  - [x] `buildComponentOverWidget`에서 회전 핸들을 오버레이 회전 그룹(`Transform.rotate`) 내부로 이동한다.
  - [x] 회전 핸들의 배치 기준을 “도형 로컬 상단 중앙 + 고정 오프셋”으로 맞춘다.
  - [x] 기존 리사이즈 핸들/하이라이트 회전 동작은 유지한다.

- [x] Task 2: 동작/회귀 검증
  - [x] 수동 검증(웹): 회전 시 회전 핸들이 오버레이와 같이 회전하는지 확인한다.
  - [x] 수동 검증(웹): Shift 스냅(45도 단위) 및 회전 점프 방지가 유지되는지 확인한다.
  - [x] `flutter analyze`, `flutter build web`를 통과한다.

# Task Dependencies
- Task 2 depends on Task 1
