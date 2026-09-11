import 'package:flutter/material.dart';
import 'package:zane_bible_lockscreen/features/verse/verse_screen.dart';

class DailyFaithApp extends StatelessWidget {
  const DailyFaithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DailyFaith',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const VerseScreen(),
    );
  }
}
