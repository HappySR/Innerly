import 'package:Innerly/home/pages/profile_view.dart';
import 'package:Innerly/home/pages/therapists/therapist_home.dart';
import 'package:Innerly/home/pages/therapists_list_view.dart';
import 'package:Innerly/widget/innerly_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Innerly/home/pages/therapists/therapist_patients.dart';
import 'package:Innerly/home/pages/therapists/therapist_profile.dart';
import '../../services/role.dart';
import '../providers/bottom_nav_provider.dart';
import 'community_screen.dart';
import 'explore_view.dart';
import 'home_view.dart';
import 'notifications_view.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  @override
  Widget build(BuildContext context) {
    return Consumer<BottomNavProvider>(
      builder: (context, bottomNavProvider, child) {
        final int selectedIndex = bottomNavProvider.selectedIndex;

        final List<Widget> pages = [
          if (UserRole.isTherapist)
            const HomeTherapist()
          else
            MentalHealthHome(),
          if (UserRole.isTherapist)
            const PatientsPage()
          else
            const TherapistsListScreen(),
          CommunityScreen(), // <-- now a normal screen
          if (UserRole.isTherapist)
            TherapistProfile()
          else
            const ProfileView(),
        ];

        return Scaffold(
          body: IndexedStack(index: selectedIndex, children: pages),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (index) {
              bottomNavProvider.setIndex(index);
            },
            selectedItemColor: InnerlyTheme.secondary.withAlpha(200),
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: false,
            showSelectedLabels: false,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/icons/home.png',
                  width: 24,
                  height: 24,
                  color: selectedIndex == 0
                      ? InnerlyTheme.secondary.withAlpha(200)
                      : Colors.grey,
                ),
                label: UserRole.isTherapist ? 'Therapist' : 'Home',
              ),
              BottomNavigationBarItem(
                icon: UserRole.isTherapist
                    ? Icon(
                  Icons.medical_services,
                  color: selectedIndex == 1
                      ? InnerlyTheme.secondary.withAlpha(200)
                      : Colors.grey,
                )
                    : Image.asset(
                  'assets/icons/plus.png',
                  width: 24,
                  height: 30,
                  color: selectedIndex == 1
                      ? InnerlyTheme.secondary.withAlpha(200)
                      : Colors.grey,
                ),
                label: UserRole.isTherapist ? 'Clients' : 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/icons/community.png',
                  width: 30,
                  height: 32,
                  color: selectedIndex == 2
                      ? InnerlyTheme.secondary.withAlpha(200)
                      : Colors.grey,
                ),
                label: 'Community',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/icons/user.png',
                  width: 22,
                  height: 28,
                  color: selectedIndex == 3
                      ? InnerlyTheme.secondary.withAlpha(200)
                      : Colors.grey,
                ),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
