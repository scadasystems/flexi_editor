# Tasks
- [x] Task 1: 코너 핸들 위치를 테두리 외곽 기준으로 보정
  - [x] 하이라이트 strokeWidth(현재 사용값)를 코너 핸들 배치에 반영한다.
  - [x] 코너 핸들을 `rect.inflate(strokeWidth/2)` 기반 코너에 배치한다.

- [x] Task 2: 동작/회귀 검증
  - [x] 수동 검증(웹): 0/30/45/90도에서 코너 포인트가 모서리에 정확히 붙는지 확인한다.
  - [x] 수동 검증(웹): 리사이즈/회전 동작이 기존과 동일하게 유지되는지 확인한다.
  - [x] `flutter analyze`, `flutter build web`를 통과한다.

# Task Dependencies
- Task 2 depends on Task 1
