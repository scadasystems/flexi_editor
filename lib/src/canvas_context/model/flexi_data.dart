import 'package:flexi_editor/flexi_editor.dart';

/// FlexiEditor의 직렬화 단위(전체 데이터)입니다.
///
/// 생성자 파라미터/필드:
/// - [components]: 캔버스에 포함된 모든 컴포넌트 목록
/// - [links]: 컴포넌트 간 연결(링크) 목록
class FlexiData {
  final List<Component> components;
  final List<LinkData> links;

  /// [FlexiData]를 생성합니다.
  FlexiData({
    /// 캔버스에 포함된 모든 컴포넌트 목록입니다.
    required this.components,
    /// 컴포넌트 간 연결(링크) 목록입니다.
    required this.links,
  });

  /// JSON으로부터 [FlexiData]를 복원합니다.
  ///
  /// - [decodeCustomComponentData]: `Component.dynamic_data` 복원 함수(선택)
  /// - [decodeCustomLinkData]: `LinkData.dynamic_data` 복원 함수(선택)
  FlexiData.fromJson(
    Map<String, dynamic> json, {
    /// `Component.dynamic_data`를 사용자 정의 타입으로 복원하는 함수(선택)입니다.
    Function(Map<String, dynamic> json)? decodeCustomComponentData,
    /// `LinkData.dynamic_data`를 사용자 정의 타입으로 복원하는 함수(선택)입니다.
    Function(Map<String, dynamic> json)? decodeCustomLinkData,
  })  : components = (json['components'] as List).map((componentJson) {
          return Component.fromJson(
            componentJson,
            decodeCustomComponentData: decodeCustomComponentData,
          );
        }).toList(),
        links = (json['links'] as List).map((linkJson) {
          return LinkData.fromJson(
            linkJson,
            decodeCustomLinkData: decodeCustomLinkData,
          );
        }).toList();

  Map<String, dynamic> toJson() => {
        'components': components,
        'links': links,
      };
}
