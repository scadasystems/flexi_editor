# Tasks
- [x] Task 1: 회전 각도 계산을 상대(delta) 방식으로 변경
  - [x] 드래그 시작 시점의 포인터 각도와 기존 `rotationRadians`를 저장한다.
  - [x] 드래그 중 `rotationRadians = startRotation + (currentAngle - startAngle)`로 계산한다.
  - [x] Shift가 눌린 경우 결과 각도를 45도 단위로 스냅한다.

- [x] Task 2: 수동 검증 및 빌드 검증
  - [x] 수동 검증(웹): 작은 드래그에서도 회전이 튀지 않는지 확인한다.
  - [x] 수동 검증(웹): Shift 스냅이 점프 없이 동작하는지 확인한다.
  - [x] `flutter analyze`, `flutter build web`를 통과한다.

# Task Dependencies
- Task 2 depends on Task 1
