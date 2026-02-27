import 'package:agromotion/components/agro_navbar.dart';
import 'package:agromotion/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'schedule_screen.dart';
import 'statistics_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 1; // Começa no Home (centro)
  late PageController _pageController;

  // The controller lives here to survive tab swipes
  final Flutter3DController _modelController = Flutter3DController();

  // Ordem: 0: Horário, 1: Home, 2: Estatísticas
  late final List<Widget> _pages = [
    const ScheduleScreen(),
    HomeScreen(modelController: _modelController),
    const StatisticsScreen(),
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
        physics: const BouncingScrollPhysics(),
        children: _pages,
        onPageChanged: (i) {
          setState(() {
            _index = i;
          });
        },
      ),
<<<<<<< Updated upstream
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
=======
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 110,
        child: Wrap(
          children: [
            AgroNavBar(
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
          ],
        ),
>>>>>>> Stashed changes
      ),
    );
  }
}
