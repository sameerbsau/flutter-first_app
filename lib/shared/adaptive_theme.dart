import 'package:flutter/material.dart';

final _androidTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.deepOrange,
    accentColor: Colors.brown[700],
    fontFamily: 'Oswald',
    buttonColor: Colors.black);

final _iOSTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.grey,
    accentColor: Colors.blue,
    fontFamily: 'Oswald',
    buttonColor: Colors.blue);

ThemeData getAdaptiveThemeData(context) {
  return Theme.of(context).platform == TargetPlatform.android
      ? _androidTheme
      : _iOSTheme;
}
