import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FolderDetailScreen extends StatefulWidget {
  final String folderId;
  final String folderName;

  const FolderDetailScreen({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  List<Map<String, dynamic>> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  // Firestore에서 파일 데이터 불러오기
  Future<void> _loadFiles() async {
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
          .doc(widget.folderId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _files = List<Map<String, dynamic>>.from(data?['files'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('파일을 불러오는 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Firestore에 파일 데이터 저장하기
  Future<void> _saveFiles() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('folders')
          .doc(widget.folderId)
          .update({'files': _files, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('파일 저장 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 새 파일 생성 다이얼로그
  void _showCreateFileDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '새 파일 만들기',
            style: GoogleFonts.notoSans(
              fontWeight: FontWeight.bold,
              color: Colors.brown[800],
            ),
          ),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(
              hintText: '파일 이름을 입력하세요',
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
                    _files.add({
                      'name': textController.text,
                      'content': '',
                      'createdAt': DateTime.now().toIso8601String(),
                    });
                    _saveFiles();
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

  // 파일 삭제
  void _deleteFile(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '파일 삭제',
            style: GoogleFonts.notoSans(
              fontWeight: FontWeight.bold,
              color: Colors.brown[800],
            ),
          ),
          content: Text(
            '${_files[index]['name']} 파일을 삭제하시겠습니까?',
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
                  _files.removeAt(index);
                  _saveFiles();
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
      backgroundColor: const Color(0xFFFAF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown[800]),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          widget.folderName,
          style: GoogleFonts.pacifico(
            fontSize: 24,
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
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: Colors.brown[600]),
                )
              : _files.isEmpty
              ? Center(
                  child: Text(
                    '파일이 없습니다\n하단 버튼을 눌러 파일을 만드세요',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      color: Colors.brown[400],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
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
                            Icons.description,
                            color: Colors.brown[600],
                            size: 24,
                          ),
                        ),
                        title: Text(
                          file['name'],
                          style: GoogleFonts.notoSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF432C1C),
                          ),
                        ),
                        subtitle: Text(
                          file['content'].toString().isEmpty
                              ? '내용 없음'
                              : '${file['content'].toString().length}자',
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
                              onPressed: () => _deleteFile(index),
                              tooltip: '파일 삭제',
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.brown[400],
                            ),
                          ],
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FileEditorScreen(
                                fileName: file['name'],
                                initialContent: file['content'],
                                onSave: (content) {
                                  setState(() {
                                    _files[index]['content'] = content;
                                    _saveFiles();
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
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
          onPressed: _showCreateFileDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.note_add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

// 파일 에디터 화면
class FileEditorScreen extends StatefulWidget {
  final String fileName;
  final String initialContent;
  final Function(String) onSave;

  const FileEditorScreen({
    super.key,
    required this.fileName,
    required this.initialContent,
    required this.onSave,
  });

  @override
  State<FileEditorScreen> createState() => _FileEditorScreenState();
}

class _FileEditorScreenState extends State<FileEditorScreen> {
  late TextEditingController _contentController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent);
    _contentController.addListener(() {
      if (!_hasChanges) {
        setState(() {
          _hasChanges = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _saveContent() {
    widget.onSave(_contentController.text);
    setState(() {
      _hasChanges = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('저장되었습니다', style: GoogleFonts.notoSans()),
        backgroundColor: Colors.brown[600],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
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
          widget.fileName,
          style: GoogleFonts.notoSans(
            fontSize: 18,
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
            onPressed: _hasChanges ? _saveContent : null,
          ),
        ],
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
          child: TextField(
            controller: _contentController,
            maxLines: null,
            expands: true,
            style: GoogleFonts.notoSans(
              fontSize: 16,
              color: const Color(0xFF432C1C),
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: '여기에 내용을 작성하세요...',
              hintStyle: GoogleFonts.notoSans(
                fontSize: 16,
                color: Colors.brown[300],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
      ),
    );
  }
}
