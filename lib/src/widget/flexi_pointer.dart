import 'package:defer_pointer/defer_pointer.dart';

/// FlexiEditor 내부에서 포인터 이벤트 처리 순서를 제어하기 위한 래퍼 위젯입니다.
///
/// `defer_pointer`의 [DeferPointer]를 그대로 노출하며, 외부 API 일관성을 위해 이름만 래핑합니다.
class FlexiPointer extends DeferPointer {
  /// [child]를 감싸 포인터 이벤트 처리 순서를 제어합니다.
  ///
  /// - [paintOnTop]: 오버레이를 상단에 그릴지 여부
  /// - [link]: 동일한 링크 그룹을 공유할 때 사용
  const FlexiPointer(
      {super.key, required super.child, super.paintOnTop, super.link});
}
