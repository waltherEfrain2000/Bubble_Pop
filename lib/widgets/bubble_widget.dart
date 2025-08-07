import 'dart:math';
import 'package:flutter/material.dart';
import '../models/bubble.dart';

class BubbleWidget extends StatefulWidget {
  final Bubble bubble;
  final VoidCallback onPop;
  final VoidCallback onRemoveWithoutSound;
  final bool isPaused; // Nueva propiedad para controlar la pausa

  const BubbleWidget({
    required Key key,
    required this.bubble,
    required this.onPop,
    required this.onRemoveWithoutSound,
    this.isPaused = false, // Por defecto no pausado
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
        if (status == AnimationStatus.completed && !_popped && !widget.isPaused) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !widget.isPaused) {
              widget.onRemoveWithoutSound();
            }
          });
        }
      });
    _controller.forward();
  }

  @override
  void didUpdateWidget(BubbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pausar o reanudar la animación basado en el estado del juego
    if (widget.isPaused && !oldWidget.isPaused) {
      _controller.stop();
    } else if (!widget.isPaused && oldWidget.isPaused) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void pop() {
    if (!_popped && !widget.isPaused) { // No permitir pop si está pausado
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                _popped
                    ? AnimatedOpacity(
                        opacity: 0,
                        duration: const Duration(milliseconds: 180),
                        child: _buildBubbleImage(),
                      )
                    : _buildBubbleImage(),
                // Mostrar indicador de vida especial
                if (widget.bubble.isSpecial && widget.bubble.specialType == 'life' && !_popped)
                  Positioned(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBubbleImage() {
    if (widget.bubble.isSpecial && widget.bubble.specialType == 'life') {
      // Burbuja especial con efecto dorado
      return Container(
        width: widget.bubble.size,
        height: widget.bubble.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.bubble.size / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.6),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Image.asset(
          widget.bubble.image, 
          width: widget.bubble.size,
          color: Colors.amber.withOpacity(0.7),
          colorBlendMode: BlendMode.overlay,
        ),
      );
    }
    return Image.asset(widget.bubble.image, width: widget.bubble.size);
  }
}