import 'package:flutter/material.dart';

class Bubble {
  Offset position;
  double size;
  int speed;
  Key key;
  String image;

  Bubble({
    required this.position,
    required this.size,
    required this.speed,
    required this.key,
    required this.image,
  });
}