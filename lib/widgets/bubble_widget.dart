import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
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

class _BubbleWidgetState extends State<BubbleWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Controlador para animación de destrucción
  late AnimationController _popController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;

  // AudioPlayer local para sonido más suave
  late AudioPlayer _popSoundPlayer;

  bool _popped = false;

  @override
  void initState() {
    super.initState();

    // Inicializar AudioPlayer local para sonido más suave
    _popSoundPlayer = AudioPlayer();

    // Animación principal de movimiento
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.bubble.speed),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            !_popped &&
            !widget.isPaused) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !widget.isPaused) {
              widget.onRemoveWithoutSound();
            }
          });
        }
      });

    // Animaciones de destrucción
    _popController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _popController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _popController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _popController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

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
    _popController.dispose();
    _popSoundPlayer.dispose();
    super.dispose();
  }

  void pop() async {
    if (!_popped && !widget.isPaused) {
      setState(() => _popped = true);

      // Reproducir sonido inmediatamente con volumen más suave
      await _playPopSound();

      // Iniciar animación de destrucción
      _popController.forward();

      // Llamar onPop después de la animación
      Future.delayed(const Duration(milliseconds: 300), () => widget.onPop());
    }
  }

  // Método para reproducir sonido de pop más suave
  Future<void> _playPopSound() async {
    try {
      // Volumen dinámico basado en el tamaño de la burbuja
      double volume = (widget.bubble.size / 130.0).clamp(0.3, 0.8);

      // Agregar variación de pitch simulada con diferentes volúmenes
      if (widget.bubble.isSpecial) {
        volume *= 1.2; // Burbujas especiales un poco más fuertes
      }

      await _popSoundPlayer.play(
        AssetSource('sounds/pop.mp3'),
        volume: volume,
        mode:
            PlayerMode.lowLatency, // Modo de baja latencia para mejor respuesta
      );
    } catch (e) {
      // Silenciosamente ignorar errores de audio para no interrumpir el juego
      print('Error reproduciendo sonido: $e');
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
                    ? AnimatedBuilder(
                        animation: _popController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Transform.rotate(
                              angle: _rotationAnimation.value * 2 * pi,
                              child: Opacity(
                                opacity: _fadeAnimation.value,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    _buildBubbleImage(),
                                    // Efecto de partículas
                                    ..._buildParticles(),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : _buildBubbleImage(),
                // Mostrar indicador de vida especial
                if (widget.bubble.isSpecial &&
                    widget.bubble.specialType == 'life' &&
                    !_popped)
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
                // Mostrar indicador de lentitud especial
                if (widget.bubble.isSpecial &&
                    widget.bubble.specialType == 'slow' &&
                    !_popped)
                  Positioned(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.schedule,
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
      // Burbuja especial de vida con efecto dorado
      return Container(
        width: widget.bubble.size,
        height: widget.bubble.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.bubble.size / 2),
        ),
        child: Image.asset(
          widget.bubble.image,
          width: widget.bubble.size,
          colorBlendMode: BlendMode.overlay,
        ),
      );
    } else if (widget.bubble.isSpecial && widget.bubble.specialType == 'slow') {
      // Burbuja especial de lentitud con efecto azul
      return Container(
        width: widget.bubble.size,
        height: widget.bubble.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.bubble.size / 2),
        ),
        child: Image.asset(
          widget.bubble.image,
          width: widget.bubble.size,
          color: Colors.blue.withOpacity(0.3),
          colorBlendMode: BlendMode.overlay,
        ),
      );
    }
    return Image.asset(widget.bubble.image, width: widget.bubble.size);
  }

  // Crear efecto de partículas para la destrucción
  List<Widget> _buildParticles() {
    if (!_popped) return [];

    List<Widget> particles = [];
    Random random = Random();

    for (int i = 0; i < 8; i++) {
      double angle = (i * pi * 2) / 8;
      double distance = 30 + random.nextDouble() * 20;

      particles.add(
        Positioned(
          left: cos(angle) * distance * _scaleAnimation.value,
          top: sin(angle) * distance * _scaleAnimation.value,
          child: Transform.scale(
            scale: 1.0 - _popController.value,
            child: Container(
              width: 4 + random.nextDouble() * 4,
              height: 4 + random.nextDouble() * 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.bubble.isSpecial
                    ? (widget.bubble.specialType == 'life' 
                        ? Colors.amber.withOpacity(0.8)
                        : Colors.blue.withOpacity(0.8))
                    : [
                        Colors.blue,
                        Colors.cyan,
                        Colors.lightBlue
                      ][random.nextInt(3)]
                        .withOpacity(0.7),
              ),
            ),
          ),
        ),
      );
    }

    return particles;
  }
}
