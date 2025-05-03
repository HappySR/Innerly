import 'package:Innerly/home/pages/therapists_list_view.dart';
import 'package:Innerly/localization/i10n.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../started/get_started_view.dart';
import '../../widget/innerly_theme.dart';
import 'chatbot/lively.dart';
import 'global_chat_view.dart';
import 'mind_games_view.dart';

class MentalHealthHome extends StatefulWidget {
  final VoidCallback onProfileTap;

  const MentalHealthHome({super.key, required this.onProfileTap});

  @override
  State<MentalHealthHome> createState() => _MentalHealthHomeState();
}

class _MentalHealthHomeState extends State<MentalHealthHome> with TickerProviderStateMixin {
  bool _isInitializing = true;
  bool _showBigEmoji = false;

  late AnimationController _emojiAnimationController;
  late Animation<double> _scaleAnimation;

  String? _selectedEmoji;
  int _userPoints = 0;

  final Map<String, int> emojiPoints = {
    "😄": 10,
    "😊": 5,
    "😐": 2,
    "😢": 1,
    "😡": -2,
  };

  @override
  void initState() {
    super.initState();
    _emojiAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
      parent: _emojiAnimationController,
      curve: Curves.easeOutBack,
    ));


    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingFlow()),
      );
    } else {
      setState(() => _isInitializing = false);
    }
  }

  @override
  void dispose() {
    _emojiAnimationController.dispose();
    super.dispose();
  }

  void _onEmojiTapped(String emoji) {
    setState(() {
      _selectedEmoji = emoji;
      _showBigEmoji = true;
      _userPoints += emojiPoints[emoji] ?? 0;
    });

    _emojiAnimationController.forward(from: 0.0);

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showBigEmoji = false;
        });
        _emojiAnimationController.reset();  // <-- Important reset
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'You earned ${emojiPoints[emoji]} points!',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget moodEmoji(String emoji) {
    return GestureDetector(
      onTap: () => _onEmojiTapped(emoji),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = Supabase.instance.client.auth.currentUser!;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF4E7),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${L10n.getTranslatedText(context, 'Hello')} Kate",
                            style: GoogleFonts.lora(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            L10n.getTranslatedText(context, 'How are you feeling today?'),
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: widget.onProfileTap,
                        child:  CircleAvatar(
                        radius: 24,
                        backgroundImage: AssetImage('assets/user/user.png'),
                      ),
                      )],
                  ),
                  const SizedBox(height: 20),

                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "${L10n.getTranslatedText(context, 'Search for session, journals')}...",
                        hintStyle: TextStyle(color: Colors.grey),
                        icon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Daily Mood Log
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                              L10n.getTranslatedText(context,'Daily mood log'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            L10n.getTranslatedText(context,'Identify and track your emotions'),
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),

                          // Mood Emojis
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: InnerlyTheme.beige,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                moodEmoji("😊"),
                                moodEmoji("😄"),
                                moodEmoji("😐"),
                                moodEmoji("😢"),
                                moodEmoji("😡"),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Relaxing Activities Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: InnerlyTheme.pink,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        L10n.getTranslatedText(context,'Relaxing Activities'),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "${L10n.getTranslatedText(context,'Wanna know how heaven feels like? Explore more')}...",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0XFF000000),
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const GamesPage(),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: InnerlyTheme.secondary,
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            L10n.getTranslatedText(context,'Explore More'),
                                            style: TextStyle(
                                              color: InnerlyTheme.secondary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  height: 150,
                                  width: 150,
                                  child: Image.asset('assets/images/explore.png'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Connect with Experts
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: InnerlyTheme.pink,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        L10n.getTranslatedText(context,'Connect with our Experts'),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        L10n.getTranslatedText(context,'Let’s see the progress of your journey'),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0XFF000000),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const TherapistsListScreen(),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: InnerlyTheme.secondary,
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            L10n.getTranslatedText(context,'Start Session'),
                                            style: TextStyle(
                                              color: InnerlyTheme.secondary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  height: 150,
                                  width: 150,
                                  child: Image.asset('assets/images/img.png'),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20,),
                          Text(
                            L10n.getTranslatedText(context,'Daily challenge'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // const SizedBox(height: ),
                          Text(
                            L10n.getTranslatedText(context,'Build your confidence and resilience'),
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: InnerlyTheme.beige, // inner box color
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 150,
                                  height: 150,
                                  child: Image.asset(
                                    'assets/images/challenge.png', // replace with your image path
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        L10n.getTranslatedText(context,'Want to build up your confidence?'),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        L10n.getTranslatedText(context,'Make better yourself'),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      OutlinedButton(
                                        onPressed: () {},
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: InnerlyTheme.secondary,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          L10n.getTranslatedText(context,'Start challenge'),
                                          style: TextStyle(
                                            color: InnerlyTheme.secondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Big emoji animation overlay
          if (_showBigEmoji && _selectedEmoji != null)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Text(
                    _selectedEmoji!,
                    style: const TextStyle(fontSize: 100),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 4,
            right: 5,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Lively(),
                  ),
                );
              },
              child: Container(
                // decoration: BoxDecoration(
                //   color: Colors.white,
                //   shape: BoxShape.circle,
                //   boxShadow: [
                //     BoxShadow(
                //       color: Colors.black12,
                //       blurRadius: 4,
                //       offset: Offset(2, 2),
                //     ),
                //   ],
                // ),
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  'assets/chat/leaf.png',
                  width: 50,
                  height: 50,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


