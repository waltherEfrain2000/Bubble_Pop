import 'dart:math';
import 'package:flutter/material.dart';
import '../models/bubble.dart';

class BubbleWidget extends StatefulWidget {
  final Bubble bubble;
  final VoidCallback onPop;
  final VoidCallback onRemoveWithoutSound;

  const BubbleWidget({
    required Key key,
    required this.bubble,
    required this.onPop,
    required this.onRemoveWithoutSound,
  }) : super(key: key);

  @override
  State<BubbleWidget> createState() => _BubbleWidgetState();
}

class _BubbleWidgetState extends State<BubbleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _popped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.bubble.speed),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_popped) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onRemoveWithoutSound();
            }
          });
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void pop() {
    if (!_popped) {
      setState(() => _popped = true);
      Future.delayed(const Duration(milliseconds: 180), () => widget.onPop());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (ctx, child) {
        double bottom = _animation.value * MediaQuery.of(context).size.height;
        double oscillation = sin(_animation.value * pi * 2) * 22;
        double left = widget.bubble.position.dx + oscillation;

        return Positioned(
          left: left,
          bottom: bottom,
          child: GestureDetector(
            onTap: pop,
            child: _popped
                ? AnimatedOpacity(
                    opacity: 0,
                    duration: const Duration(milliseconds: 180),
                    child: Image.asset(widget.bubble.image, width: widget.bubble.size),
                  )
                : Image.asset(widget.bubble.image, width: widget.bubble.size),
          ),
        );
      },
    );
  }
}