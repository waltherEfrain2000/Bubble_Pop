import 'package:flutter/material.dart';

class Bubble {
  Offset position;
  double size;
  int speed;
  Key key;
  String image;
  bool isSpecial; // Nueva propiedad para burbujas especiales
  String specialType; // Tipo de burbuja especial

  Bubble({
    required this.position,
    required this.size,
    required this.speed,
    required this.key,
    required this.image,
    this.isSpecial = false,
    this.specialType = 'normal',
  });
}