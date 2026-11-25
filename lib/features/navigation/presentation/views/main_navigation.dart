import 'package:flutter/material.dart';

import 'package:app/features/home/presentation/views/home_screen.dart';
import 'package:app/features/koleksi/presentation/views/koleksi_screen.dart';
import 'package:app/features/tiket/presentation/views/tiket_screen.dart';
import 'package:app/features/tentang/presentation/views/tentang_screen.dart';
import 'package:app/features/chat/presentation/views/chat_screen.dart';
import 'package:app/features/chat/presentation/viewmodels/chat_viewmodel.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late final List<Widget> _screens;
  late final ChatViewModel _chatViewModel;

  @override
  void initState() {
    super.initState();
    _chatViewModel = ChatViewModel();
    _screens = [
      HomeScreen(
        onBookTicket: () {
          setState(() {
            _currentIndex = 2;
          });
        },
        onReadHistory: () {
          setState(() {
            _currentIndex = 3;
          });
        },
      ),
      KoleksiScreen(),
      TiketScreen(
        onGoHome: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
      TentangScreen(),
    ];
  }

  @override
  void dispose() {
    _chatViewModel.dispose();
    super.dispose();
  }

  void _openChatDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        child: ChatScreen(viewModel: _chatViewModel),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openChatDialog(context),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C322B), Color(0xFF3F5243)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFFD4AF37),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4AF37),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Color(0xFF2C322B),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tanya AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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
        ],
      ),
    );
  }
}
