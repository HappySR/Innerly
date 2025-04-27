import 'package:Innerly/widget/innerly_theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../started/welcome_page.dart';
import 'edit_profile_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF4E7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, Kate",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Your Mental Health Score: 85",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 35,
                    backgroundImage: AssetImage(
                      'assets/user/user.png',
                    ), // your asset path
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Edit Profile Button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfilePage(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide(color: InnerlyTheme.beige),
                  backgroundColor: InnerlyTheme.beige,
                ),
                icon: const Icon(Icons.edit, size: 16, color: Colors.black,),
                label: const Text("Edit Profile", style: TextStyle(color: Colors.black),),
              ),
              const SizedBox(height: 20),

              // Mood Tracker Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: InnerlyTheme.beige,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Mood Tracker Summary",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Progress Bar
                    LinearProgressIndicator(
                      value: 0.3,
                      backgroundColor: Color(0xFFFEE2BE),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 16),

                    // Mood Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        _MoodIcon(emoji: "😢", label: "Low"),
                        _MoodIcon(emoji: "😐", label: "Neutral"),
                        _MoodIcon(emoji: "😊", label: "Happy"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Personal Growth Section
              const Text(
                "Personal Growth",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildGrowthItem(
                emoji: '📝',
                title: "Journals Completed",
                value: "12",
              ),
              _buildGrowthItem(
                emoji: '🎯',
                title: "Challenges Achieved",
                value: "5",
              ),
              _buildGrowthItem(
                emoji: '🔥',
                title: "Current Journey Stage",
                value: "Stage 3",
              ),
              const SizedBox(height: 24),

              // Therapist and Community Section
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildCard(
                        title: "Therapist",
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundImage: AssetImage(
                                'assets/user/user.png',
                              ), // therapist image
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Jane Tanner, PhD",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              "CBT",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ), // <-- added this
                                      ),
                                    ),
                                    child: const Text(
                                      "Message",
                                      style: TextStyle(fontSize: 12,
                                      color: Colors.black),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ), // <-- added this
                                      ),
                                    ),
                                    child: const Text(
                                      "Book Session",
                                      style: TextStyle(fontSize: 12,
                                          color: Colors.black),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCard(
                        title: "My Community Posts",
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "12 posts . 45 comments",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "56 Followers . 45 comments",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ), // <-- added this
                                ),
                              ),
                              child: const Text(
                                "View my posts",
                                style: TextStyle(fontSize: 12,
                                    color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Wellness Goals
              _buildCard(
                title: "Wellness Goals",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _GoalItem(
                      goal: "Meditate 5 times this week",
                      isCompleted: true,
                    ),
                    _GoalItem(goal: "Log mood daily", isCompleted: true),
                    _GoalItem(
                      goal: "Eat 2 healthy meals daily",
                      isCompleted: true,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0), // Margin around button
                child: SizedBox(
                  width: double.infinity, // Full width
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0), // Padding inside button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Rounded corners
                      ),
                      backgroundColor: Colors.redAccent, // Button color (optional, can remove if you want default color)
                    ),
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const WelcomePage()),
                            (route) => false,
                      );
                    },
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Text color
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrowthItem({
    required String emoji,
    required String title,
    required String value,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Text(emoji, style: const TextStyle(fontSize: 30)),

      title: Text(title),
      trailing: Text(value),
      onTap: () {},
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: InnerlyTheme.beige,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// Mood Icon Widget
class _MoodIcon extends StatelessWidget {
  final String emoji;
  final String label;

  const _MoodIcon({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// Wellness Goal Item
class _GoalItem extends StatelessWidget {
  final String goal;
  final bool isCompleted;

  const _GoalItem({required this.goal, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.check_circle, color: Color(0xFF6AA84F)),
      title: Text(goal, style: const TextStyle(fontSize: 14)),
    );
  }
}
