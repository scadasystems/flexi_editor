import 'package:flutter_test/flutter_test.dart';

import 'package:example/app.dart';
import 'package:flexi_editor/flexi_editor.dart';

void main() {
  testWidgets('에디터 화면이 렌더링된다', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    expect(find.byType(FlexiEditor), findsOneWidget);
  });
}
