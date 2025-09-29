import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FolderScreen extends StatelessWidget {
  const FolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F0),
        elevation: 0,
        title: Text(
          'lias',
          style: GoogleFonts.pacifico(
            fontSize: 28,
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
              color: Colors.brown.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.brown[50],
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.brown.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  '내 폴더',
                  style: GoogleFonts.notoSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF432C1C),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: 8, // 더 많은 임시 데이터
                  itemBuilder: (context, index) {
                    final folderNames = [
                      '중요한 문서',
                      '프로젝트 자료',
                      '학습 노트',
                      '아이디어 모음',
                      '회의록',
                      '참고 자료',
                      '개인 메모',
                      '업무 문서',
                    ];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.brown.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.brown.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.brown[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.folder,
                            color: Colors.brown[600],
                            size: 24,
                          ),
                        ),
                        title: Text(
                          folderNames[index],
                          style: GoogleFonts.notoSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF432C1C),
                          ),
                        ),
                        subtitle: Text(
                          '${index * 2 + 3}개의 항목',
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: Colors.brown[400],
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.brown[400],
                        ),
                        onTap: () {
                          // 폴더 열기 기능 (미구현)
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF432C1C),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            // 새 폴더 생성 기능 (미구현)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '새 폴더 만들기 기능은 준비 중입니다',
                  style: GoogleFonts.notoSans(),
                ),
                backgroundColor: Colors.brown[600],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.create_new_folder,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
