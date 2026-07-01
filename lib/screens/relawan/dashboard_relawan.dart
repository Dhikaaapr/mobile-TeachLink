import 'package:flutter/material.dart';
import 'home_tab_relawan.dart';
import 'search_tab_relawan.dart';
import 'profile_tab_relawan.dart';

class DashboardRelawan extends StatefulWidget {
  const DashboardRelawan({super.key});

  @override
  State<DashboardRelawan> createState() => _DashboardRelawanState();
}

class _DashboardRelawanState extends State<DashboardRelawan> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeTabRelawan(),
    SearchTabRelawan(),
    ProfileTabRelawan(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Cari Siswa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
