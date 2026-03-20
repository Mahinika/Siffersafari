import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widgets/loke_walk_preview_widget.dart';

void main() {
  testWidgets('[Widget] Loke walk character renders svg parts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: LokeWalkPreviewWidget(height: 120),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(LokeWalkPreviewWidget), findsOneWidget);
    expect(find.byType(SvgPicture), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SvgPicture &&
            widget.bytesLoader.toString().contains('loke_arm_upper_left.svg'),
      ),
      findsOneWidget,
    );
  });
}
