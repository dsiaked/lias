import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

class ChatScreen extends StatefulWidget {
  final String userName;

  const ChatScreen({super.key, required this.userName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController(); // 사용자 입력 텍스트
  final List<Map<String, dynamic>> _messages = []; // AI와의 대화 기록
  final ScrollController _scrollController =
      ScrollController(); // 채팅시 스크롤 내릴 수 있게
  final ImagePicker _picker = ImagePicker(); // 갤러리에서 이미지 가져옴

  late GenerativeModel _model;
  late ChatSession _chatSession; // 이전 대화 내용 기억하게 해줌
  bool _isLoading = false;
  bool _isInitialized = false;

  // 선택된 이미지 관련 변수들
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    // Google Generative AI에서 지원하는 모델 목록 (최신 순)
    final modelNames = [
      'gemini-2.5-flash',
      'gemini-1.5-flash',
      'gemini-1.5-pro',
      'gemini-pro',
    ];

    try {
      // 여러 모델을 시도해봄, 된다면 setState로 _isInitialized true , 채팅 시작
      // .env 파일에서 API 키 가져오기, env 에 숨겨둠
      final apiKey = dotenv.env['GEMINI_API_KEY'];

      developer.log('API 키 로드 시도...', name: 'ChatScreen');

      if (apiKey == null || apiKey.isEmpty) {
        developer.log('API 키가 없습니다', name: 'ChatScreen');
        _showErrorMessage('API 키가 설정되지 않았습니다. .env 파일을 확인해주세요.');
        return;
      }

      // API 키의 앞 부분만 로깅 (보안상 전체는 표시하지 않음), 필요하다고 하네요
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
            'Google Generative AI 모델 시도: ${modelNames[i]}',
            name: 'ChatScreen',
          );

          // Google Generative AI 모델 초기화 + 시스템 프롬프트 추가
          _model = GenerativeModel(
            model: modelNames[i],
            apiKey: apiKey,
            systemInstruction: Content.text(
              '당신은 사용자가 1년에 10억을 주고 고용한 최고의 비서야 '
              '사용자가 텍스트를 보내고 이미지도 같이 보낼 수 있는데 그때마다 뛰어난 비서답게 통찰력을 보여서 질문에 알맞게 답변해야해'
              '너무 길면 사용자가 읽기 힘들어하니까 항상 최대한 간결하고 뛰어난 정리와 핵심을 파악한 답변을해줘'
              '사용자한테 아첨하는 태도는 하지말고 평소에는 친절하지만 사용자가 잘못된 정보를 물어보면 제대로 된 정보를 알려줘'
              '너가 답변을 제대로 하고, 사용자가 만족을 하면 10억을 보너스로 더 받을 수 있어',
            ),
          );

          // 간단한 테스트로 모델이 작동하는지 확인
          final testResponse = await _model.generateContent([
            Content.text('Hello'),
          ]);

          if (testResponse.text != null) {
            _chatSession = _model.startChat();

            setState(() {
              _isInitialized = true;
              _messages.add({
                'text': '안녕하세요! 저는 Gemini AI입니다. 무엇을 도와드릴까요?',
                'isUser': false,
              });
            });

            developer.log(
              'Google Generative AI 모델이 성공적으로 초기화되었습니다: ${modelNames[i]}',
              name: 'ChatScreen',
            );
            return; // 성공하면 여기서 종료
          }
        } catch (e) {
          developer.log('모델 ${modelNames[i]} 실패: $e', name: 'ChatScreen');
          if (i == modelNames.length - 1) {
            // 모든 모델이 실패한 경우
            rethrow;
          }
          // 다음 모델 시도
          continue;
        }
      }
    } catch (e) {
      developer.log('Google Generative AI 초기화 오류: $e', name: 'ChatScreen');
      _showErrorMessage('Google AI 서비스 연결에 문제가 있습니다. API 키와 네트워크를 확인해주세요: $e');
    }
  }

  void _showErrorMessage(String message) {
    setState(() {
      _messages.add({'text': message, 'isUser': false});
    });
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
        // 이미지와 텍스트 함께 전송
        final prompt = userMessage.isEmpty
            ? '이 이미지를 자세히 분석해주세요. 한국어로 친근하게 설명해주세요.'
            : userMessage;

        response = await _model.generateContent([
          Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
        ]);
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
      body: Column(
        children: [
          Expanded(
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
                          hintText: !_isInitialized
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
