import 'package:flutter/material.dart';
import 'package:zane_bible_lockscreen/core/models/verse_text_position.dart';

class VerseEditorState {
  double fontSize;
  TextAlign textAlign;
  Color textColor;
  String fontFamily;
  VerseTextPosition position;

  VerseEditorState({
    this.fontSize = 22,
    this.textAlign = TextAlign.center,
    this.textColor = Colors.white,
    this.fontFamily = 'Roboto', // default font family name from pubspec.yaml
    this.position = VerseTextPosition.legacy,
  });

  VerseEditorState copyWith({
    double? fontSize,
    TextAlign? textAlign,
    Color? textColor,
    String? fontFamily,
    VerseTextPosition? position,
  }) {
    return VerseEditorState(
      fontSize: fontSize ?? this.fontSize,
      textAlign: textAlign ?? this.textAlign,
      textColor: textColor ?? this.textColor,
      fontFamily: fontFamily ?? this.fontFamily,
      position: position ?? this.position,
    );
  }
}
