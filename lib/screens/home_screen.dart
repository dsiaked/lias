import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_screen.dart';
import 'calendar_screen.dart';
import 'folder_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName; // 사용자 이름을 저장하는 필드

  const HomeScreen({
    super.key,
    required this.userName,
  }); // 필수적으로 userName을 받도록 변경

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 0: chat, 1: calendar, 2: folder, 3: profile
  late List<Widget> _screens; // 나중에 생성함

  @override
  void initState() {
    // init, 위젯이 생성될 때 단 한 번 호출되는 함수
    super.initState();
    _screens = [
      ChatScreen(userName: widget.userName),
      CalendarScreen(userName: widget.userName),
      const FolderScreen(),
      ProfileScreen(userName: widget.userName),
    ];
  } // 스크린에 0: chat, 1: calendar, 2: folder, 3: profile 저장

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F0), // 로그인 화면과 같은 배경색
      body: _screens[_selectedIndex], // 선택된 인덱스에 해당하는 화면 표시
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25), // clipReact가 여기에 맞출 예정
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          // 강제로 부모에 맞춰서 잘라냄
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: _selectedIndex, // 현재 선택된 인덱스
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
                label: 'Chats',
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
                    _selectedIndex == 1
                        ? Icons.calendar_today
                        : Icons.calendar_today_outlined,
                    color: _selectedIndex == 1
                        ? const Color(0xFF432C1C)
                        : Colors.brown[400],
                    size: 24,
                  ),
                ),
                label: 'Calendar',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 2
                        ? Colors.brown[50]
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedIndex == 2 ? Icons.folder : Icons.folder_outlined,
                    color: _selectedIndex == 2
                        ? const Color(0xFF432C1C)
                        : Colors.brown[400],
                    size: 24,
                  ),
                ),
                label: 'Folder',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 3
                        ? Colors.brown[50]
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedIndex == 3 ? Icons.person : Icons.person_outline,
                    color: _selectedIndex == 3
                        ? const Color(0xFF432C1C)
                        : Colors.brown[400],
                    size: 24,
                  ),
                ),
                label: 'Profile',
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
