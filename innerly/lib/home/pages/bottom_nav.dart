import 'package:Innerly/home/pages/profile_view.dart';
import 'package:Innerly/home/pages/therapists/therapist_home.dart';
import 'package:Innerly/home/pages/therapists/therapist_requests.dart';
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
  late List<Widget> _pages;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pages =
        UserRole.isTherapist
            ? [
              HomeTherapist(
                onProfileTap: () {
                  setState(() {
                    _selectedIndex =
                        3; // Navigate to Profile tab when user image is tapped
                  });
                },
              ),
              const PatientsPage(),
              PatientsRequests(),
              CommunityScreen(),
              TherapistProfile(),
            ]
            : [
              MentalHealthHome(
                onProfileTap: () {
                  setState(() {
                    _selectedIndex =
                        3; // Navigate to Profile tab when user image is tapped
                  });
                },
              ),
              const TherapistsListScreen(),
              CommunityScreen(),
              const ProfileView(),
            ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BottomNavProvider>(
      builder: (context, bottomNavProvider, child) {
        return Scaffold(
          body: _pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: InnerlyTheme.secondary.withAlpha(200),
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: false,
            showSelectedLabels: false,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            items: UserRole.isTherapist
                ? [ // 5 items for therapists
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/icons/home.png',
                  width: 24,
                  height: 24,
                  color: _selectedIndex == 0
                      ? InnerlyTheme.secondary.withAlpha(200)
                      : Colors.grey,
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/icons/chat.png',
                  width: 24,
                  height: 24,
                  color: _selectedIndex == 1
                      ? InnerlyTheme.secondary.withAlpha(200)
                      : Colors.grey,
                ),
                label: 'Chats',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/icons/calendar.png',
                  width: 34,
                  height: 30,
                  color: _selectedIndex == 2
                      ? InnerlyTheme.secondary.withAlpha(200)
                      : Colors.grey,
                ),
                label: 'Clients',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/icons/community.png',
                  width: 30,
                  height: 32,
                  color: _selectedIndex == 3
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
                  color: _selectedIndex == 4
                      ? InnerlyTheme.secondary.withAlpha(200)
                      : Colors.grey,
                ),
                label: 'Profile',
              ),
            ]
                : [ // 4 items for regular users
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/icons/home.png',
                  width: 24,
                  height: 24,
                  color: _selectedIndex == 0
                      ? InnerlyTheme.secondary.withAlpha(200)
                      : Colors.grey,
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/icons/plus.png',
                  width: 24,
                  height: 30,
                  color: _selectedIndex == 1
                      ? InnerlyTheme.secondary.withAlpha(200)
                      : Colors.grey,
                ),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/icons/community.png',
                  width: 30,
                  height: 32,
                  color: _selectedIndex == 2
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
                  color: _selectedIndex == 3
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
