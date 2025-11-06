import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  String? _selectedGender;
  String _region = '';
  String _favoriteColor = '';

  bool _hasChanges = false;
  bool _isLoading = true;

  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();

    // 텍스트 변경 감지
    _regionController.addListener(() {
      if (!_hasChanges) {
        setState(() => _hasChanges = true);
      }
    });
    _colorController.addListener(() {
      if (!_hasChanges) {
        setState(() => _hasChanges = true);
      }
    });
  }

  @override
  void dispose() {
    _regionController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  // 사용자 정보 불러오기 (Firestore에서)
  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _selectedGender = data['gender'];
          _region = data['region'] ?? '';
          _favoriteColor = data['favoriteColor'] ?? '';

          _regionController.text = _region;
          _colorController.text = _favoriteColor;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('정보를 불러오는 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 사용자 정보 저장하기 (Firestore에)
  Future<void> _saveUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Firestore의 users 컬렉션에 저장 (기존 데이터와 병합)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'gender': _selectedGender,
        'region': _regionController.text.trim(),
        'favoriteColor': _colorController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge: true로 기존 name, email 유지

      setState(() {
        _hasChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장되었습니다', style: GoogleFonts.notoSans()),
            backgroundColor: Colors.brown[600],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
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
    // 로딩 중일 때 표시
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF8F0),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFAF8F0),
          elevation: 0,
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
        body: Center(
          child: CircularProgressIndicator(color: Colors.brown[600]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown[800]),
          onPressed: () {
            if (_hasChanges) {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      '저장하지 않은 변경사항',
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                    content: Text(
                      '변경사항을 저장하지 않고 나가시겠습니까?',
                      style: GoogleFonts.notoSans(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          '취소',
                          style: TextStyle(color: Colors.brown[400]),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Text(
                          '나가기',
                          style: TextStyle(color: Colors.red[600]),
                        ),
                      ),
                    ],
                  );
                },
              );
            } else {
              Navigator.pop(context);
            }
          },
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.save,
              color: _hasChanges ? Colors.brown[800] : Colors.brown[300],
            ),
            onPressed: _hasChanges ? _saveUserInfo : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 성별 선택
                Text(
                  '성별',
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
                            _hasChanges = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _selectedGender == '남자'
                                ? Colors.brown[100]
                                : Colors.brown[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedGender == '남자'
                                  ? Colors.brown[400]!
                                  : Colors.brown.withValues(alpha: 0.1),
                              width: _selectedGender == '남자' ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                                  fontWeight: _selectedGender == '남자'
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
                            _hasChanges = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _selectedGender == '여자'
                                ? Colors.brown[100]
                                : Colors.brown[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedGender == '여자'
                                  ? Colors.brown[400]!
                                  : Colors.brown.withValues(alpha: 0.1),
                              width: _selectedGender == '여자' ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                                  fontWeight: _selectedGender == '여자'
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
                  '사는 지역',
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
                    hintStyle: TextStyle(color: Colors.brown[300]),
                    prefixIcon: Icon(
                      Icons.location_on,
                      color: Colors.brown[400],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.brown.withValues(alpha: 0.1),
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
                ),
                const SizedBox(height: 24),

                // 좋아하는 색깔
                Text(
                  '좋아하는 색깔',
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
                    hintStyle: TextStyle(color: Colors.brown[300]),
                    prefixIcon: Icon(Icons.palette, color: Colors.brown[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.brown.withValues(alpha: 0.1),
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
                ),
                const SizedBox(height: 32),

                // 저장 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _hasChanges ? _saveUserInfo : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasChanges
                          ? const Color(0xFF432C1C)
                          : Colors.brown[300],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _hasChanges ? 2 : 0,
                    ),
                    child: Text(
                      '저장하기',
                      style: GoogleFonts.notoSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
