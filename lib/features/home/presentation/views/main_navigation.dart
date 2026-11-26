import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:app/features/home/presentation/views/home_screen.dart';
import 'package:app/features/koleksi/presentation/views/koleksi_screen.dart';
import 'package:app/features/profile/presentation/views/edit_profile_screen.dart';
import 'package:app/features/tentang/presentation/views/tentang_screen.dart';
import 'package:app/features/tiket/presentation/views/tiket_screen.dart';

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

  static const Color _activeColor = Color(0xFF3F5243);
  static const Color _inactiveColor = Color(0xFF9E9E9E);
  static const Color _ticketGreen = Color(0xFF1FA34A);

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final selected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? activeIcon : icon,
                color: selected ? _activeColor : _inactiveColor,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? _activeColor : _inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tombol Tiket hijau yang menonjol di atas bar (gaya Gojek / GoPay)
  Widget _buildTicketButton() {
    final selected = _currentIndex == 2;
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _onTabSelected(2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2ECC71), _ticketGreen],
                ),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: _ticketGreen.withValues(alpha: selected ? 0.55 : 0.35),
                    blurRadius: selected ? 16 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                selected
                    ? Icons.confirmation_number
                    : Icons.confirmation_number_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tiket',
            style: TextStyle(
              fontFamily: 'Lato',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: selected ? _ticketGreen : _inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EA),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildTicketButton(),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 12,
        shadowColor: Colors.black26,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Beranda',
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.layers_outlined,
              activeIcon: Icons.layers,
              label: 'Koleksi',
            ),
            const SizedBox(width: 72),
            _buildNavItem(
              index: 3,
              icon: Icons.info_outline,
              activeIcon: Icons.info,
              label: 'Tentang',
            ),
            _buildNavItem(
              index: 4,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
