import 'package:Innerly/started/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:Innerly/widget/innerly_theme.dart';
import '../home/pages/bottom_nav.dart';
import '../widget/circular_progress.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final onboardingData = [
    {
      "title": "We are changing system around mental health",
      "description":
      "Even the most serious mental health conditions can be treated, allowing people to better contribute.",
      "imagePath": "assets/images/meditate.png",
    },
    {
      "title": "Together, we’re building a future that puts care first.",
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

  void _onNextTap() {
    if (_currentPage == onboardingData.length - 1) {
      _navigateToHome();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        color: InnerlyTheme.appBackground,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: onboardingData.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) => _buildPageContent(size, onboardingData[index]),
            ),
            _buildBottomButton(size),
          ],
        ),
      ),
    );
  }


  Widget _buildPageContent(Size size, Map<String, String> data) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: size.height * 0.15),
          Image.asset(
            data['imagePath']!,
            width: size.width * 0.8,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          _buildDots(),
          const SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
            child: Text(
              data['title']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.width * 0.07,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: InnerlyTheme.lightGreen,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
            child: Text(
              data['description']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.width * 0.0355,
                fontFamily: 'Poppins',
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
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
            color: _currentPage == index ? InnerlyTheme.secondary : Colors.grey[300],
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
        child: CustomPaint(
          painter: CircularProgress(
            currentPage: _currentPage,
            totalPages: onboardingData.length,
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
              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
