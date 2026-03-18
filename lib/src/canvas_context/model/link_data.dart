import 'package:flexi_editor/src/utils/link_style.dart';
import 'package:flexi_editor/src/utils/vector_utils.dart';
import 'package:flutter/material.dart';

/// 링크(선) 관련 상수 모음입니다.
class LinkConstants {
  /// 링크 히트테스트 허용 오차(px)입니다.
  static const double hitTestTolerance = 5.0;
}

/// 컴포넌트 간 연결(링크) 모델입니다.
///
/// 생성자 파라미터/필드 의미:
/// - [id]: 링크 고유 ID
/// - [sourceComponentId]: 출발 컴포넌트 ID
/// - [targetComponentId]: 도착 컴포넌트 ID
/// - [linkStyle]: 링크 스타일(선 굵기/색 등). 미지정 시 기본값이 사용됩니다.
/// - [linkPoints]: 링크를 구성하는 포인트 목록(최소 2개: start/end)
/// - [data]: 사용자 정의 데이터(선택)
class LinkData<T> with ChangeNotifier {
  final String id;
  final String sourceComponentId;
  final String targetComponentId;
  final LinkStyle linkStyle;
  final List<Offset> linkPoints;

  T? data;

  /// [LinkData]를 생성합니다.
  LinkData({
    /// 링크 고유 ID입니다.
    required this.id,

    /// 출발 컴포넌트 ID입니다.
    required this.sourceComponentId,

    /// 도착 컴포넌트 ID입니다.
    required this.targetComponentId,

    /// 링크 스타일(선 굵기/색 등)입니다. 미지정 시 기본값이 사용됩니다.
    LinkStyle? linkStyle,

    /// 링크를 구성하는 포인트 목록입니다(최소 2개: start/end).
    required this.linkPoints,

    /// 사용자 정의 데이터(선택)입니다.
    this.data,
  }) : linkStyle = linkStyle ?? LinkStyle();

  void refresh() => notifyListeners();

  void setStart(Offset start) {
    linkPoints[0] = start;
    notifyListeners();
  }

  void setEnd(Offset end) {
    linkPoints[linkPoints.length - 1] = end;
    notifyListeners();
  }

  void setEndpoints(Offset start, Offset end) {
    linkPoints[0] = start;
    linkPoints[linkPoints.length - 1] = end;
    notifyListeners();
  }

  List<Offset> getLinkPoints() {
    return linkPoints;
  }

  void insertMiddlePoint(Offset position, int index) {
    assert(index > 0);
    assert(index < linkPoints.length);
    linkPoints.insert(index, position);
    notifyListeners();
  }

  void setMiddlePointPosition(Offset position, int index) {
    linkPoints[index] = position;
    notifyListeners();
  }

  void moveMiddlePoint(Offset offset, int index) {
    linkPoints[index] += offset;
    notifyListeners();
  }

  void removeMiddlePoint(int index) {
    assert(linkPoints.length > 2);
    assert(index > 0);
    assert(index < linkPoints.length - 1);
    linkPoints.removeAt(index);
    notifyListeners();
  }

  void moveAllMiddlePoints(Offset position) {
    for (int i = 1; i < linkPoints.length - 1; i++) {
      linkPoints[i] += position;
    }
  }

  int? determineLinkSegmentIndex(
    Offset position,
    Offset canvasPosition,
    double canvasScale,
  ) {
    for (int i = 0; i < linkPoints.length - 1; i++) {
      final point1 = linkPoints[i] * canvasScale + canvasPosition;
      final point2 = linkPoints[i + 1] * canvasScale + canvasPosition;

      final Path rect = VectorUtils.getRectAroundLine(
        point1,
        point2,
        canvasScale * (linkStyle.lineWidth + LinkConstants.hitTestTolerance),
      );

      if (rect.contains(position)) {
        return i + 1;
      }
    }
    return null;
  }

  /// 링크 투명도를 설정합니다.
  void setOpacity(double opacity) {
    assert(opacity >= 0 && opacity <= 1);
    linkStyle.color = linkStyle.color.withValues(alpha: opacity);
    notifyListeners();
  }

  /// JSON으로부터 [LinkData]를 복원합니다.
  ///
  /// - [decodeCustomLinkData]: `dynamic_data`를 사용자 정의 타입으로 복원할 때 사용합니다.
  LinkData.fromJson(
    Map<String, dynamic> json, {
    Function(Map<String, dynamic> json)? decodeCustomLinkData,
  }) : id = json['id'],
       sourceComponentId = json['source_component_id'],
       targetComponentId = json['target_component_id'],
       linkStyle = LinkStyle.fromJson(json['link_style']),
       linkPoints = (json['link_points'] as List)
           .map((point) => Offset(point['x'], point['y']))
           .toList(),
       data = decodeCustomLinkData?.call(json['dynamic_data'] ?? {});

  Map<String, dynamic> toJson() => {
    'id': id,
    'source_component_id': sourceComponentId,
    'target_component_id': targetComponentId,
    'link_style': linkStyle,
    'link_points': linkPoints
        .map((point) => {'x': point.dx.round(), 'y': point.dy.round()})
        .toList(),
    if (data != null) 'dynamic_data': (data as dynamic)?.toJson(),
  };
}
