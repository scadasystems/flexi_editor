# Undo/Redo 기능 추가 계획

## 목표
- 캔버스 편집 작업에 대해 Undo/Redo를 제공한다.
- 단축키(Ctrl/Cmd+Z / Ctrl/Cmd+Shift+Z 또는 Ctrl/Cmd+Y)로 동작하게 한다.
- 라이브러리에서 재사용 가능한 형태로 제공하되, 예제 앱에도 즉시 연결한다.

## 범위(본 계획에서 포함)
- 모델 변경(컴포넌트/링크): 추가/삭제, 이동, 리사이즈, 회전, 링크 생성/삭제.
- 캔버스 뷰(패닝/줌), 선택 상태, 툴 선택 등 UI 상태는 우선 범위에서 제외(요청 시 확장 가능).

## 핵심 조사 결과(현재 구조 제약)
- 모델 스냅샷 저장은 `CanvasModelReader.serializeFlexi()`로 가능하다.
- 모델 복원은 `CanvasModelWriter.deserializeFlexi(...)`로 가능하지만, 현재 구현은 **기존 모델을 지우지 않고 merge**한다.
  - Undo/Redo처럼 “교체 복원”이 목적이면 `removeAllComponents()` 후 deserialize가 필요하다.
- `CanvasModel` 자체 notify만으로는 모든 변경을 잡을 수 없다(이동/사이즈 변경은 컴포넌트/링크 개별 notify로만 반영될 수 있음).
  - 따라서 “자동 변경 감지 기반 기록”보다는 “조작 종료 시점에 명시적으로 commit”이 안전하고 단순하다.

## 설계(최소 침습 / 스냅샷 기반)
### 1) 라이브러리: Undo/Redo 컨트롤러 추가
1. 신규 클래스 `CanvasUndoRedoController`(이름은 구현 시 코드 컨벤션에 맞춰 결정)를 `lib/src/...`에 추가한다.
2. 내부에 아래 상태를 가진다.
   - `List<String> undoStack`, `List<String> redoStack`
   - `int maxDepth`(기본 50 등)
   - `bool get canUndo/canRedo`
   - (선택) `bool _isRestoring`(undo/redo 수행 중 재진입 방지)
3. Snapshot 포맷은 `serializeFlexi()` 결과 JSON 문자열을 사용한다(간단/일관/커스텀 데이터 포함 가능).
4. API
   - `commit(PolicySet policySet)` 또는 `(CanvasReader, CanvasWriter)`를 받는 형태
     - 현재 상태를 스냅샷으로 push
     - redoStack은 clear
     - maxDepth 초과 시 오래된 항목 drop
   - `undo(...)` / `redo(...)`
     - 현재 상태를 반대 스택으로 이동
     - 타겟 스냅샷을 복원
   - `clear()`(선택)
5. 복원 로직
   - `canvasWriter.model.removeAllComponents()`
   - `canvasWriter.model.deserializeFlexi(snapshotJson, decodeCustomComponentData: ..., decodeCustomLinkData: ...)`
   - 커스텀 데이터 복원이 필요한 경우를 대비해 컨트롤러 생성 시 decode 콜백을 보관하거나, undo/redo 호출 시 인자로 받는다.

### 2) 예제 앱: 기록 타이밍 연결(“조작 종료 시점 commit”)
Undo가 직관적으로 동작하려면 “조작이 끝났을 때 결과 상태를 1회 기록”이 필요하다.
1. 초기 스냅샷을 1회 commit한다.
   - 예: editor 초기화 직후 또는 첫 렌더 후.
2. 컴포넌트 이동
   - 현재 `ExamplePolicySet.onComponentScaleUpdate`에서 이동 처리 중이므로,
   - `onComponentScaleStart`/`onComponentScaleEnd`를 override(또는 추가)하여 **End에서 commit**한다.
3. 리사이즈/회전(예제는 오버레이 핸들에서 GestureDetector로 직접 처리)
   - `_ResizeHandle`/`_RotateHandle`의 드래그 제스처에 `onPanStart`/`onPanEnd`를 추가해 End에서 commit한다.
   - 이미 드래그 중 연속 업데이트는 유지하고, commit은 1회만 수행한다.
4. 컴포넌트 생성/삭제, 링크 생성/삭제
   - 해당 동작 직후 commit한다(한 번의 동작 = 한 번의 기록).

### 3) 예제 앱: 단축키 처리
1. 라이브러리의 `FlexiEditorCanvas`는 `onKeyboardEvent` 콜백 훅이 있으므로, 예제에서 이를 사용해 단축키를 구현한다.
2. 매핑
   - Undo: `Cmd+Z`(macOS) / `Ctrl+Z`(Windows/Linux)
   - Redo: `Cmd+Shift+Z` 또는 `Ctrl+Y`(관례)
3. KeyDownEvent에서만 처리하고, 처리 시 `KeyEventResult.handled` 반환하도록 구성한다(중복 실행 방지).

## 검증 계획
### 동작 검증(수동)
- 사각형/타원 생성 → 이동 → 리사이즈 → 회전 → 링크 생성/삭제 후,
  - Ctrl/Cmd+Z로 단계적으로 되돌아가는지
  - Ctrl/Cmd+Shift+Z(또는 Ctrl/Cmd+Y)로 다시 진행되는지
  - redoStack이 새 작업 commit 시 초기화되는지(undo 후 새 작업하면 redo 불가)

### 빌드 검증(자동)
- example 기준:
  - `flutter analyze`
  - `flutter build web`

## 예상 변경 파일(구현 단계에서 확정)
- 라이브러리
  - 신규: Undo/Redo 컨트롤러 파일 1개
  - (필요 시) public export 추가(`flexi_editor.dart`)
- 예제
  - `example/lib/editor/example_policy_set.dart`(move end commit, 생성/삭제/링크 후 commit)
  - `example/lib/editor/policy/resize_handle.dart`, `rotate_handle.dart`(drag end commit)
  - 예제 엔트리에서 `onKeyboardEvent` 연결(예: `main.dart` 또는 editor 화면)

