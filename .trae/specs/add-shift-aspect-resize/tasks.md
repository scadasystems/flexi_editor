# Tasks
- [x] Task 1: Shift 비율 고정 리사이즈 구현
  - [x] 드래그 시작 시점의 도형 비율(`width/height`)을 저장한다.
  - [x] 드래그 중 Shift 키가 눌려 있으면 비율을 유지하도록 리사이즈 벡터를 보정한다.
  - [x] 드래그 중 Shift 토글(OFF→ON/ON→OFF) 시 점프 없이 연속 동작하도록 기준점을 갱신한다.
  - [x] 최소 크기 클램프 및 반대 코너 고정 기준을 유지한다.

- [x] Task 2: 동작/회귀 검증
  - [x] 수동 검증(웹): Shift 리사이즈 시 비율이 유지되는지 확인한다.
  - [x] 수동 검증(웹): 회전(예: 45도) 상태에서도 동일하게 비율이 유지되는지 확인한다.
  - [x] `flutter analyze`, `flutter build web`를 통과한다.

# Task Dependencies
- Task 2 depends on Task 1
