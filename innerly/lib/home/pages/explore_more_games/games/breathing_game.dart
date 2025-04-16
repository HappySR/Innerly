import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class BreathingGame extends FlameGame {
  @override
  Color backgroundColor() => const Color(0xFFFDF3E7); // Pastel background

  @override
  Future<void> onLoad() async {
    final center = size / 2;
    add(BreathingCircle()..position = center);
    add(
      TextComponent(
        text: 'Follow the circle\nBreathe In... Breathe Out...',
        anchor: Anchor.center,
      )
        ..position = Vector2(center.x, 100)
        ..textRenderer = TextPaint(
          style: const TextStyle(
            fontSize: 24,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
    );
  }
}

class BreathingCircle extends CircleComponent with HasGameRef<BreathingGame> {
  double _breathPhase = 0;
  bool _isInhaling = true;
  final double _breathDuration = 4.0; // 4 seconds per breath phase

  BreathingCircle() : super(
    radius: 50,
    paint: Paint()..color = const Color(0xFF6C9A8B), // Therapeutic green-blue
    anchor: Anchor.center,
  );

  @override
  void update(double dt) {
    super.update(dt);

    // Update breath phase (0-1)
    _breathPhase += dt / _breathDuration;

    // Switch between inhale/exhale
    if (_breathPhase >= 1) {
      _breathPhase = 0;
      _isInhaling = !_isInhaling;
    }

    // Animate size based on breathing phase
    final progress = _isInhaling
        ? Curves.easeInOutSine.transform(_breathPhase)
        : Curves.easeInOutSine.transform(1 - _breathPhase);

    final minSize = 80.0;
    final maxSize = 150.0;
    final currentSize = minSize + (maxSize - minSize) * progress;

    size = Vector2.all(currentSize);
    paint.color = Color.lerp(
      const Color(0xFF6C9A8B), // Calm blue-green
      const Color(0xFFDAF5FB), // Lighter blue
      progress,
    )!;
  }
}

class BreathingGameScreen extends StatelessWidget {
  const BreathingGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breathing Exercise'),
        backgroundColor: const Color(0xFFFDF3E7),
      ),
      body: GameWidget<BreathingGame>(
        game: BreathingGame(),
        overlayBuilderMap: {
          'pause': (context, game) => const PauseMenu(),
        },
      ),
    );
  }
}

class PauseMenu extends StatelessWidget {
  const PauseMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: Colors.white.withOpacity(0.8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Paused', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C9A8B),
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}