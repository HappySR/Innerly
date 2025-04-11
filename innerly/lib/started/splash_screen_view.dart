import 'package:Innerly/widget/innerly_theme.dart';
import 'package:flutter/material.dart';

import '../home/pages/bottom_nav.dart';
import '../home/pages/home_view.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  AnimatedSplashScreenState createState() => AnimatedSplashScreenState();
}

class AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity; // Animation for the fade-in effect

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // 2 seconds total
    )..forward();

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6,
            curve: Curves.easeIn), // 0.6 of 2 sec = 1.2 sec
      ),
    );

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) {
        return; // Ensure widget is still active before using context
      }
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => BottomNav(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InnerlyTheme.appBackground,
      body: Center(
        child: FadeTransition(
          // Apply FadeTransition to the logo
          opacity: _opacity,
          child: Image.asset(
            'assets/logo/app_logo.png',
            height: 190,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
