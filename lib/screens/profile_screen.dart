import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userName; // 로그인 시 받은 사용자 이름 (nullable로 안전하게 처리)

  const ProfileScreen({super.key, this.userName});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '사용자';
  String? _profileImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // 프로필 정보 불러오기 (Firestore에서)
  Future<void> _loadProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Firestore에서 사용자 정보 가져오기
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _userName = data['userName'] as String? ?? widget.userName ?? '사용자';
        });
      } else {
        // Firestore에 문서가 없으면 로그인 시 받은 이름으로 초기화
        setState(() {
          _userName = widget.userName ?? '사용자';
        });
        // Firestore에 초기 데이터 저장
        await _saveProfile();
      }

      // 프로필 이미지는 여전히 로컬에 저장 (SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _profileImagePath = prefs.getString('profile_image_path');
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 정보를 불러오는 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 프로필 정보 저장하기 (Firestore에)
  Future<void> _saveProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Firestore에 이름 저장 (merge: true로 다른 필드는 유지)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'userName': _userName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 프로필 이미지는 로컬에 저장
      if (_profileImagePath != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_path', _profileImagePath!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 정보를 저장하는 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 이름 수정 다이얼로그
  void _showEditNameDialog() {
    final textController = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '이름 수정',
            style: GoogleFonts.notoSans(
              fontWeight: FontWeight.bold,
              color: Colors.brown[800],
            ),
          ),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(
              hintText: '이름을 입력하세요',
              hintStyle: TextStyle(color: Colors.brown[300]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.brown[400]!),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소', style: TextStyle(color: Colors.brown[400])),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  setState(() {
                    _userName = textController.text;
                    _saveProfile();
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('저장', style: TextStyle(color: Colors.brown[800])),
            ),
          ],
        );
      },
    );
  }

  // 프로필 사진 선택
  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
          _saveProfile();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 선택 중 오류가 발생했습니다'),
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
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F0),
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.pacifico(
            fontSize: 28,
            color: const Color(0xFF432C1C),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 프로필 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                child: Row(
                  children: [
                    // 프로필 사진
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.brown[100],
                            backgroundImage: _profileImagePath != null
                                ? FileImage(File(_profileImagePath!))
                                : null,
                            child: _profileImagePath == null
                                ? Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.brown[400],
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF432C1C),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // 이름 및 수정 버튼
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: GoogleFonts.notoSans(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF432C1C),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _showEditNameDialog,
                            icon: const Icon(Icons.edit, size: 16),
                            label: Text(
                              '이름 수정',
                              style: GoogleFonts.notoSans(fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown[50],
                              foregroundColor: Colors.brown[700],
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 내 정보 수정하기 버튼
              Container(
                width: double.infinity,
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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileEditScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.brown[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.settings,
                              color: Colors.brown[600],
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              '내 정보 수정하기',
                              style: GoogleFonts.notoSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF432C1C),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 20,
                            color: Colors.brown[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 로그아웃 버튼
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _logout,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.logout,
                              color: Colors.red[600],
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              '로그아웃',
                              style: GoogleFonts.notoSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[600],
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 20,
                            color: Colors.red[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 로그아웃 함수
  Future<void> _logout() async {
    // 확인 다이얼로그 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '로그아웃',
          style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
        ),
        content: Text('정말 로그아웃 하시겠습니까?', style: GoogleFonts.notoSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '취소',
              style: GoogleFonts.notoSans(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              '로그아웃',
              style: GoogleFonts.notoSans(
                color: Colors.red[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    // 사용자가 확인을 누른 경우
    if (confirmed == true) {
      try {
        // Firebase 로그아웃
        await FirebaseAuth.instance.signOut();

        // 로그인 화면으로 이동 (모든 이전 화면 제거)
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('로그아웃 중 오류가 발생했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
