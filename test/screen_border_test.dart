import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_border/screen_border.dart';

void main() {
  tearDown(ScreenCornerRadius.debugReset);

  group('ScreenBorder', () {
    testWidgets('renders border with custom color and width', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: ScreenBorder(color: Color(0xFFFF9800), width: 4.0),
        ),
      );

      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(ScreenBorder),
          matching: find.byType(DecoratedBox),
        ),
      );

      final decoration = box.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect(decoration.border!.top.color, const Color(0xFFFF9800));
      expect(decoration.border!.top.width, 4.0);
    });

    testWidgets('uses supplied explicit borderRadius', (tester) async {
      const customRadius = BorderRadius.only(
        topLeft: Radius.circular(42),
        topRight: Radius.circular(42),
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      );

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: ScreenBorder(borderRadius: customRadius),
        ),
      );

      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(ScreenBorder),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.borderRadius, customRadius);
    });

    testWidgets('follows ScreenCornerRadius dynamically', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: ScreenBorder(),
        ),
      );

      var box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(ScreenBorder),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect((box.decoration as BoxDecoration).borderRadius, BorderRadius.zero);

      const displayRadius = BorderRadius.all(Radius.circular(44));
      ScreenCornerRadius.debugSetValue(displayRadius);
      await tester.pump();

      box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(ScreenBorder),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect((box.decoration as BoxDecoration).borderRadius, displayRadius);
    });

    testWidgets('hides border when visible is false (standalone)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: ScreenBorder(visible: false),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(ScreenBorder),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );
    });

    testWidgets('wraps child and toggles overlay visibility', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: ScreenBorder(
            visible: true,
            child: Text('Preview'),
          ),
        ),
      );

      expect(find.text('Preview'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ScreenBorder),
          matching: find.byType(DecoratedBox),
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: ScreenBorder(
            visible: false,
            child: Text('Preview'),
          ),
        ),
      );

      expect(find.text('Preview'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ScreenBorder),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );
    });

    testWidgets('does not block pointer gestures on underlying widgets', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ScreenBorder(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => tapped = true,
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(50, 50));
      expect(tapped, isTrue);
    });

    testWidgets('excludes border from semantics tree', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ScreenBorder(
              child: Semantics(label: 'Camera', child: const SizedBox.expand()),
            ),
          ),
        );

        expect(find.byType(ExcludeSemantics), findsOneWidget);
        expect(find.bySemanticsLabel('Camera'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });
  });
}
