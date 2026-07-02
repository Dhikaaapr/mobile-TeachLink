import 'package:flutter/material.dart';
import 'home_tab_relawan.dart';
import 'jadwal_relawan_tab.dart';
import 'permintaan_relawan_tab.dart';
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
    JadwalRelawanTab(),        // Jadwal
    PermintaanRelawanTab(),    // Permintaan
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
            label: 'Beranda',
          ),
         BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Jadwal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mail_outline),
            activeIcon: Icon(Icons.mail),
            label: 'Permintaan',
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
