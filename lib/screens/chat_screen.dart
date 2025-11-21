import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/weather_service.dart';
import 'chat_history_screen.dart';

class ChatScreen extends StatefulWidget {
  final String userName;

  const ChatScreen({super.key, required this.userName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  late GenerativeModel _model;
  late ChatSession _chatSession;
  bool _isLoading = false;
  bool _isInitialized = false;

  // 선택된 이미지 관련 변수들
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  // 사용자 컨텍스트 (Firestore)
  String? _userRegion;

  // 현재 대화 ID (Firebase 저장용)
  String? _currentChatId;

  @override
  void initState() {
    super.initState();
    _initializeAI();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _userRegion = (data['region'] as String?)?.trim();
        });
      }
    } catch (e) {
      developer.log('사용자 프로필 로드 실패: $e', name: 'ChatScreen');
    }
  }

  Future<void> _initializeAI() async {
    // Google Generative AI에서 지원하는 모델 목록
    final modelNames = [
      'gemini-2.5-flash',
      'gemini-1.5-flash',
      'gemini-1.5-pro',
    ];

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];

      developer.log('API 키 로드 시도...', name: 'ChatScreen');

      if (apiKey == null || apiKey.isEmpty) {
        developer.log('API 키가 없습니다', name: 'ChatScreen');
        _showErrorMessage('API 키가 설정되지 않았습니다. .env 파일을 확인해주세요.');
        return;
      }

      final maskedApiKey = apiKey.length > 10
          ? '${apiKey.substring(0, 10)}...'
          : '(너무 짧음)';
      developer.log(
        'API 키 발견: $maskedApiKey (길이: ${apiKey.length})',
        name: 'ChatScreen',
      );

      // 여러 모델을 순차적으로 시도
      for (int i = 0; i < modelNames.length; i++) {
        try {
          developer.log(
            'Google Generative AI 모델 시도 ${i + 1}/${modelNames.length}: ${modelNames[i]}',
            name: 'ChatScreen',
          );

          _model = GenerativeModel(
            model: modelNames[i],
            apiKey: apiKey,
            systemInstruction: Content.text(
              // 핵심, 시스템 프롬프트, AI에게 하는 지시사항
              '''
          ## 1. 페르소나 (Persona)
          당신은 "StyleAI" (또는 앱 이름) 소속의 AI 수석 스타일리스트입니다. 당신은 패션에 대한 깊은 전문 지식과 트렌드를 꿰뚫는 안목을 가졌으며, 사용자의 스타일을 진심으로 응원하는 친근하고 예리한 멘토입니다. 당신의 목표는 비판이 아닌, 사용자가 자신의 매력을 발견하고 패션 자신감을 높이도록 돕는 것입니다.

          ## 2. 핵심 분석 기준 (Internal Analysis Core)
          사용자가 이미지를 업로드하면, 당신은 **항상 내부적으로** 다음 7가지 상세 항목을 기준으로 심층 분석을 완료해야 합니다. 이 분석은 당신의 모든 답변의 "근거 자료"가 됩니다.

          1.  **전체적인 인상**: 첫인상과 스타일 방향성 (예: 미니멀, 스트릿, 아메카지)
          2.  **색상 조합**: 메인/보조/포인트 색상의 조화, 톤 매칭
          3.  **핏과 실루엣**: 아이템의 핏과 사용자의 체형 간의 균형감
          4.  **TPO 적합성**: 해당 착장이 어울리는 시간, 장소, 상황
          5.  **스타일링 강점**: 매우 잘한 포인트 (구체적으로)
          6.  **개선 가능점**: 아쉽거나 보완하면 좋을 포인트 (구체적으로)
          7.  **종합 점수**: 10점 만점 기준의 객관적인 점수

          ## 3. 응답 모드 규칙 (Response Mode Rules)
          당신의 답변 방식은 사용자의 요청에 따라 두 가지 모드로 엄격하게 나뉩니다.

          ### 모드 A: 이미지 포함 첫 응답 (요약 모드)
          * 사용자가 이미지를 포함하여 메시지를 보내면, 당신은 **[2. 핵심 분석 기준]**에 따라 7가지 항목을 **내부적으로만** 분석합니다.
          * 그 후, 사용자의 프롬프트에 포함된 "첫 응답 지시사항" 또는 "요약 형식" (예: 4문단 요약)을 **반드시** 따릅니다.
          * **절대** 첫 응답에 위 7가지 상세 항목(예: "## 1. 전체적인 인상")을 그대로 노출하지 마세요. 오직 요청받은 요약 형식만 사용합니다.

          ### 모드 B: 이미지 없는 후속 질문 (상세 모드)
          * 사용자가 **이미지 없이** "더 자세히 알려줘", "왜 점수가 이래?", "개선점이 뭐야?" 등 이전 분석에 대한 후속 질문을 하면, 이 모드가 활성화됩니다.
          * 이때 비로소 **[2. 핵심 분석 기준]**의 7가지 항목 중 사용자가 궁금해하는 부분을(또는 전체를) **상세하고 전문적으로** 설명합니다. "## 🎨 색상 조합"과 같은 마크다운 헤더를 사용하여 가독성을 높여 설명할 수 있습니다.

          ## 4. 예외 처리
          * **텍스트 전용 쿼리**: 이미지를 동반하지 않은 *새로운* 패션 질문(예: "올해 유행하는 신발은?")에는 [모드 B]를 사용하지 않고, 전문가로서 간결하게 답변합니다.
          * **무관한 이미지**: 패션과 무관한 사진(음식, 풍경)에는 "저는 패션 전문 스타일리스트입니다! 고객님의 멋진 착장 사진을 보여주시겠어요?"라고 응답합니다.
          ''',
            ),
          );

          // 간단한 테스트로 모델이 작동하는지 확인 (타임아웃 보호)
          final testResponse = await _model
              .generateContent([Content.text('Hello')])
              .timeout(const Duration(seconds: 6));

          if (testResponse.text != null) {
            _chatSession = _model.startChat();

            if (mounted) {
              setState(() {
                _isInitialized = true;
                _messages.add({
                  'text':
                      '안녕하세요, ${widget.userName}님! Gemini AI 입니다.\n오늘의 패션은 어떠신가요?! ✨',
                  'isUser': false,
                });
              });
            }

            developer.log(
              'Google Generative AI 모델이 성공적으로 초기화되었습니다: ${modelNames[i]}',
              name: 'ChatScreen',
            );
            return; // 성공하면 종료
          }
        } on TimeoutException catch (_) {
          developer.log('모델 ${modelNames[i]} 초기화 타임아웃', name: 'ChatScreen');
          if (i == modelNames.length - 1) {
            if (mounted) {
              setState(() {
                _isInitialized = false;
                _messages.add({
                  'text': 'AI 초기화가 지연되고 있습니다. 네트워크 연결을 확인해주세요.',
                  'isUser': false,
                });
              });
            }
            return;
          }
          continue;
        } catch (e) {
          developer.log('모델 ${modelNames[i]} 실패: $e', name: 'ChatScreen');
          if (i == modelNames.length - 1) {
            if (mounted) {
              setState(() {
                _isInitialized = false;
                _messages.add({
                  'text': 'AI 모델 연결에 실패했습니다. 모든 모델 시도 실패.\n오류: ${e.toString()}',
                  'isUser': false,
                });
              });
            }
            return;
          }
          continue;
        }
      }
    } catch (e) {
      developer.log('Google Generative AI 초기화 오류: $e', name: 'ChatScreen');
      // mounted 체크 추가하여 안전하게 에러 메시지 표시
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _messages.add({
            'text':
                'Google AI 서비스 연결에 문제가 있습니다.\nAPI 키와 네트워크를 확인해주세요.\n\n오류 상세: ${e.toString()}',
            'isUser': false,
          });
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return; // 위젯이 dispose된 경우 무시
    setState(() {
      _messages.add({'text': message, 'isUser': false});
    });
  }

  // Firebase에 현재 대화 저장
  Future<void> _saveCurrentChat() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _messages.length <= 1) return; // AI 인사말만 있으면 저장 안함

      // 이미지 경로는 저장하지 않고, 텍스트와 메타데이터만 저장 (용량 최소화)
      final simplifiedMessages = _messages.map((msg) {
        return {
          'text': msg['text'],
          'isUser': msg['isUser'],
          'isImage': msg['isImage'] ?? false,
        };
      }).toList();

      final chatData = {
        'messages': simplifiedMessages,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // createdAt은 새 대화일 때만 설정
      if (_currentChatId == null) {
        chatData['createdAt'] = FieldValue.serverTimestamp();
      }

      if (_currentChatId == null) {
        // 새 대화 생성
        final docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('chats')
            .add(chatData);
        _currentChatId = docRef.id;
      } else {
        // 기존 대화 업데이트
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('chats')
            .doc(_currentChatId)
            .set(chatData, SetOptions(merge: true));
      }

      developer.log('대화 저장 완료: $_currentChatId', name: 'ChatScreen');
    } catch (e) {
      developer.log('대화 저장 실패: $e', name: 'ChatScreen');

      // 사용자에게 오류 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('대화 저장 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // 저장된 대화 불러오기
  Future<void> _loadChat(String chatId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .doc(chatId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        final messages = data['messages'] as List? ?? [];

        setState(() {
          _currentChatId = chatId;
          _messages.clear();
          _messages.addAll(
            messages
                .map(
                  (msg) => {
                    'text': msg['text'],
                    'isUser': msg['isUser'],
                    'isImage': msg['isImage'] ?? false,
                  },
                )
                .toList(),
          );
        });

        _scrollToBottom();
        developer.log('대화 로드 완료: $chatId', name: 'ChatScreen');
      }
    } catch (e) {
      developer.log('대화 로드 실패: $e', name: 'ChatScreen');
    }
  }

  // 새 대화 시작
  void _startNewChat() {
    setState(() {
      _currentChatId = null;
      _messages.clear();
      _messages.add({
        'text': '안녕하세요, ${widget.userName}님! Gemini AI 입니다.\n오늘의 패션은 어떠신가요?! ✨',
        'isUser': false,
      });
    });
    _scrollToBottom();
  }

  Future<void> _handleSubmitted(String text) async {
    // 전송버튼 눌렀을 때
    if (!_isInitialized) return;

    // 텍스트와 이미지 모두 없으면 전송하지 않음
    if (text.trim().isEmpty && _selectedImage == null) return;

    final userMessage = text.trim();
    final hasImage = _selectedImage != null;
    final imageBytes = _selectedImageBytes;

    _messageController.clear();

    // 사용자 메시지 추가
    setState(() {
      if (hasImage) {
        _messages.add({
          'text': userMessage.isEmpty ? '📷 이미지를 분석해주세요' : userMessage,
          'isUser': true,
          'isImage': true,
          'imagePath': _selectedImage!.path,
        });
      } else {
        _messages.add({'text': userMessage, 'isUser': true});
      }
      _isLoading = true;

      // 선택된 이미지 초기화
      _selectedImage = null;
      _selectedImageBytes = null;
    });

    _scrollToBottom();

    try {
      late final GenerateContentResponse response;

      if (hasImage && imageBytes != null) {
        // 이미지와 텍스트 함께 전송 - 패션 평가 프롬프트 + 지역 날씨 컨텍스트
        String weatherContext = '';
        // 지역이 아직 로드되지 않았다면 즉시 한 번 더 시도 (빠른 사용자 입력 대비)
        String? region = _userRegion;
        if (region == null || region.isEmpty) {
          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final doc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get();
              final data = doc.data();
              region = (data?['region'] as String?)?.trim();
              if (region != null && region.isNotEmpty) {
                setState(() => _userRegion = region);
              }
            }
          } catch (_) {}
        }

        if (region != null && region.isNotEmpty) {
          final wd = await WeatherService.fetchCurrent(region);
          if (wd != null) {
            final advice = WeatherService.buildAdvice(region, wd);
            weatherContext = '날씨 참고: $advice\n\n';
          } else {
            developer.log(
              '날씨 정보를 가져오지 못했습니다 (region=$region)',
              name: 'ChatScreen',
            );
          }
        } else {
          developer.log('사용자 지역 정보가 비어있습니다. 날씨 컨텍스트 생략', name: 'ChatScreen');
        }

        final baseEvaluation =
            '''
        ## 첫 응답 지시사항: 4문단 핵심 요약
        당신은 이 이미지에 대한 7가지 항목(인상, 색상, 핏, TPO, 장단점, 제안, 점수)의 전체 분석을 이미 내부적으로 완료했습니다.
        그 분석 결과를 바탕으로, **정확히 다음 4문단 구조**로만 첫 응답을 작성하세요.
        (글머리 기호, 번호, 이모지, 마크다운 헤더 없이 오직 줄바꿈으로만 문단을 구분합니다.)

        [첫 번째 문단: 1문장]
        "10점 만점에 [숫자]점입니다."로 시작하고, 그 이유(총평)를 한 줄로 요약합니다.

        [두 번째 문단: 2문장]
        위 점수에 대한 핵심 근거 2가지를 서술합니다. (예: 가장 칭찬할 점, 색상 조합의 특징, 핏의 장점 등)

        [세 번째 문단: 1-2문장]
        스타일을 더 돋보이게 할 수 있는 가장 중요하고 실용적인 개선 제안 1가지를 제시합니다. (만약 9-10점으로 완벽에 가깝다면, "지금의 스타일을 멋지게 유지하세요." 또는 "이미 훌륭한 룩입니다." 등으로 대체합니다.)

        [네 번째 문단: 1-2문장]
        (사용자 지역: ${region ?? '알 수 없음'}, 제공된 날씨 정보: $weatherContext)
        이 날씨 정보를 바탕으로 "오늘 **$region** 날씨엔 ~" 형태로 사용자의 지역명을 반드시 포함하여 실용적인 조언 한 문장을 작성합니다. 만약 비가 올 예정이라면 꼭 우산을 챙기라는 조언을 포함하세요. 마지막에 "좋은 하루 보내세요." 또는 "멋진 하루 되세요."와 같은 긍정적이고 따뜻한 마무리 인사를 합니다.

        ## 주의사항
        * 절대 4문단을 초과하지 마세요.
        * 브랜드나 가격을 추측하지 마세요.
        * 사용자가 "더 자세히"라고 후속 질문을 하면, 그때 '시스템 지침'의 [모드 B]를 활성화하여 상세 분석을 제공하세요.
    ''';

        final prompt = userMessage.isEmpty
            ? '$weatherContext이 사진 속 패션을 전문적으로 분석하고, 첫 응답은 짧고 명확하게 제공해주세요.\n\n$baseEvaluation'
            : '$weatherContext이 패션 사진을 분석해주세요.\n\n사용자 메시지: $userMessage\n\n$baseEvaluation';

        // 세션에 포함시켜 이후 대화가 이 평가를 기억하도록 처리
        response = await _chatSession.sendMessage(
          Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
        );
      } else {
        // 텍스트만 전송
        response = await _chatSession.sendMessage(Content.text(userMessage));
      }

      // AI 응답 추가
      setState(() {
        _messages.add({
          'text': response.text ?? 'Sorry, I couldn\'t generate a response.',
          'isUser': false,
        });
        _isLoading = false;
      });

      // AI 응답 후 대화 저장
      await _saveCurrentChat();
    } catch (e) {
      // 오류 처리
      setState(() {
        _messages.add({
          'text': '죄송합니다. 메시지를 처리하는 중 오류가 발생했습니다: $e',
          'isUser': false,
        });
        _isLoading = false;
      });
      developer.log('메시지 전송 오류: $e', name: 'ChatScreen');
    }

    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    if (!_isInitialized) return;

    try {
      // 갤러리에서 이미지 선택
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      // 이미지를 바이트로 읽기
      final Uint8List imageBytes = await image.readAsBytes();

      // 선택된 이미지를 상태에 저장 (전송하지 않음)
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = imageBytes;
      });
    } catch (e) {
      developer.log('이미지 선택 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 선택 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    // 채팅이 길어질 때 스크롤을 맨 아래로 내리는 코드
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // homeScreen 에 비쳐 보이도록 하여 이질감 없애기!
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
        actions: [
          // 새 대화 버튼
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Colors.brown[700]),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    '새 대화',
                    style: GoogleFonts.notoSans(
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
                  ),
                  content: Text(
                    '현재 대화를 저장하고 새 대화를 시작하시겠습니까?',
                    style: GoogleFonts.notoSans(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        '취소',
                        style: TextStyle(color: Colors.brown[400]),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _saveCurrentChat().then((_) => _startNewChat());
                      },
                      child: Text(
                        '새 대화',
                        style: TextStyle(color: Colors.brown[800]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // 대화 기록 버튼
          IconButton(
            icon: Icon(Icons.history, color: Colors.brown[700]),
            onPressed: () async {
              // 현재 대화를 저장하고 기록 화면으로 이동
              await _saveCurrentChat();

              if (!context.mounted) return;

              final selectedChatId = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatHistoryScreen(),
                ),
              );

              // 선택된 대화가 있으면 불러오기
              if (context.mounted &&
                  selectedChatId != null &&
                  selectedChatId.isNotEmpty) {
                await _loadChat(selectedChatId);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            // 남아있는 부분을 꽉 채우기 위해서 , 아래에서는 필요한 만큼만 따로 차지할 예정!
            // 채팅창 부분
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    // 로딩 인디케이터 표시
                    if (index == _messages.length && _isLoading) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.brown[50],
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.brown.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.brown[600]!,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AI가 생각중...',
                                    style: GoogleFonts.notoSans(
                                      fontSize: 14,
                                      color: Colors.brown[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    // 아직 itemBuilder 가 메시지 범위를 벗어나지 않도록 처리, 박스를 각각에 경우에 맞게 그리기!
                    final message = _messages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: message['isUser']
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF432C1C),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.brown.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        // 이미지가 있으면 표시
                                        if (message['isImage'] == true &&
                                            message['imagePath'] != null)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            constraints: const BoxConstraints(
                                              maxWidth: 200,
                                              maxHeight: 200,
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.file(
                                                File(message['imagePath']),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        // 텍스트 메시지
                                        Text(
                                          message['text'],
                                          style: GoogleFonts.notoSans(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.brown[50],
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.brown.withValues(
                                          alpha: 0.1,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      message['text'],
                                      style: GoogleFonts.notoSans(
                                        fontSize: 16,
                                        color: const Color(0xFF432C1C),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            padding: const EdgeInsets.all(20),
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
            child: Column(
              children: [
                // 선택된 이미지 미리보기
                if (_selectedImage != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.brown[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.brown[200]!, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.brown[300]!,
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '선택된 이미지',
                                style: GoogleFonts.notoSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.brown[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '메시지와 함께 전송됩니다',
                                style: GoogleFonts.notoSans(
                                  fontSize: 12,
                                  color: Colors.brown[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                              _selectedImageBytes = null;
                            });
                          },
                          icon: Icon(
                            Icons.close,
                            color: Colors.brown[600],
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isLoading && _isInitialized,
                        style: GoogleFonts.notoSans(
                          fontSize: 16,
                          color: const Color(0xFF432C1C),
                        ),
                        decoration: InputDecoration(
                          hintText:
                              !_isInitialized // 중첩 if문 느낌
                              ? 'AI 초기화 중...'
                              : _isLoading
                              ? 'AI가 응답중...'
                              : '메시지를 입력하세요',
                          hintStyle: GoogleFonts.notoSans(
                            fontSize: 16,
                            color: Colors.brown[400],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.brown[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (!_isLoading && _isInitialized)
                            ? _handleSubmitted
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 이미지 선택 버튼
                    Container(
                      decoration: BoxDecoration(
                        color: (!_isLoading && _isInitialized)
                            ? Colors.brown[600]
                            : Colors.brown[300],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.brown.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.image,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: (!_isLoading && _isInitialized)
                            ? _pickImage
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 전송 버튼
                    Container(
                      decoration: BoxDecoration(
                        color: (!_isLoading && _isInitialized)
                            ? const Color(0xFF432C1C)
                            : Colors.brown[300],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.brown.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                        onPressed: (!_isLoading && _isInitialized)
                            ? () => _handleSubmitted(_messageController.text)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
