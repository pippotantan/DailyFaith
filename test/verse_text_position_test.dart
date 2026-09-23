import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zane_bible_lockscreen/core/models/verse_text_position.dart';
import 'package:zane_bible_lockscreen/core/services/settings_service.dart';
import 'package:zane_bible_lockscreen/features/editor/verse_position_section.dart';

void main() {
  const canvas = Size(1080, 1920);

  group('placement', () {
    test('center anchor puts the block center on the canvas center', () {
      final rect = VerseTextLayout.placeBlock(
        canvas: canvas,
        block: const Size(200, 100),
        anchor: const Offset(0.5, 0.5),
        margin: VerseTextLayout.edgeMargin,
      );

      expect(rect.center.dx, 540);
      expect(rect.center.dy, 960);
    });

    test('top-left anchor stays inside the wallpaper', () {
      final rect = VerseTextLayout.placeBlock(
        canvas: canvas,
        block: const Size(200, 100),
        anchor: const Offset(0.1, 0.1),
        margin: VerseTextLayout.edgeMargin,
      );

      expect(rect.left, greaterThanOrEqualTo(VerseTextLayout.edgeMargin));
      expect(rect.top, greaterThanOrEqualTo(VerseTextLayout.edgeMargin));
      expect(
        rect.right,
        lessThanOrEqualTo(canvas.width - VerseTextLayout.edgeMargin),
      );
      expect(
        rect.bottom,
        lessThanOrEqualTo(canvas.height - VerseTextLayout.edgeMargin),
      );
      expect(rect.left, VerseTextLayout.edgeMargin);
    });

    test('bottom-right anchor stays inside the wallpaper', () {
      final rect = VerseTextLayout.placeBlock(
        canvas: canvas,
        block: const Size(200, 100),
        anchor: const Offset(0.9, 0.9),
        margin: VerseTextLayout.edgeMargin,
      );

      expect(rect.right, canvas.width - VerseTextLayout.edgeMargin);
      expect(
        rect.bottom,
        lessThanOrEqualTo(canvas.height - VerseTextLayout.edgeMargin),
      );
      expect(rect.left, greaterThanOrEqualTo(VerseTextLayout.edgeMargin));
      expect(rect.top, greaterThanOrEqualTo(VerseTextLayout.edgeMargin));
    });

    test('positions outside the valid range are constrained', () {
      final rect = VerseTextLayout.placeBlock(
        canvas: canvas,
        block: const Size(300, 400),
        anchor: const Offset(-2, 4),
        margin: VerseTextLayout.edgeMargin,
      );

      expect(rect.left, VerseTextLayout.edgeMargin);
      expect(rect.top, canvas.height - VerseTextLayout.edgeMargin - 400);
      expect(
        rect.right,
        lessThanOrEqualTo(canvas.width - VerseTextLayout.edgeMargin),
      );
      expect(
        rect.bottom,
        lessThanOrEqualTo(canvas.height - VerseTextLayout.edgeMargin),
      );
    });

    test('default center matches the historical content column', () {
      const blockHeight = 180.0;
      final legacy = VerseTextLayout.legacyBlockRect(
        canvas: canvas,
        blockHeight: blockHeight,
      );
      final placed = VerseTextLayout.placeBlock(
        canvas: canvas,
        block: Size(legacy.width, blockHeight),
        anchor: const Offset(0.5, 0.5),
        margin: VerseTextLayout.edgeMargin,
      );

      expect(legacy.left, VerseTextLayout.horizontalPadding);
      expect(
        legacy.width,
        canvas.width - (2 * VerseTextLayout.horizontalPadding),
      );
      expect(legacy.top, (canvas.height - blockHeight) / 2);
      expect(placed.left, closeTo(legacy.left, 0.01));
      expect(placed.top, closeTo(legacy.top, 0.01));
    });

    test('container width stays inside the wallpaper and scales', () {
      expect(VerseTextLayout.containerWidth(canvas, 0.4), closeTo(432, 0.01));
      expect(
        VerseTextLayout.containerWidth(canvas, 0.01),
        closeTo(canvas.width * VerseTextLayout.minWidthFraction, 0.01),
      );
      expect(
        VerseTextLayout.containerWidth(canvas, 5),
        canvas.width - (2 * VerseTextLayout.edgeMargin),
      );

      const fraction = 0.4;
      final small = VerseTextLayout.containerWidth(
        const Size(540, 960),
        fraction,
      );
      expect(small / 540, closeTo(fraction, 0.001));
    });

    test('the same fraction maps across wallpaper sizes', () {
      const anchor = Offset(0.5, 0.75);
      final phone = VerseTextLayout.placeBlock(
        canvas: canvas,
        block: const Size(200, 100),
        anchor: anchor,
        margin: 0,
      );
      final larger = VerseTextLayout.placeBlock(
        canvas: const Size(1440, 3200),
        block: const Size(200, 100),
        anchor: anchor,
        margin: 0,
      );

      expect(phone.center.dx / canvas.width, closeTo(0.5, 0.001));
      expect(phone.center.dy / canvas.height, closeTo(0.75, 0.001));
      expect(
        larger.center.dx / 1440,
        closeTo(phone.center.dx / canvas.width, 0.001),
      );
      expect(
        larger.center.dy / 3200,
        closeTo(phone.center.dy / canvas.height, 0.001),
      );
    });

    test(
      'alignment changes the ink inside the box and not a stored anchor',
      () {
        final box = VerseTextLayout.legacyBlockRect(
          canvas: canvas,
          blockHeight: 120,
        );
        final left = VerseTextLayout.inkLeft(
          boxLeft: box.left,
          layoutWidth: box.width,
          inkWidth: 180,
          align: TextAlign.left,
        );
        final right = VerseTextLayout.inkLeft(
          boxLeft: box.left,
          layoutWidth: box.width,
          inkWidth: 180,
          align: TextAlign.right,
        );

        expect(left, box.left);
        expect(right, greaterThan(left));
        expect(const VerseTextPosition(x: 0.35, y: 0.72).x, 0.35);
        expect(const VerseTextPosition(x: 0.35, y: 0.72).y, 0.72);
      },
    );
  });

  group('persistence', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('saves and reloads normalized coordinates', () async {
      const saved = VerseTextPosition(x: 0.35, y: 0.72);
      await SettingsService.saveVersePosition(saved);

      final loaded = await SettingsService.loadVersePosition();
      expect(loaded.isCustom, isTrue);
      expect(loaded.x, 0.35);
      expect(loaded.y, 0.72);
      expect(loaded.width, isNull);
    });

    test('saves and reloads a container width', () async {
      const saved = VerseTextPosition(x: 0.4, y: 0.6, width: 0.4);
      await SettingsService.saveVersePosition(saved);

      final loaded = await SettingsService.loadVersePosition();
      expect(loaded.x, 0.4);
      expect(loaded.y, 0.6);
      expect(loaded.width, 0.4);
    });

    test('a saved move without a width key keeps automatic width', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'verse_position_x': 0.35,
        'verse_position_y': 0.72,
      });

      final loaded = await SettingsService.loadVersePosition();
      expect(loaded.isCustom, isTrue);
      expect(loaded.width, isNull);
    });

    test('no stored position uses the historical center', () async {
      final loaded = await SettingsService.loadVersePosition();
      expect(loaded.isCustom, isFalse);
      expect(loaded.x, 0.5);
      expect(loaded.y, 0.5);
    });

    test('changing alignment does not modify the saved position', () async {
      await SettingsService.saveVersePosition(
        const VerseTextPosition(x: 0.35, y: 0.72),
      );
      final editor = await SettingsService.loadEditorState();
      expect(editor.position.x, 0.35);

      await SettingsService.saveEditorState(
        editor.copyWith(textAlign: TextAlign.left),
      );

      final position = await SettingsService.loadVersePosition();
      final reloaded = await SettingsService.loadEditorState();
      expect(position.x, 0.35);
      expect(position.y, 0.72);
      expect(reloaded.textAlign, TextAlign.left);
      expect(reloaded.position.x, 0.35);
      expect(reloaded.position.y, 0.72);
      expect(reloaded.position.width, isNull);
    });

    test('scheduled generation reads the same persisted position', () async {
      await SettingsService.saveVersePosition(
        const VerseTextPosition(x: 0.35, y: 0.72),
      );

      final editor = await SettingsService.loadEditorState();
      expect(editor.position.isCustom, isTrue);
      expect(editor.position.x, 0.35);
      expect(editor.position.y, 0.72);
    });

    test('reset clears the custom position and width', () async {
      await SettingsService.saveVersePosition(
        const VerseTextPosition(x: 0.2, y: 0.8, width: 0.4),
      );
      await SettingsService.clearVersePosition();

      final loaded = await SettingsService.loadVersePosition();
      expect(loaded.isCustom, isFalse);
      expect(loaded.width, isNull);
      expect(loaded.x, VerseTextPosition.legacy.x);
      expect(loaded.y, VerseTextPosition.legacy.y);
    });
  });

  testWidgets('dragging the verse reports a new position', (tester) async {
    VerseTextPosition? live;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VersePositionSection(
            verse: 'For God so loved the world',
            reference: 'John 3:16',
            fontSize: 22,
            textAlign: TextAlign.center,
            textColor: Colors.white,
            fontFamily: 'Roboto',
            position: VerseTextPosition.legacy,
            onPositionChanged: (next) => live = next,
            onPositionCommitted: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Verse Position'), findsOneWidget);
    expect(
      find.text('Drag the verse to move it. Drag the corner to resize.'),
      findsOneWidget,
    );
    expect(find.text('Reset position'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('verse-position-pad')),
      const Offset(-30, 40),
    );
    await tester.pump();

    expect(live, isNotNull);
    expect(live!.isCustom, isTrue);
    expect(live!.x, isNot(0.5));
    expect(live!.width, isNull);
  });

  testWidgets('dragging the corner stores a container width', (tester) async {
    VerseTextPosition? live;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VersePositionSection(
            verse: 'For God so loved the world',
            reference: 'John 3:16',
            fontSize: 22,
            textAlign: TextAlign.center,
            textColor: Colors.white,
            fontFamily: 'Roboto',
            position: VerseTextPosition.legacy,
            onPositionChanged: (next) => live = next,
            onPositionCommitted: (_) {},
          ),
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('verse-resize-handle')),
      const Offset(36, 0),
    );
    await tester.pump();

    expect(live, isNotNull);
    expect(live!.isCustom, isTrue);
    expect(live!.width, isNotNull);
    expect(live!.width!, greaterThan(VerseTextLayout.minWidthFraction));
    expect(live!.width!, lessThanOrEqualTo(1));
  });
}
