import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown[800]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '내 정보 수정',
          style: GoogleFonts.notoSans(
            fontSize: 20,
            color: const Color(0xFF432C1C),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                '내 정보 수정 기능\n(구체적인 코드는 나중에 구현 예정)',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  color: Colors.brown[400],
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
