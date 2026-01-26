import 'package:agromotion/components/agro_navbar.dart';
import 'package:agromotion/screens/admins_screen.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'camera_screen.dart';
import 'schedule_screen.dart';
import 'statistics_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 2; // Começa no Home (centro)

  late PageController _pageController;

  // Ordem: 0: Horário, 1: Câmara, 2: Home, 3: Estatísticas, 4: Perfil (Admins)
  final List<Widget> _pages = [
    const ScheduleScreen(),
    const CameraScreen(),
    const HomeScreen(),
    const StatisticsScreen(),
    const AdminsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        children: _pages,
        onPageChanged: (i) {
          setState(() {
            _index = i;
          });
        },
      ),
      bottomNavigationBar: AgroNavBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() {
            _index = i;
            _pageController.animateToPage(
              i,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        },
      ),
    );
  }
}
