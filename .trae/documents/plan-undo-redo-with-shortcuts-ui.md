# Undo/Redo + 단축키 + UI 추가 계획

## 목표

* Undo/Redo 기능을 라이브러리에서 제공한다(예제/외부 앱에서 재사용 가능).

* 예제 앱에 Undo/Redo **UI 버튼**을 추가한다.

* 예제 앱에 단축키를 추가한다.

  * Undo: Ctrl(Windows/Linux) 또는 Cmd(macOS) + Z

  * Redo: Ctrl(Windows/Linux) 또는 Cmd(macOS) + Y

## 동작 범위(1차)

* Undo/Redo 대상: 컴포넌트/링크 모델 변경(추가/삭제, 이동, 리사이즈, 회전, 링크 생성/삭제).

* 제외(추가 요청 시 확장): 선택 상태, 캔버스 뷰(패닝/줌), 현재 툴 상태 등 UI 상태.

## 핵심 제약/선택

* 모델 스냅샷 저장은 `serializeFlexi()`로 가능.

* 모델 복원은 `deserializeFlexi()`로 가능하지만 **기존 맵에 merge**되므로, Undo/Redo 복원은 “교체 복원”으로 구현한다:

  * `removeAllComponents()` → `deserializeFlexi(...)`

* “모든 변경을 리스너로 자동 기록”은 이동/사이즈 변경이 CanvasModel notify를 타지 않을 수 있어 누락 위험이 큼.

  * 따라서 **조작 종료 시점에 1회 commit**하는 방식으로 구현한다(최소 침습, 성능 안정).

## 구현 단계

### 1) 라이브러리: Undo/Redo 컨트롤러 추가(스냅샷 기반)

1. 신규 클래스 `CanvasUndoRedoController` 추가.
2. 내부 상태/규칙

   * `undoStack: List<String>`, `redoStack: List<String>`

   * `maxDepth`(기본 50)

   * `canUndo/canRedo`

   * `isRestoring`(undo/redo 실행 중 재진입 방지)

   * 규칙: 새 commit 발생 시 redoStack은 항상 clear
3. API 설계

   * `commit({required CanvasReader reader})`

     * `reader.model.serializeFlexi()` 결과를 undoStack에 push

     * maxDepth 초과 시 오래된 항목 drop

   * `undo({required CanvasReader reader, required CanvasWriter writer, decodeCustomComponentData?, decodeCustomLinkData?})`

   * `redo({required CanvasReader reader, required CanvasWriter writer, decodeCustomComponentData?, decodeCustomLinkData?})`
4. 복원 알고리즘(undo/redo 공통)

   * 현재 상태를 반대 스택으로 이동(undo면 redoStack에 push, redo면 undoStack에 push)

   * `writer.model.removeAllComponents()`

   * `writer.model.deserializeFlexi(snapshot, decodeCustomComponentData: ..., decodeCustomLinkData: ...)`
5. export 추가(외부 사용 가능하게).

### 2) 예제: 컨트롤러 인스턴스 생성 및 초기 스냅샷 commit

1. 예제의 에디터 화면(= FlexiEditor를 감싸는 위젯)에서 `CanvasUndoRedoController`를 생성/보관한다.
2. 초기 상태가 Undo로 되돌릴 수 있도록 첫 프레임 이후 1회 `commit()`한다.

   * 방식: `WidgetsBinding.instance.addPostFrameCallback`에서 commit

### 3) 예제: commit 타이밍 연결(“조작 종료 시점 1회”)

1. 컴포넌트 이동

   * `onComponentScaleStart`에서 “조작 시작 전” 스냅샷을 commit(옵션)하거나,

   * `onComponentScaleEnd`에서 “조작 완료 후” 결과를 commit한다(권장: end 1회).
2. 리사이즈/회전(현재 오버레이 핸들이 GestureDetector로 직접 모델을 갱신)

   * `_ResizeHandle`, `_RotateHandle`에 `onPanEnd/onPanCancel`을 추가해서 end 시점에 commit한다.
3. 생성/삭제/링크 생성/삭제

   * 동작 직후 commit한다(한 동작 = 한 히스토리).

### 4) 예제: 단축키(Ctrl/Cmd+Z, Ctrl/Cmd+Y) 연결

1. FlexiEditor가 제공하는 `onKeyboardEvent` 훅을 사용해 단축키를 처리한다.
2. 판별 로직

   * Undo: (Ctrl 또는 Meta/Cmd) + Z, KeyDownEvent에서만 처리

   * Redo: (Ctrl 또는 Meta/Cmd) + Y, KeyDownEvent에서만 처리
3. 처리 결과

   * 실행 시 `KeyEventResult.handled` 반환(중복 실행 방지)

   * 실행 불가(canUndo/canRedo false)면 무시 또는 handled 처리(일관 UX 선택)

### 5) 예제: UI 버튼 추가

1. 에디터 상단(또는 캔버스 위 오버레이)에 Undo/Redo 버튼 2개를 추가한다.
2. 버튼 상태

   * `canUndo/canRedo`에 따라 enabled/disabled 처리
3. 버튼 동작

   * Undo 버튼: controller.undo(...)

   * Redo 버튼: controller.redo(...)

## 검증

* 수동 시나리오:

  * 사각형/타원 생성 → 이동 → 리사이즈 → 회전 → 링크 생성/삭제

  * Ctrl/Cmd+Z로 단계적으로 되돌림

  * Ctrl/Cmd+Y로 단계적으로 되돌림 취소(redo)

  * undo 후 새 작업 수행 시 redo가 초기화되는지 확인

* 자동 검증:

  * example 기준 `flutter analyze`, `flutter build web`

## 예상 변경 파일

* 라이브러리:

  * 신규: Undo/Redo 컨트롤러 파일 1개

  * 수정: `flexi_editor.dart` export

* 예제:

  * editor 화면 위젯(단축키+UI+controller 보관)

  * `ExamplePolicySet` 및 오버레이 핸들 파일(commit 타이밍 연결)

