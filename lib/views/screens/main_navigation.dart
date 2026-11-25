import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app/viewmodels/auth_viewmodel.dart';
import 'home/home_screen.dart';
import 'koleksi/koleksi_screen.dart';
import 'tiket/tiket_screen.dart';
import 'tentang/tentang_screen.dart';
import 'profile/edit_profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late final AuthViewModel _authViewModel;
  late int _currentIndex;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _authViewModel = AuthViewModel();
    // Clamp ke range 0-4 (5 tab sekarang)
    _currentIndex = widget.initialIndex;
    if (_currentIndex < 0 || _currentIndex > 4) _currentIndex = 0;
    _authViewModel.saveLastTab(_currentIndex);

    _screens = [
      HomeScreen(
        onBookTicket: () {
          _onTabSelected(2);
        },
        onReadHistory: () {
          _onTabSelected(3);
        },
      ),
      const KoleksiScreen(),
      TiketScreen(
        onGoHome: () {
          _onTabSelected(0);
        },
      ),
      const TentangScreen(),
      ProfileScreen(
        isRootTab: true,
        onSwitchTab: _onTabSelected,
      ),
    ];
  }

  @override
  void didUpdateWidget(covariant MainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex.clamp(0, 4);
      });
      _authViewModel.saveLastTab(_currentIndex);
    }
  }

  @override
  void dispose() {
    _authViewModel.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      _authViewModel.saveLastTab(index);
    }

    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/koleksi');
        break;
      case 2:
        context.go('/tiket');
        break;
      case 3:
        context.go('/tentang');
        break;
      case 4:
        context.go('/profil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EA),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF3F5243),
        unselectedItemColor: const Color(0xFF9E9E9E),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontFamily: 'Lato'),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Lato'),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.layers_outlined),
            activeIcon: Icon(Icons.layers),
            label: 'Koleksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            activeIcon: Icon(Icons.confirmation_number),
            label: 'Tiket',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            activeIcon: Icon(Icons.info),
            label: 'Tentang',
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
