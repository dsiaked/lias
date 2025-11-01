import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'folder_detail_screen.dart';

class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  List<Map<String, dynamic>> _folders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  // 폴더 데이터 불러오기
  Future<void> _loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? foldersData = prefs.getString('folders');
    if (foldersData != null) {
      setState(() {
        _folders = List<Map<String, dynamic>>.from(json.decode(foldersData));
      });
    } else {
      // 초기 Diary 폴더 생성
      setState(() {
        _folders = [
          {'name': 'Diary', 'files': []},
        ];
      });
      _saveFolders();
    }
  }

  // 폴더 데이터 저장하기
  Future<void> _saveFolders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('folders', json.encode(_folders));
  }

  // 새 폴더 생성 다이얼로그
  void _showCreateFolderDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '새 폴더 만들기',
            style: GoogleFonts.notoSans(
              fontWeight: FontWeight.bold,
              color: Colors.brown[800],
            ),
          ),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(
              hintText: '폴더 이름을 입력하세요',
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
                    _folders.add({'name': textController.text, 'files': []});
                    _saveFolders();
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('생성', style: TextStyle(color: Colors.brown[800])),
            ),
          ],
        );
      },
    );
  }

  // 폴더 삭제
  void _deleteFolder(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '폴더 삭제',
            style: GoogleFonts.notoSans(
              fontWeight: FontWeight.bold,
              color: Colors.brown[800],
            ),
          ),
          content: Text(
            '${_folders[index]['name']} 폴더를 삭제하시겠습니까?\n폴더 안의 모든 파일도 함께 삭제됩니다.',
            style: GoogleFonts.notoSans(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소', style: TextStyle(color: Colors.brown[400])),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _folders.removeAt(index);
                  _saveFolders();
                });
                Navigator.pop(context);
              },
              child: Text('삭제', style: TextStyle(color: Colors.red[600])),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F0),
        elevation: 0,
        title: Text(
          'Folder',
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
              color: Colors.brown.withValues(alpha: 0.1),
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
                      color: Colors.brown.withValues(alpha: 0.1),
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
                child: _folders.isEmpty
                    ? Center(
                        child: Text(
                          '폴더가 없습니다',
                          style: GoogleFonts.notoSans(
                            fontSize: 16,
                            color: Colors.brown[400],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _folders.length,
                        itemBuilder: (context, index) {
                          final folder = _folders[index];
                          final fileCount = (folder['files'] as List).length;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.brown.withValues(alpha: 0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.brown.withValues(alpha: 0.05),
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
                                folder['name'],
                                style: GoogleFonts.pacifico(
                                  fontSize: 16,
                                  color: const Color(0xFF432C1C),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '$fileCount개의 항목',
                                style: GoogleFonts.notoSans(
                                  fontSize: 14,
                                  color: Colors.brown[400],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.brown[400],
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FolderDetailScreen(
                                      folderIndex: index,
                                      folderName: folder['name'],
                                      onUpdate: () {
                                        _loadFolders();
                                      },
                                    ),
                                  ),
                                );
                              },
                              onLongPress: () => _deleteFolder(index),
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
              color: Colors.brown.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            _showCreateFolderDialog();
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
