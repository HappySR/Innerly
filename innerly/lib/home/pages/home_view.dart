import 'package:Innerly/widget/innerly_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widget/imageCard.dart';

class MentalHealthHome extends StatelessWidget {
  const MentalHealthHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Drawer(),
      backgroundColor: InnerlyTheme.appBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.filter_list_sharp, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: SizedBox(
          height: 36,
          child: TextField(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Search',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            const SizedBox(height: 10),

            // Centered texts
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Hello, Julia',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HOW ARE YOU FEELING TODAY',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: 108, // 2 * radius
              height: 108,
              child: ClipOval(
                child: Image.asset(
                  'assets/user/user.png',
                  fit: BoxFit.contain, // or try BoxFit.cover or BoxFit.scaleDown
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '"Hey, are you feeling low. Talk to our\nexpert therapist for instant relaxation"',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Row for first two cards
            Row(
              children: const [
                Expanded(child: ShadowImageCard(imagePath: 'assets/images/explore.png')),
                SizedBox(width: 12),
                Expanded(child: ShadowImageCard(imagePath: 'assets/images/interact.png')),
              ],
            ),
            const SizedBox(height: 25),

            // Full-width third image with custom height
            const ShadowImageCard(
              imagePath: 'assets/images/global_chat.png',
              height: 220,
            ),
          ],
        ),
      ),

    );
  }
}

