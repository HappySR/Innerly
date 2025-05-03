import 'package:flutter/material.dart';
import 'package:Innerly/started/welcome_page.dart';
import 'package:Innerly/widget/innerly_theme.dart';
import 'dart:math';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  double _progress = 0.0; // Start with 0/3 initially
  int _step = 0;
  final int _totalSteps = 3;


  final onboardingData = [
    {
      "title": "We are changing system around mental health",
      "description":
      "Even the most serious mental health conditions can be treated, allowing people to better contribute.",
      "imagePath": "assets/images/meditate.png",
    },
    {
      "title": "Together, we're building a future that puts care first.",
      "description":
      "With the right support, recovery is possible—and everyone has something valuable to offer.",
      "imagePath": "assets/images/well-being.png",
    },
    {
      "title": "No one should feel trapped by time to heal.",
      "description":
      "Healing is a personal journey, and no one should feel rushed along the way.",
      "imagePath": "assets/images/hourglass.png",
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: _progress,
    ).animate(_animationController);

    _animationController.forward();

  }

  void _onNextTap() {
    if (_step < _totalSteps) {
      _step++;

      if (_step < onboardingData.length) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }

      setState(() {
        _animateProgress(_step);
      });

      // Delay navigation until progress shows 3/3
      if (_step == _totalSteps) {
        _animationController.addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            _navigateToHome();
          }
        });
      }
    }
  }


  void _navigateToHome() {
    if (!mounted) return;
    Future.microtask(() {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => WelcomePage()),
            (route) => false,
      );
    });
  }

  void _animateProgress(int step) {
    final double newProgress = step / _totalSteps;

    _progressAnimation = Tween<double>(
      begin: _progress,
      end: newProgress,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController
      ..reset()
      ..forward();

    _progress = newProgress;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        color: InnerlyTheme.appBackground,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Column(
              children: [
                SizedBox(height: size.height * 0.2),
                SizedBox(
                  height: size.height * 0.3,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: onboardingData.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                        _animateProgress(index);
                      });
                    },
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return Image.asset(
                        onboardingData[index]['imagePath']!,
                        width: size.width * 0.8,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildDots(),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.08,
                    ),
                    child: _buildTextContent(
                      onboardingData[_currentPage],
                      size,
                    ),
                  ),
                ),
              ],
            ),
            _buildBottomButton(size),
          ],
        ),
      ),
    );
  }

  Widget _buildTextContent(Map<String, String> data, Size size) {
    return Column(
      children: [
        Text(
          data['title']!,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size.width * 0.07,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: InnerlyTheme.lightGreen,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          data['description']!,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size.width * 0.0355,
            fontFamily: 'Poppins',
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        onboardingData.length,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 30 : 8,
          height: 8,
          decoration: BoxDecoration(
            color:
            _currentPage == index
                ? InnerlyTheme.secondary
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(Size size) {
    return Padding(
      padding: EdgeInsets.only(bottom: size.height * 0.06),
      child: GestureDetector(
        onTap: _onNextTap,
        child: AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: _CircularProgressPainter(
                progress: _progressAnimation.value,
                activeColor: InnerlyTheme.secondary,
                inactiveColor: Colors.grey[300]!,
              ),
              child: Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: InnerlyTheme.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _CircularProgressPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint trackPaint =
    Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final Paint progressPaint =
    Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Draw track
    canvas.drawCircle(center, radius, trackPaint);

    // Draw progress
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}