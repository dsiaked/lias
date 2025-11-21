import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key});

  String _generateChatPreview(List messages) {
    if (messages.isEmpty) return '새 대화';

    // 첫 번째 사용자 메시지 찾기
    for (var msg in messages) {
      if (msg['isUser'] == true) {
        String text = msg['text'] ?? '';
        if (text.isNotEmpty) {
          return text.length > 30 ? '${text.substring(0, 30)}...' : text;
        }
      }
    }
    return '새 대화';
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '오늘 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '어제';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  Future<void> _deleteChat(BuildContext context, String chatId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '대화 삭제',
          style: GoogleFonts.notoSans(
            fontWeight: FontWeight.bold,
            color: Colors.brown[800],
          ),
        ),
        content: Text(
          '이 대화를 삭제하시겠습니까?\n삭제된 대화는 복구할 수 없습니다.',
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
      ),
    );

    if (shouldDelete == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('chats')
              .doc(chatId)
              .delete();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('대화가 삭제되었습니다'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 중 오류가 발생했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
          '대화 기록',
          style: GoogleFonts.notoSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown[800],
          ),
        ),
        centerTitle: true,
      ),
      body: user == null
          ? Center(
              child: Text(
                '로그인이 필요합니다',
                style: GoogleFonts.notoSans(color: Colors.brown[400]),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('chats')
                  .orderBy('updatedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '오류가 발생했습니다',
                      style: GoogleFonts.notoSans(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: Colors.brown[600]),
                  );
                }

                final chats = snapshot.data?.docs ?? [];

                if (chats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.brown[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          '저장된 대화가 없습니다',
                          style: GoogleFonts.notoSans(
                            fontSize: 16,
                            color: Colors.brown[400],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final data = chat.data() as Map<String, dynamic>;
                    final messages = data['messages'] as List? ?? [];
                    final preview = _generateChatPreview(messages);
                    final timestamp = data['updatedAt'] as Timestamp?;

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.brown.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.brown[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.chat,
                            color: Colors.brown[600],
                            size: 24,
                          ),
                        ),
                        title: Text(
                          preview,
                          style: GoogleFonts.notoSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.brown[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _formatTimestamp(timestamp),
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            color: Colors.brown[400],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${messages.length}',
                              style: GoogleFonts.notoSans(
                                fontSize: 12,
                                color: Colors.brown[400],
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.message,
                              size: 16,
                              color: Colors.brown[400],
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red[400],
                                size: 20,
                              ),
                              onPressed: () => _deleteChat(context, chat.id),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context, chat.id);
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
