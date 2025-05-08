import 'package:flutter/material.dart';

//Source : https://medium.com/@filipvk/creating-a-custom-color-swatch-in-flutter-554bcdcb27f3

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map swatch = <int?, Color>{};
  final double r = color.r, g = color.g, b = color.b;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r.round() + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g.round() + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b.round() + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.toARGB32(), swatch as Map<int, Color>);
}
