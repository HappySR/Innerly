import 'package:Innerly/home/pages/profile_view.dart';
import 'package:Innerly/home/pages/therapist_home.dart';
import 'package:Innerly/widget/innerly_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Innerly/home/pages/therapist_patients.dart';
import 'package:Innerly/home/pages/therapist_profile.dart';
import '../../services/role.dart';
import '../providers/bottom_nav_provider.dart';
import 'explore_view.dart';
import 'home_view.dart';
import 'notifications_view.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isNotificationSheetOpen = false;
  PersistentBottomSheetController? _controller;

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
          if (UserRole.isTherapist) const PatientsPage() else ExplorePage(),
          const SizedBox.shrink(), // Placeholder for notifications
          if (UserRole.isTherapist) TherapistProfile() else ProfileView(),
        ];

        return Scaffold(
          key: _scaffoldKey,
          body: IndexedStack(index: selectedIndex, children: pages),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _isNotificationSheetOpen ? 2 : selectedIndex,
            onTap: (index) {
              if (index == 2) {
                // Open notification sheet
                if (!_isNotificationSheetOpen) {
                  setState(() => _isNotificationSheetOpen = true);
                  _controller = _scaffoldKey.currentState!.showBottomSheet(
                    (context) => Container(
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: const NotificationBottomSheet(),
                    ),
                    backgroundColor: Colors.transparent,
                  );
                  _controller!.closed.then((_) {
                    if (mounted) {
                      setState(() => _isNotificationSheetOpen = false);
                    }
                  });
                }
              } else {
                // Close the sheet if it was open and switch tab
                if (_isNotificationSheetOpen) {
                  _controller?.close();
                }
                bottomNavProvider.setIndex(index);
                setState(() => _isNotificationSheetOpen = false);
              }
            },
            selectedItemColor: InnerlyTheme.appColor.withAlpha(180),
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: false,
            showSelectedLabels: false,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            items: [
              if (UserRole.isTherapist)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Therapist',
                )
              else
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),

              if (UserRole.isTherapist)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.medical_services),
                  label: 'Clients',
                )
              else
                const BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Explore',
                ),

              const BottomNavigationBarItem(
                icon: Icon(Icons.notifications),
                label: 'Community',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
