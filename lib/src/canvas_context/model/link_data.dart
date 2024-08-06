import 'package:flexi_editor/src/utils/link_style.dart';
import 'package:flexi_editor/src/utils/vector_utils.dart';
import 'package:flutter/material.dart';

class LinkData<T> with ChangeNotifier {
  final String id;

  final String sourceComponentId;

  final String targetComponentId;

  final LinkStyle linkStyle;

  final List<Offset> linkPoints;

  bool areJointsVisible = false;

  T? data;

  LinkData({
    required this.id,
    required this.sourceComponentId,
    required this.targetComponentId,
    LinkStyle? linkStyle,
    required this.linkPoints,
    this.data,
  }) : linkStyle = linkStyle ?? LinkStyle();

  void updateLink() {
    notifyListeners();
  }

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
      var point1 = linkPoints[i] * canvasScale + canvasPosition;
      var point2 = linkPoints[i + 1] * canvasScale + canvasPosition;

      Path rect = VectorUtils.getRectAroundLine(
        point1,
        point2,
        canvasScale * (linkStyle.lineWidth + 5),
      );

      if (rect.contains(position)) {
        return i + 1;
      }
    }
    return null;
  }

  void showJoints() {
    areJointsVisible = true;
    notifyListeners();
  }

  void hideJoints() {
    areJointsVisible = false;
    notifyListeners();
  }

  LinkData.fromJson(
    Map<String, dynamic> json, {
    Function(Map<String, dynamic> json)? decodeCustomLinkData,
  })  : id = json['id'],
        sourceComponentId = json['source_component_id'],
        targetComponentId = json['target_component_id'],
        linkStyle = LinkStyle.fromJson(json['link_style']),
        linkPoints = (json['link_points'] as List).map((point) => Offset(point['x'], point['y'])).toList(),
        data = decodeCustomLinkData?.call(json['dynamic_data'] ?? {});

  Map<String, dynamic> toJson() => {
        'id': id,
        'source_component_id': sourceComponentId,
        'target_component_id': targetComponentId,
        'link_style': linkStyle,
        'link_points': linkPoints.map((point) => {'x': point.dx.round(), 'y': point.dy.round()}).toList(),
        // if (data != null) 'dynamic_data': (data as dynamic).toJson(),
      };
}
