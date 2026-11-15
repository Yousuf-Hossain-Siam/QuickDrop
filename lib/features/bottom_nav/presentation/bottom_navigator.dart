import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pos_background_upload_download/features/home/presentation/home_screen.dart';
import 'package:flutter_pos_background_upload_download/features/downloads/presentation/downloads_screen.dart';
import 'package:flutter_pos_background_upload_download/features/uploads/presentation/uploads_screen.dart';
import 'package:flutter_pos_background_upload_download/features/bottom_nav/providers/bottom_navigator_provider.dart';
import 'package:flutter_pos_background_upload_download/features/profile/presentation/profile_screen.dart';

class BottomNavigator extends StatelessWidget {
  const BottomNavigator({super.key});

  static const _screens = [
    HomeScreen(),
    UploadsScreen(),
    DownloadsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final selectedIndex = ref.watch(bottomNavigatorIndexProvider);

        return Scaffold(
          body: Stack(
            children: [IndexedStack(index: selectedIndex, children: _screens)],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) {
                  ref.read(bottomNavigatorIndexProvider.notifier).state = index;
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.space_dashboard_outlined),
                    selectedIcon: Icon(Icons.space_dashboard),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.cloud_upload_outlined),
                    selectedIcon: Icon(Icons.cloud_upload),
                    label: 'Upload',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.cloud_download_outlined),
                    selectedIcon: Icon(Icons.cloud_download),
                    label: 'Download',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
