import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RelaxPage extends StatefulWidget {
  const RelaxPage({super.key});

  @override
  State<RelaxPage> createState() => _RelaxPageState();
}

class _RelaxPageState extends State<RelaxPage> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _exercises = [
    {
      'title': 'Neck Relaxation',
      'duration': 30,
      'instructions': 'Slowly tilt your head side to side\nHold each stretch for 5 seconds'
    },
    {
      'title': 'Shoulder Release',
      'duration': 45,
      'instructions': 'Roll shoulders forward and backward\nKeep breathing steadily'
    },
    {
      'title': 'Hand Stretch',
      'duration': 20,
      'instructions': 'Extend fingers fully then make fists\nRepeat 5 times'
    },
    {
      'title': 'Back Stretch',
      'duration': 60,
      'instructions': 'Arch and round your back slowly\nMaintain smooth breathing'
    },
  ];

  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentStep = 0;
  bool _isExerciseActive = false;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() => setState(() {}));
  }

  void _startExerciseTimer() {
    _remainingSeconds = _exercises[_currentStep]['duration'];
    _isExerciseActive = true;
    _controller.repeat(reverse: true);

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_remainingSeconds > 0 && _isExerciseActive) {
        setState(() => _remainingSeconds--);
        return true;
      }
      return false;
    });
  }

  void _stopExercise() {
    setState(() {
      _isExerciseActive = false;
      _remainingSeconds = 0;
    });
    _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Muscle Relaxation', style: GoogleFonts.aboreto()),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / _exercises.length,
            backgroundColor: Colors.grey[200],
            color: const Color(0xFF6C9A8B),
          ),
          Expanded(
            child: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: PageController(initialPage: _currentStep),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: _exercises.map((exercise) => Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      exercise['title'],
                      style: GoogleFonts.amita(
                          fontSize: 28,
                          fontWeight: FontWeight.w600
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C9A8B).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        CustomPaint(
                          painter: _CirclePainter(_animation.value),
                          child: Container(
                            width: 150,
                            height: 150,
                            alignment: Alignment.center,
                            child: Text(
                              '$_remainingSeconds',
                              style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6C9A8B)
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text(
                      exercise['instructions'],
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      icon: Icon(_isExerciseActive ? Icons.pause : Icons.play_arrow),
                      label: Text(_isExerciseActive ? 'PAUSE' : 'START'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C9A8B),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                      ),
                      onPressed: () {
                        if (_isExerciseActive) {
                          _stopExercise();
                        } else {
                          _startExerciseTimer();
                        }
                      },
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentStep > 0 ? () {
                    setState(() => _currentStep--);
                    _stopExercise();
                  } : null,
                ),
                Text(
                  'Step ${_currentStep + 1} of ${_exercises.length}',
                  style: GoogleFonts.amita(fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentStep < _exercises.length - 1 ? () {
                    setState(() => _currentStep++);
                    _stopExercise();
                  } : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;

  _CirclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6C9A8B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.5 * 3.1416,
      2 * 3.1416 * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}