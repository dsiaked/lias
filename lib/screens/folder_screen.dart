import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'folder_detail_screen.dart';

class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  List<Map<String, dynamic>> _folders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  // Firestore에서 폴더 데이터 불러오기
  Future<void> _loadFolders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('folders')
          .orderBy('createdAt', descending: false)
          .get();

      if (doc.docs.isEmpty) {
        // 초기 Diary 폴더 생성
        await _createInitialFolder();
      } else {
        setState(() {
          _folders = doc.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'],
              'files': data['files'] ?? [],
              'createdAt': data['createdAt'],
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('폴더를 불러오는 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 초기 Diary 폴더 생성
  Future<void> _createInitialFolder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final docRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('folders')
        .add({
          'name': 'Diary',
          'files': [],
          'createdAt': FieldValue.serverTimestamp(),
        });

    setState(() {
      _folders = [
        {
          'id': docRef.id,
          'name': 'Diary',
          'files': [],
          'createdAt': DateTime.now(),
        },
      ];
      _isLoading = false;
    });
  }

  // Firestore에 새 폴더 저장하기
  Future<void> _saveFolder(String folderName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }

      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('folders')
          .add({
            'name': folderName,
            'files': [],
            'createdAt': FieldValue.serverTimestamp(),
          });

      setState(() {
        _folders.add({
          'id': docRef.id,
          'name': folderName,
          'files': [],
          'createdAt': DateTime.now(),
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('폴더 생성 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                  _saveFolder(textController.text);
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
  void _deleteFolder(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
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
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('취소', style: TextStyle(color: Colors.brown[400])),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('삭제', style: TextStyle(color: Colors.red[600])),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final folderId = _folders[index]['id'];
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('folders')
              .doc(folderId)
              .delete();

          if (mounted) {
            setState(() {
              _folders.removeAt(index);
            });
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('폴더 삭제 중 오류가 발생했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.brown[600],
                        ),
                      )
                    : _folders.isEmpty
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
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red[400],
                                      size: 20,
                                    ),
                                    onPressed: () => _deleteFolder(index),
                                    tooltip: '폴더 삭제',
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.brown[400],
                                  ),
                                ],
                              ),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FolderDetailScreen(
                                      folderId: folder['id'],
                                      folderName: folder['name'],
                                    ),
                                  ),
                                );
                                // 돌아왔을 때 폴더 목록 새로고침
                                if (result == true && mounted) {
                                  _loadFolders();
                                }
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
