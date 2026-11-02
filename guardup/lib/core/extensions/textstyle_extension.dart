import 'package:flutter/material.dart';

extension TextStyleExtension on TextStyle {
  //weight
  TextStyle bold() => copyWith(fontWeight: FontWeight.w700);
  TextStyle semiBold() => copyWith(fontWeight: FontWeight.w600);
  TextStyle medium() => copyWith(fontWeight: FontWeight.w500);
  TextStyle regular() => copyWith(fontWeight: FontWeight.w400);
  TextStyle weight(FontWeight w) => copyWith(fontWeight: w);

  //size
  TextStyle increaseSize(int value) =>
      copyWith(fontSize: (fontSize ?? 12) + value);
  TextStyle decreaseSize(int value) =>
      copyWith(fontSize: (fontSize ?? 12) - value);

  //letter spacing
  TextStyle increaseLetterSpacing(int value) =>
      copyWith(letterSpacing: (letterSpacing ?? 12) + value);
  TextStyle decreaseLetterSpacing(int value) =>
      copyWith(letterSpacing: (letterSpacing ?? 12) - value);
  TextStyle textSpacing(double ls) => copyWith(letterSpacing: ls);

  //color
  TextStyle colour(Color c) => copyWith(color: c);

  //line height
  TextStyle lineHeight(double h) => copyWith(height: h);

  //font style & decoration
  TextStyle italic() => copyWith(fontStyle: FontStyle.italic);
  TextStyle underline() => copyWith(decoration: TextDecoration.underline);

  TextStyle size(double s) => copyWith(fontSize: s);
}
