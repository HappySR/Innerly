import 'package:Innerly/localization/i10n.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'explore_more_games/cognitive_games_pages.dart';
import 'explore_more_games/initiate_page.dart';
import 'explore_more_games/meditation_page.dart';
import 'explore_more_games/music_page.dart';
import 'explore_more_games/relax_page.dart';
import 'explore_more_games/sleep_page.dart';
import 'home_view.dart';


class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF3E7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 25),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) =>  MentalHealthHome(onProfileTap: () {  },)),
              );
            }
          },

        ),
        centerTitle: true,
        title: Text(
          L10n.getTranslatedText(context, 'ACTIVITY'),
          style: GoogleFonts.lora(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 2.5,
          children: [
            GameCard(image: 'assets/icons/meditate.png', type: ActivityType.meditate),
            GameCard(image: 'assets/images/sleep.png', type: ActivityType.sleep),
            GameCard(image: 'assets/images/music.png', type: ActivityType.music),
            GameCard(image: 'assets/images/games.png', type: ActivityType.games),
            GameCard(image: 'assets/images/relax.png', type: ActivityType.relax),
            GameCard(image: 'assets/icons/consult.png', type: ActivityType.initiate),
          ],
        ),
      ),
    );
  }
}

class GameCard extends StatelessWidget {
  final String image;
  final ActivityType type;

  const GameCard({super.key, required this.image, required this.type});

  void _handleNavigation(BuildContext context) {
    switch (type) {
      case ActivityType.meditate:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MeditationPage()));
        break;
      case ActivityType.sleep:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SleepPage()));
        break;
      case ActivityType.music:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MusicPage()));
        break;
      case ActivityType.games:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesHub()));
        break;
      case ActivityType.relax:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RelaxPage()));
        break;
      case ActivityType.initiate:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const InitiatePage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    String label;
    switch (type) {
      case ActivityType.meditate:
        label = L10n.getTranslatedText(context, 'Meditate');
        break;
      case ActivityType.sleep:
        label = L10n.getTranslatedText(context, 'Sleep');
        break;
      case ActivityType.music:
        label = L10n.getTranslatedText(context, 'Music');
        break;
      case ActivityType.games:
        label = L10n.getTranslatedText(context, 'Games');
        break;
      case ActivityType.relax:
        label = L10n.getTranslatedText(context, 'Relax');
        break;
      case ActivityType.initiate:
        label = L10n.getTranslatedText(context, 'Initiate');
        break;
    }

    return GestureDetector(
      onTap: () => _handleNavigation(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            Image.asset(image, height: 40, width: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// Define activity types
enum ActivityType { meditate, sleep, music, games, relax, initiate }
