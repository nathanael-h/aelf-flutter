import 'package:flutter/material.dart';

Color getLiturgicalColor(String? colorName) {
  if (colorName == null) return Colors.grey;
  switch (colorName.toLowerCase()) {
    case 'white':
      return Colors.white;
    case 'red':
      return Colors.red.shade700;
    case 'green':
      return Colors.green.shade700;
    case 'violet':
      return Colors.purple.shade700;
    case 'rose':
    case 'pink':
      return Colors.pink.shade300;
    case 'gold':
    case 'yellow':
      return Colors.amber.shade700;
    default:
      return Colors.grey;
  }
}
