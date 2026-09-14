import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zane_bible_lockscreen/app.dart';

void main() {
  testWidgets('DailyFaith smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DailyFaithApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
