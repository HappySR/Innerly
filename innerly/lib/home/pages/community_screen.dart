import 'package:Innerly/localization/i10n.dart';
import 'package:Innerly/widget/innerly_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'global_chat_view.dart';

class CommunityScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E7),
      appBar: AppBar(
        backgroundColor: InnerlyTheme.beige,
        automaticallyImplyLeading: false,
        title: Text(
          L10n.getTranslatedText(context, 'Community'),
          style: GoogleFonts.lora(
            fontSize: 22,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: L10n.getTranslatedText(context, 'Search anything'),
                  hintStyle: GoogleFonts.rubik(fontSize: 14),
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Channel List
            SizedBox(
              height: 100, // Increased height for text + icons
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  buildChannelItem(Icons.add, L10n.getTranslatedText(context, 'Add\nChannel'), (){}),
                  buildChannelItem(Icons.public, L10n.getTranslatedText(context, 'Global\nChat'), (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GlobalChatScreen(),
                      ),
                    );
                  }),
                  buildChannelItem(
                    Icons.chat_bubble_outline,
                    L10n.getTranslatedText(context, 'Therapy\nNutshell'),(){

                  }
                  ),
                  buildChannelItem(
                    Icons.self_improvement,
                    L10n.getTranslatedText(context, 'Mindfulness\nSpace'), (){},
                  ),
                  buildChannelItem(Icons.group, L10n.getTranslatedText(context, 'Anxiety\nSupport'), (){}),
                  buildChannelItem(Icons.family_restroom, L10n.getTranslatedText(context, 'Family\nMatters'), (){}),
                  buildChannelItem(Icons.school, L10n.getTranslatedText(context, 'Student\nLife'), (){}),
                  buildChannelItem(
                    Icons.business_center,
                    L10n.getTranslatedText(context, 'Workplace\nWellness'),(){},
                  ),
                  buildChannelItem(Icons.healing, L10n.getTranslatedText(context, 'Healing\nJourney'), (){}),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Write Post
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    radius: 20,
                    child: Icon(Icons.edit, color: Colors.black),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      L10n.getTranslatedText(context, 'Write Something'),
                      style: GoogleFonts.rubik(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF719E07),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      L10n.getTranslatedText(context, 'Add Post'),
                      style: GoogleFonts.rubik(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Posts List
            Expanded(
              child: ListView(
                children: [
                  buildPost(
                    userName: "Kati Morton",
                    time: "26 Jun. 10:14 PM",
                    text:
                        L10n.getTranslatedText(context, 'You deserve a love with no trauma attached to it, a love that is good for your mental health, a love that is kind to you. I\'m talking about people NOT suffering from mental health issues'),
                    imagePath: 'assets/images/love-illustration.png',
                  ),
                  buildPost(
                    userName: "Angus MacGyver",
                    time: "26 Jun. 10:14 PM",
                    text:
                        L10n.getTranslatedText(context, 'If you struggle with depression know that you are not alone'),
                    imagePath: 'assets/images/meditate_illustration.png',
                    isVideo: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildChannelItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Icon(icon, color: Colors.black, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.rubik(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }


  Widget buildPost({
    required String userName,
    required String time,
    required String text,
    required String imagePath,
    bool isVideo = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              CircleAvatar(backgroundColor: Colors.grey.shade300, radius: 20),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    time,
                    style: GoogleFonts.rubik(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              Spacer(),
              Icon(Icons.more_vert),
            ],
          ),
          const SizedBox(height: 12),

          // Post Text
          Text(text, style: GoogleFonts.rubik(fontSize: 14)),
          const SizedBox(height: 12),

          // Image or Video
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
                if (isVideo)
                  Positioned.fill(
                    child: Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 64,
                        color: Colors.white70,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Interaction Row
          Row(
            children: [
              Icon(Icons.favorite_border, size: 20),
              const SizedBox(width: 4),
              Text('100', style: GoogleFonts.rubik(fontSize: 12)),
              const SizedBox(width: 16),
              Icon(Icons.comment, size: 20),
              const SizedBox(width: 4),
              Text('255', style: GoogleFonts.rubik(fontSize: 12)),
              Spacer(),
              if (isVideo)
                Text(
                  '56.5K Views',
                  style: GoogleFonts.rubik(fontSize: 12, color: Colors.black54),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
