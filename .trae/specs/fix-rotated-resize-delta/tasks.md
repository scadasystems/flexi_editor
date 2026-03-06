# Tasks
- [x] Task 1: 리사이즈 드래그 델타를 로컬 축으로 변환
  - [x] `rotationRadians`를 조회한다.
  - [x] `details.delta / scale` 값을 `-rotationRadians`로 회전시켜 로컬 델타를 만든다.
  - [x] 로컬 델타를 기존 리사이즈 계산에 적용한다.

- [x] Task 2: 동작/회귀 검증
  - [x] 수동 검증(웹): 0/30/45/90도에서 리사이즈 감도가 일관적인지 확인한다.
  - [x] 수동 검증(웹): 최소 크기 클램프가 유지되는지 확인한다.
  - [x] `flutter analyze`, `flutter build web`를 통과한다.

# Task Dependencies
- Task 2 depends on Task 1
