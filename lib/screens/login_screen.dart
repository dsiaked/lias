import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F0),
      body: SafeArea(
        // SafeArea : 기기의 노치, 상태 표시줄, 하단에 홈 인디케이터 등을 "피해서" 콘텐츠가 표시되도록 하는 위젯
        child: SingleChildScrollView(
          // 화면 넘칠 때 스크롤 가능하게
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 90),
                // 앱 로고 텍스트
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'lias',
                        style: GoogleFonts.pacifico(
                          fontSize: 100,
                          color: const Color(0xFF432C1C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // 장식적인 밑줄 추가
                Container(
                  // 밑줄 추가 방식 알아두기! + 아래에 Stack으로 겹쳐서 쌓기
                  width: 500,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      // 이 방식 알아는 두기!
                      // 밑줄을 그라데이션으로 변경하기
                      colors: [
                        Colors.brown.withValues(
                          alpha: 0.1,
                        ), // withValues : 투명도를 조절하게 해주는 함수
                        Colors.brown.withValues(
                          alpha: 0.5,
                        ), // 그라데이션 이므로 이렇게 3개정도가 적당한듯?
                        Colors.brown.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Stack(
                  // 겹쳐서 쌓기
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 150, // 100에서 150으로 증가
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.brown.withValues(alpha: 0.05),
                            const Color(0xFFE8B7A9).withValues(alpha: 0.3),
                            Colors.brown.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8B7A9).withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 65), // 간격 조정
                // 입력 필드들을 카드로 감싸기
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      // + required 라는 설명이 그 변수는 꼭 필요하다는 뜻!, super 만으로는 필수 X , 기본값이 부여될 수 있음!!
                      BoxShadow(
                        // 위젯에 입체감을 주는 그림자 효과
                        color: Colors.brown.withValues(alpha: 0.1), // 투명도, 색상
                        blurRadius: 20, // 흐림 정도
                        offset: const Offset(
                          0,
                          10,
                        ), // 그림자의 위치 조정, x축, y축, x가 0이면 위젯 바로 아래에 그림자를 설치하겠다는 뜻!
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _idController,
                        decoration: InputDecoration(
                          labelText: '아이디',
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
                          ), // prefixIcon : 입력 필드 "앞에" 아이콘 추가 (사람 아이콘)
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
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
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 로그인 버튼
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HomeScreen(userName: _idController.text),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(55),
                    backgroundColor: const Color(0xFF432C1C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    '로그인',
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  mainAxisSize: MainAxisSize.min, // Column이 필요한 만큼만 공간 차지
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '계정이 없으신가요? ',
                          style: TextStyle(
                            color: Colors.brown[400],
                            fontSize: 15,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            '회원가입',
                            style: TextStyle(
                              color: Colors.brown[800],
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Transform.translate(
                      offset: const Offset(0, -2), // 위로 4픽셀 이동
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '아이디 찾기',
                              style: TextStyle(
                                color: Colors.brown[500],
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                            ),
                            child: Text(
                              '|',
                              style: TextStyle(
                                color: Colors.brown[300],
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '비밀번호 찾기',
                              style: TextStyle(
                                color: Colors.brown[500],
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // 소셜 로그인 섹션
                Text(
                  '소셜 계정으로 로그인',
                  style: TextStyle(
                    color: Colors.brown[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialLoginButton(
                      icon: FontAwesomeIcons.google,
                      color: Colors.red[400]!,
                      onPressed: () {},
                    ),
                    const SizedBox(width: 12),
                    _buildSocialLoginButton(
                      icon: FontAwesomeIcons.n,
                      color: const Color(0xFF03C75A),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 12),
                    _buildSocialLoginButton(
                      icon: FontAwesomeIcons.instagram,
                      color: const Color(0xFFE4405F),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final double size = 52.0;
    Widget iconWidget;

    if (icon == FontAwesomeIcons.google) {
      iconWidget = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://www.freepnglogos.com/uploads/google-logo-png/google-logo-png-suite-everything-you-need-know-about-google-newest-0.png',
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (icon == FontAwesomeIcons.n) {
      iconWidget = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF03C75A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF03C75A).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'N',
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      );
    } else {
      iconWidget = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFE4405F), Color(0xFFD92E7F), Color(0xFF9B36B7)],
            stops: [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE4405F).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: FaIcon(
            FontAwesomeIcons.instagram,
            color: Colors.white,
            size: 30,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: iconWidget,
        ),
      ),
    );
  }
}
