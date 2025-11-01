import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // 회원가입 처리 함수
  Future<void> _handleSignup() async {
    developer.log('🔵 회원가입 시작', name: 'SignupScreen');

    if (!_formKey.currentState!.validate()) {
      developer.log('❌ 폼 검증 실패', name: 'SignupScreen');
      return;
    }

    developer.log('✅ 폼 검증 통과', name: 'SignupScreen');

    setState(() {
      _isLoading = true;
    });

    try {
      developer.log('🔄 Firebase Authentication 시도 중...', name: 'SignupScreen');
      developer.log(
        '이메일: ${_emailController.text.trim()}',
        name: 'SignupScreen',
      );

      // Firebase Authentication으로 사용자 생성
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            // 회원가입을 하는 부분에서는 여기가 다르다!
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      developer.log(
        '✅ Authentication 성공! UID: ${userCredential.user!.uid}',
        name: 'SignupScreen',
      );

      developer.log('🔄 Firestore에 사용자 정보 저장 중...', name: 'SignupScreen');

      // Firestore에 사용자 기본 정보만 저장 (users 컬렉션)
      final String uid = userCredential.user!.uid; // 이 줄에 대한 자세한 설명은 메모장에!
      //collection('users') 컬렉션에 uid 문서 생성 후 set 메서드로 데이터 저장
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameController.text.trim(), // 모든 데이터는 "키" 의 값으로 표시가 된다!
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      developer.log('✅ Firestore 저장 완료!', name: 'SignupScreen');

      if (mounted) {
        // 회원가입 성공 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원가입이 완료되었습니다!', style: GoogleFonts.notoSans()),
            backgroundColor: Colors.green,
          ),
        );

        developer.log('🎉 회원가입 완료! 로그인 화면으로 이동', name: 'SignupScreen');

        // 로그인 화면으로 돌아가기
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      developer.log(
        '❌ FirebaseAuthException: ${e.code} - ${e.message}',
        name: 'SignupScreen',
      );

      String errorMessage;

      switch (e.code) {
        case 'weak-password':
          errorMessage = '비밀번호가 너무 약합니다. 6자 이상 입력해주세요.';
          break;
        case 'email-already-in-use':
          errorMessage = '이미 사용 중인 이메일입니다.';
          break;
        case 'invalid-email':
          errorMessage = '유효하지 않은 이메일 형식입니다.';
          break;
        default:
          errorMessage = '회원가입 중 오류가 발생했습니다: ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: GoogleFonts.notoSans()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      developer.log('❌ 예상치 못한 오류: $e', name: 'SignupScreen');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '회원가입 중 오류가 발생했습니다: $e',
              style: GoogleFonts.notoSans(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      developer.log('🔵 회원가입 프로세스 종료', name: 'SignupScreen');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown[800]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '회원가입',
          style: GoogleFonts.notoSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF432C1C),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // 안내 텍스트
                  Text(
                    '새로운 계정을 만들어주세요',
                    style: GoogleFonts.notoSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF432C1C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'AI 챗봇과 대화를 시작해보세요',
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      color: Colors.brown[400],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // 입력 필드들을 카드로 감싸기
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
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // 이름 입력
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: '이름',
                            labelStyle: TextStyle(color: Colors.brown[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.brown[50],
                            prefixIcon: Icon(
                              Icons.person,
                              color: Colors.brown[400],
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '이름을 입력해주세요';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 이메일 입력
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: '이메일',
                            labelStyle: TextStyle(color: Colors.brown[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.brown[50],
                            prefixIcon: Icon(
                              Icons.email,
                              color: Colors.brown[400],
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '이메일을 입력해주세요';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return '유효한 이메일 주소를 입력해주세요';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 비밀번호 입력
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: '비밀번호',
                            labelStyle: TextStyle(color: Colors.brown[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.brown[50],
                            prefixIcon: Icon(
                              Icons.lock,
                              color: Colors.brown[400],
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.brown[400],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '비밀번호를 입력해주세요';
                            }
                            if (value.length < 6) {
                              return '비밀번호는 6자 이상이어야 합니다';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 비밀번호 확인
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: '비밀번호 확인',
                            labelStyle: TextStyle(color: Colors.brown[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.brown[50],
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Colors.brown[400],
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.brown[400],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '비밀번호 확인을 입력해주세요';
                            }
                            if (value != _passwordController.text) {
                              return '비밀번호가 일치하지 않습니다';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 회원가입 버튼
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(55),
                      backgroundColor: const Color(0xFF432C1C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            '회원가입',
                            style: GoogleFonts.notoSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  const SizedBox(height: 20),

                  // 로그인 화면으로 이동
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '이미 계정이 있으신가요? ',
                        style: TextStyle(
                          color: Colors.brown[400],
                          fontSize: 15,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '로그인',
                          style: TextStyle(
                            color: Colors.brown[800],
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
