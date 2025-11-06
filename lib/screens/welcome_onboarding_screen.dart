import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class WelcomeOnboardingScreen extends StatefulWidget {
  final String userName;

  const WelcomeOnboardingScreen({super.key, required this.userName});

  @override
  State<WelcomeOnboardingScreen> createState() =>
      _WelcomeOnboardingScreenState();
}

class _WelcomeOnboardingScreenState extends State<WelcomeOnboardingScreen> {
  String? _selectedGender;
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _regionController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  // 모든 필수 정보가 입력되었는지 확인
  bool get _isFormComplete {
    return _selectedGender != null &&
        _regionController.text.trim().isNotEmpty &&
        _colorController.text.trim().isNotEmpty;
  }

  // 정보 저장 및 홈 화면으로 이동
  Future<void> _saveAndContinue() async {
    if (!_isFormComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('모든 정보를 입력해주세요', style: GoogleFonts.notoSans()),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Firestore에 사용자 정보 저장
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        // set 하고 get 이 결정을 함 , 데이터를 저장할지 가져올지
        'gender': _selectedGender,
        'region': _regionController.text.trim(),
        'favoriteColor': _colorController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'onboardingCompleted': true,
      }, SetOptions(merge: true));

      if (mounted) {
        // 홈 화면으로 이동 (뒤로 가기 불가)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(userName: widget.userName),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F0),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.brown[600]))
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      // 환영 메시지
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.waving_hand,
                              size: 60,
                              color: Colors.amber[700],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '환영합니다!',
                              style: GoogleFonts.pacifico(
                                fontSize: 36,
                                color: const Color(0xFF432C1C),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.userName}님',
                              style: GoogleFonts.notoSans(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[700],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '더 나은 서비스를 제공하기 위해\n몇 가지 정보를 입력해주세요',
                              style: GoogleFonts.notoSans(
                                fontSize: 16,
                                color: Colors.brown[600],
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // 정보 입력 카드
                      Container(
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
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 필수 입력 안내
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.brown[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 20,
                                      color: Colors.brown[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '모든 항목은 필수 입력입니다',
                                        style: GoogleFonts.notoSans(
                                          fontSize: 14,
                                          color: Colors.brown[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // 성별 선택
                              Text(
                                '성별 *',
                                style: GoogleFonts.notoSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown[800],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedGender = '남자';
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _selectedGender == '남자'
                                              ? Colors.brown[100]
                                              : Colors.brown[50],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _selectedGender == '남자'
                                                ? Colors.brown[400]!
                                                : Colors.brown.withValues(
                                                    alpha: 0.1,
                                                  ),
                                            width: _selectedGender == '남자'
                                                ? 2
                                                : 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.male,
                                              color: _selectedGender == '남자'
                                                  ? Colors.brown[800]
                                                  : Colors.brown[400],
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '남자',
                                              style: GoogleFonts.notoSans(
                                                fontSize: 16,
                                                fontWeight:
                                                    _selectedGender == '남자'
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: _selectedGender == '남자'
                                                    ? Colors.brown[800]
                                                    : Colors.brown[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedGender = '여자';
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _selectedGender == '여자'
                                              ? Colors.brown[100]
                                              : Colors.brown[50],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _selectedGender == '여자'
                                                ? Colors.brown[400]!
                                                : Colors.brown.withValues(
                                                    alpha: 0.1,
                                                  ),
                                            width: _selectedGender == '여자'
                                                ? 2
                                                : 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.female,
                                              color: _selectedGender == '여자'
                                                  ? Colors.brown[800]
                                                  : Colors.brown[400],
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '여자',
                                              style: GoogleFonts.notoSans(
                                                fontSize: 16,
                                                fontWeight:
                                                    _selectedGender == '여자'
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: _selectedGender == '여자'
                                                    ? Colors.brown[800]
                                                    : Colors.brown[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // 사는 지역
                              Text(
                                '사는 지역 *',
                                style: GoogleFonts.notoSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown[800],
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _regionController,
                                decoration: InputDecoration(
                                  hintText: '예: 서울, 부산, 대구...',
                                  hintStyle: TextStyle(
                                    color: Colors.brown[300],
                                  ),
                                  prefixIcon: Icon(
                                    Icons.location_on,
                                    color: Colors.brown[400],
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.brown.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.brown[400]!,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.brown[50],
                                ),
                                style: GoogleFonts.notoSans(
                                  fontSize: 16,
                                  color: Colors.brown[800],
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 24),

                              // 좋아하는 색깔
                              Text(
                                '좋아하는 색깔 *',
                                style: GoogleFonts.notoSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown[800],
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _colorController,
                                decoration: InputDecoration(
                                  hintText: '예: 파란색, 빨간색, 초록색...',
                                  hintStyle: TextStyle(
                                    color: Colors.brown[300],
                                  ),
                                  prefixIcon: Icon(
                                    Icons.palette,
                                    color: Colors.brown[400],
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.brown.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.brown[400]!,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.brown[50],
                                ),
                                style: GoogleFonts.notoSans(
                                  fontSize: 16,
                                  color: Colors.brown[800],
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 시작하기 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isFormComplete ? _saveAndContinue : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFormComplete
                                ? const Color(0xFF432C1C)
                                : Colors.brown[300],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: _isFormComplete ? 4 : 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '시작하기',
                                style: GoogleFonts.notoSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 안내 텍스트
                      Center(
                        child: Text(
                          '입력하신 정보는 나중에 프로필에서 수정할 수 있습니다',
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            color: Colors.brown[400],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
