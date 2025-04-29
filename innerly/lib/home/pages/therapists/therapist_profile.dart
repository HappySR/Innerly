import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Innerly/widget/profile_button.dart';

class TherapistProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Padding controls
    double profileImagePadding = 20.0;
    double buttonMargin = 14.0;
    double ratingBoxOuterPadding = 22.0;
    double ratingBoxInnerPadding = 22.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF6F0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.aclonica(
            fontSize: 24,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(22, 10, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image
                Padding(
                  padding: EdgeInsets.all(profileImagePadding),
                  child: CircleAvatar(
                    radius: 75,
                    backgroundImage: AssetImage('assets/user/user.png'),
                  ),
                ),

                // Name and Title
                Text(
                  'Dr. Julia',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Licensed Therapist',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),

                SizedBox(height: 20),

                // Rating Box
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    ratingBoxOuterPadding,
                    16,
                    ratingBoxOuterPadding,
                    16,
                  ),
                  margin: EdgeInsets.symmetric(vertical: buttonMargin),
                  decoration: BoxDecoration(
                    color: Color(0xFFD9F2F2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 5),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rating',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(ratingBoxInnerPadding),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F5F1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  '4.8',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 24,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Very kind and helpful!',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Profile buttons
                ProfileButton(icon: Icons.settings, text: 'Settings'),
                SizedBox(height: buttonMargin),

                ProfileButton(icon: Icons.language, text: 'Language'),
                SizedBox(height: buttonMargin),

                ProfileButton(icon: Icons.info_outline, text: 'About'),
                SizedBox(height: buttonMargin),

                ProfileButton(icon: Icons.logout, text: 'Logout'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
