import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../collection/record_page.dart';
import '../village/village_page.dart';
import '../village/actualite_page.dart';
import '../profile/profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final AuthService _auth = AuthService();

  // On crée une structure pour lier l'icône et la page ensemble
  // Cela évite les décalages d'index
  List<Map<String, dynamic>> _getMenuConfig(bool isCollector) {
    return [
      {
        'page': const VillagePage(),
        'label': 'Village',
        'icon': Icons.maps_home_work_outlined,
        'selectedIcon': Icons.maps_home_work,
      },
      if (isCollector)
        {
          'page': const RecordPage(),
          'label': 'Collecter',
          'icon': Icons.mic_none,
          'selectedIcon': Icons.mic,
        },
      {
        'page': const ActualitePage(),
        'label': 'Activité',
        'icon': Icons.notifications_none,
        'selectedIcon': Icons.notifications,
      },
      if (isCollector)
        {
          'page': const ProfilePage(),
          'label': 'Héritage',
          'icon': Icons.person_outline,
          'selectedIcon': Icons.person,
        },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isCollector = _auth.isCollector();
    final bool isWideScreen = MediaQuery.of(context).size.width > 900;

    // On génère la configuration actuelle
    final menuConfig = _getMenuConfig(isCollector);

    // Sécurité pour l'index
    if (_selectedIndex >= menuConfig.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR (WEB)
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
              destinations: menuConfig
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item['icon']),
                      selectedIcon: Icon(item['selectedIcon']),
                      label: Text(item['label']),
                    ),
                  )
                  .toList(),
            ),

          // CONTENU PRINCIPAL (Utilisation de IndexedStack pour garder les pages vivantes)
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: menuConfig
                  .map<Widget>((item) => item['page'] as Widget)
                  .toList(),
            ),
          ),
        ],
      ),

      // BARRE DU BAS (MOBILE)
      bottomNavigationBar: isWideScreen
          ? null
          : NavigationBar(
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFF8C6239).withAlpha(51),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              destinations: menuConfig
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item['icon']),
                      selectedIcon: Icon(item['selectedIcon']),
                      label: item['label'],
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
