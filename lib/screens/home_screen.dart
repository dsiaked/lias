import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_screen.dart';
import 'folder_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [ChatScreen(userName: widget.userName), const FolderScreen()];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F0), // 로그인 화면과 같은 배경색
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 0
                        ? Colors.brown[50]
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedIndex == 0
                        ? Icons.chat_bubble
                        : Icons.chat_bubble_outline,
                    color: _selectedIndex == 0
                        ? const Color(0xFF432C1C)
                        : Colors.brown[400],
                    size: 24,
                  ),
                ),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 1
                        ? Colors.brown[50]
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedIndex == 1 ? Icons.folder : Icons.folder_outlined,
                    color: _selectedIndex == 1
                        ? const Color(0xFF432C1C)
                        : Colors.brown[400],
                    size: 24,
                  ),
                ),
                label: 'Folder',
              ),
            ],
            selectedItemColor: const Color(0xFF432C1C),
            unselectedItemColor: Colors.brown[400],
            selectedLabelStyle: GoogleFonts.notoSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.notoSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
