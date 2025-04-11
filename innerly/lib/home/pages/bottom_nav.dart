import 'package:Innerly/widget/innerly_theme.dart';
import 'package:flutter/material.dart';

import '../providers/bottom_nav_provider.dart';
import 'home_view.dart';// Import provider
import 'package:provider/provider.dart';


class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BottomNavProvider>(
      builder: (context, bottomNavProvider, child) {
        final int selectedIndex = bottomNavProvider.selectedIndex;

        final List<Widget> pages = [
          MentalHealthHome(),

        ];

        return Scaffold(
          body: pages[selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: bottomNavProvider.setIndex,
            selectedItemColor: InnerlyTheme.appColor.withAlpha(180),
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: false,
            showSelectedLabels: false,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            items:[
              BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: ( 'Home')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: ('Courses')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.notifications),
                  label:('Community')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: ('Profile')),
            ]
          ),
        );
      },
    );
  }
}
