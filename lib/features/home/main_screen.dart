import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart'; // Vérifie bien le chemin vers ton AuthService
import '../collection/record_page.dart';
import '../village/village_page.dart';
import '../village/actualite_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final AuthService _auth = AuthService();

  // --- LOGIQUE DYNAMIQUE ---

  List<Widget> _getPages(bool isCollector) {
    return [
      const VillagePage(),
      if (isCollector) const RecordPage(),
      const ActualitePage(),
    ];
  }

  List<NavigationDestination> _getNavDestinations(bool isCollector) {
    return [
      const NavigationDestination(
        icon: Icon(Icons.maps_home_work_outlined),
        selectedIcon: Icon(Icons.maps_home_work),
        label: 'Village',
      ),
      if (isCollector)
        const NavigationDestination(
          icon: Icon(Icons.mic_none),
          selectedIcon: Icon(Icons.mic),
          label: 'Collecter',
        ),
      const NavigationDestination(
        icon: Icon(Icons.notifications_none),
        selectedIcon: Icon(Icons.notifications),
        label: 'Activité',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isCollector = _auth.isCollector();
    final bool isWideScreen = MediaQuery.of(context).size.width > 900;

    final pages = _getPages(isCollector);
    final destinations = _getNavDestinations(isCollector);

    // Sécurité : si l'utilisateur change de rôle, on réinitialise l'index
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: Row(
        children: [
          if (isWideScreen)
            NavigationRail(
              backgroundColor: const Color(0xFFF5F5F0),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFF5A5A40),
                  size: 30,
                ),
              ),
              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: isWideScreen
          ? null
          : NavigationBar(
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFF8C6239).withAlpha(51),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              destinations: destinations,
            ),
    );
  }
}
