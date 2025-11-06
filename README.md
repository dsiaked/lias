# 🎨 LIAS - AI 패션 스타일리스트 앱

> **L**ife **I**ntelligent **A**ssistant **S**tylist  
> AI 기반 패션 코디 평가 및 개인화된 스타일 조언을 제공하는 Flutter 모바일 애플리케이션

**개발자**: 김예중 (24101194)  
**개발 기간**: 2025.09.26 ~ 2025.11.06  
**GitHub**: https://github.com/dsiaked/lias  
**라이센스**: [MIT License](https://github.com/dsiaked/lias/blob/main/LICENSE)

---

## 📋 목차

1. [프로젝트 개요](#-프로젝트-개요)
2. [앱 사용 흐름](#-앱-사용-흐름)
3. [사용된 기술](#-사용된-기술)
4. [주요 파일 분석](#-주요-파일-분석)
5. [개발 회고](#-개발-회고)
6. [참고 자료](#-참고-자료)

---

## 🎯 프로젝트 개요

### 배경
저는 매일 아침 "오늘은 무엇을 입을까?"라는 고민을 합니다. 또 매번 입을 때마다 "오늘 패션이 괜찮을까?" 라는 걱정을 가진 채 집 밖을 나갑니다. 그러나 집 밖을 나왔을 때는 이미 늦었습니다. 그날 하루종일 그 옷을 입어야 하고, 다른 사람들이 패션이 별로라 해도 집 밖에선 Hot Reloading을 할 수 없습니다.

LIAS는 이러한 일상적인 고민에 AI 기술을 접목하여, 집 밖을 나가기 전에 사용자 각각에 취향에 맞추고, 패션을 객관적으로 평가함으로써 이러한 상황을 방지하고, 그 뿐만이 아니라 진짜 "비서"처럼 날씨체크, 대화 등을 할 수 있게 함으로써 사용자에게 자신감 있는 하루를 시작할 수 있도록 돕는 **인생 비서(LIAS)**입니다.

### 핵심 가치
- **개인화된 조언**: 지역, 성별, 선호 색상을 고려한 맞춤형 피드백
- **날씨 기반 제안**: 실시간 날씨를 반영한 실용적인 스타일링 및 비서의 역할 수행
- **전문가 수준 평가**: 7가지 평가 기준을 바탕으로 한 Google Gemini AI의 심층 분석
- **대화형 AI**: 후속 질문으로 상세한 설명 제공

---

## 📱 앱 사용 흐름

### 1. 로그인 / 회원가입
앱을 실행하면 **로그인 화면**에서 시작합니다. Firebase Authentication을 통해 이메일/비밀번호로 가입하거나 로그인합니다.

<사진필요>
*로그인 화면*

---

### 2. 온보딩 (첫 사용자)
"처음" 로그인한 사용자는 **온보딩 화면**으로 이동합니다. 여기서 다음 정보를 입력합니다:
- **성별** (남성/여성/기타)
- **지역** (예: 서울, 부산)
- **선호 색상** (8가지 색상 중 선택)

이 정보는 AI가 개인화된 조언을 제공하는 데 사용됩니다. 모든 정보를 입력해야 메인 화면으로 진입할 수 있습니다.

<사진필요>
*온보딩 화면*

---

### 3. AI 초기화
온보딩 완료 후, 백그라운드에서 **Google Gemini AI 모델**이 초기화됩니다. 다음 모델을 시도합니다:
`gemini-2.5-flash`

---

### 4. 메인 화면 (바텀 네비게이션)
메인 화면은 **4개의 바텀 네비게이션**으로 구성됩니다, 4개의 구성은 다음과 같습니다:

#### 1 - 📸 Chats (AI 채팅)
- **갤러리에서 패션 사진 선택** → AI가 실시간으로 분석
- **4문단 요약 평가** 제공:
  1. 10점 만점 점수 + 이유
  2. 핵심 강점 2문장
  3. 개선 제안 1-2문장
  4. 날씨 기반 조언 + 응원 메시지
- **후속 질문 가능**: "더 자세히 알려줘" 등 자유로운 대화

**날씨 통합**: 사용자 지역의 실시간 날씨를 OpenWeather API로 조회하여, "오늘 **서울** 날씨엔 가벼운 니트가 좋아요"처럼 자연스럽게 조언합니다.

<사진필요>
*AI 채팅 화면*

---

#### 2 - 📅 Calendar (메모)
- **월간 달력 뷰**로 날짜별 메모 작성
- 패션 아이디어, 코디 계획 등을 기록
- SharedPreferences에 로컬 저장
- 의도 : 날짜별 점수와 피드백을 체크하면서 발전해가는 사용자 본인의 모습을 확인 가능함.

<사진필요>
*캘린더 화면*

---

#### 3 - 📁 Folder (파일 관리)
- **폴더 생성/삭제** 기능
- 각 폴더 안에 **파일 생성/수정/삭제**
- 의도 : 일기장으로 활용을 하거나, 필요한 패션 아이템 등을 메모할 수 있게, 또 정말 다양한 메모를 간편하게 할 수 있게

<사진필요>
*폴더 관리 화면*

---

#### 4 - 👤 Profile (프로필)
- **프로필 이미지**: 갤러리에서 선택
- **이름 수정**: 다이얼로그로 변경
- **내 정보 수정**: 성별, 지역, 선호 색상 업데이트
- Firestore와 실시간 동기화

<사진필요>
*프로필 화면*

---

## 🛠 사용된 기술(간단하게)

### 1. Flutter & Dart
앱을 개발하기 편리한 엔진인 **Flutter**와 그 언어 Dart를 사용하였습니다.

---

### 2. Firebase
**Firebase**는 Google의 백엔드 서비스 플랫폼입니다. 서버 구축 없이 인증(Auth), 데이터베이스(DB), AI API키 관리에 기능들을 제공합니다.

#### Cloud Firestore
- NoSQL 문서 기반 데이터베이스
- 사용자 프로필 정보 저장 (이름, 성별, 지역, 선호 색상)
- 실시간 동기화로 다중 기기 간 데이터 일관성 보장
- **보안 규칙**: 본인만 자신의 데이터를 읽고 쓸 수 있도록 설정

---

### 3. AI API Key, 
Google Cloud 를 통해 Gemini API 키를 발급받아 사용하였습니다.

#### System Instruction
이미 학습이 완료가 된 Gemini 를 제가 원하는 방향대로 대답을 하게 하기 위해 파인튜닝? 같은 느낌으로 가볍게 행동 명령 지침서 정도로만 학습을 시켰습니다.

#### 세션 기반 대화
`startChat()`으로 세션을 시작하면, 이전 대화 내용을 기억합니다. 이미지 평가 후 "더 자세히 알려줘"라고 물어도 AI가 컨텍스트를 유지합니다.

---

### 4. OpenWeather API
전 세계 날씨 데이터를 제공하는 무료 API인 **OpenWeather**애서 날씨 정보를 받아왔습니다.

사용자가 입력한 지역에 대한 정보에 비 예보가 있으면 자동으로 우산 추천을 추가합니다.

---

### 5. SharedPreferences
로컬 저장소로 데이터를 저장합니다, Firestore와 함께 사용을 함으로써 데이터들을 알맞게 필요한 위치에 저장하였습니다.

---

### 6. 기타 패키지

#### UI/UX
- `google_fonts`: 브랜드 폰트 (Pacifico, Noto Sans)
- `font_awesome_flutter`: 아이콘
- `table_calendar`: 월간 캘린더
- `flutter_chat_bubble`: 채팅 UI

#### 유틸리티
- `flutter_dotenv`: 환경 변수 관리 (.env 파일, 보안상 API키 저장을 위해)
- `image_picker`: 갤러리에서 이미지 선택
- `http`: HTTP 요청 (날씨 API)
- `intl`: 날짜 포맷팅

---

## 📂 주요 파일 분석

### 1. `lib/main.dart` - 앱 진입점

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // .env 파일 로드 (API 키)
  await dotenv.load(fileName: '.env');
  
  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  runApp(const MyApp());
}
```

**역할**: 앱 시작 시 Firebase와 환경 변수를 초기화합니다.

---

### 2. `lib/screens/login_screen.dart` - 로그인

```dart
Future<void> _login() async {
  final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: _emailController.text.trim(),
    password: _passwordController.text.trim(),
  );
  
  // Firestore에서 사용자 정보 확인
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userCredential.user!.uid)
      .get();
  
  // 온보딩 정보 누락 시 온보딩 화면으로
  if (doc.exists && (doc.data()?['gender'] == null || ...)) {
    Navigator.pushReplacement(context, WelcomeOnboardingScreen(...));
  } else {
    Navigator.pushReplacement(context, HomeScreen(...));
  }
}
```

**핵심 로직**: 로그인 후 Firestore에서 사용자 정보를 확인하고, 온보딩 완료 여부에 따라 다른 화면으로 이동합니다.

---

### 3. `lib/screens/welcome_onboarding_screen.dart` - 온보딩

```dart
Future<void> _completeOnboarding() async {
  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    ~~
    ~~
    ~~
  }, SetOptions(merge: true));
  
  Navigator.pushReplacement(context, HomeScreen(...));
}
```

**핵심 로직**: 키 값에 형태로 사용자가 입력한 정보를 Firebase Database 에 저장합니다

---

### 4. `lib/screens/chat_screen.dart` - AI 채팅 (핵심)

#### AI 초기화
```dart
Future<void> _initAI() async {
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  final models = ['gemini-2.5-flash', 'gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-pro'];
  
  for (var modelName in models) {
    try {
      _model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        systemInstruction: Content.text('당신은 AI 수석 스타일리스트입니다...'),
      );
      
      // 6초 타임아웃으로 초기화 테스트
      await _model.generateContent([Content.text('Hello')])
          .timeout(const Duration(seconds: 6));
      
      _chatSession = _model.startChat();
      break;
    } catch (e) {
      continue; // 다음 모델 시도
    }
  }
}
```

**핵심**: 모델을 시도합니다.

---

#### 이미지 분석 + 날씨 통합
```dart
Future<void> _sendImageWithText(File imageFile, String userText) async {
  // 1. 지역 정보 로드
  String? region = _userRegion;
  if (region == null || region.isEmpty) {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    region = doc.data()?['region'];
  }
  
  // 2. 날씨 조회
  String weatherContext = '';
  if (region != null) {
    final weatherData = await WeatherService.fetchCurrent(region);
    if (weatherData != null) {
      weatherContext = '날씨 참고: ${WeatherService.buildAdvice(region, weatherData)}\n\n';
    }
  }
  
  // 3. 프롬프트 생성
  final prompt = '''
$weatherContext이 패션 사진을 분석해주세요.
(사용자 지역: $region)
"오늘 **$region** 날씨엔 ~" 형태로 작성...
''';
  
  // 4. 이미지 + 텍스트 전송
  final imageBytes = await imageFile.readAsBytes();
  final response = await _chatSession.sendMessage(
    Content.multi([
      TextPart(prompt),
      DataPart('image/jpeg', imageBytes),
    ]),
  );
  
  setState(() {
    _messages.add(ChatMessage(text: response.text, isUser: false));
  });
}
```

**핵심**: 
1. Firestore에서 사용자 지역 조회
2. OpenWeather API로 실시간 날씨 조회
3. 날씨 정보를 프롬프트에 주입
4. 이미지와 텍스트를 세션에 전송하여 컨텍스트 유지

---

### 5. `lib/services/weather_service.dart` - 날씨 서비스

```dart
static Future<WeatherData?> fetchCurrent(String region) async {
  final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
  
  // 1차: 입력 그대로
  var result = await _byCity(region, apiKey);
  if (result != null) return result;
  
  // 2차: 한글이면 국가 코드 추가
  if (_containsNonAscii(region) && !region.contains(',')) {
    result = await _byCity('$region,KR', apiKey);
    if (result != null) return result;
  }
  
  // 3차: Geocoding으로 좌표 변환
  final geoResp = await http.get(
    Uri.parse('$_geoUrl?q=$region&limit=1&appid=$apiKey'),
  ).timeout(Duration(seconds: 4));
  
  final geoData = jsonDecode(geoResp.body) as List;
  if (geoData.isNotEmpty) {
    final lat = geoData[0]['lat'];
    final lon = geoData[0]['lon'];
    return await _byCoord(lat, lon, apiKey);
  }
  
  return null; // 모두 실패
}
```

**핵심**: 3단계 fallback으로 한글 지역명도 정확하게 처리합니다.

---

#### 날씨 기반 조언 생성
```dart
static String buildAdvice(String region, WeatherData wd) {
  final t = wd.temperature;
  String comfort;
  
  if (t >= 28) {
    comfort = '꽤 덥습니다. 통기성 좋은 소재와 밝은 톤을 추천해요.';
  } else if (t >= 23) {
    comfort = '약간 덥습니다. 반소매나 가벼운 아우터면 충분해요.';
  } else if (t >= 18) {
    comfort = '선선합니다. 가벼운 니트나 얇은 아우터가 좋아요.';
  } else if (t >= 12) {
    comfort = '쌀쌀합니다. 가벼운 코트나 재킷이 필요해요.';
  } else if (t >= 5) {
    comfort = '춥습니다. 보온성 있는 아우터를 꼭 챙기세요.';
  } else {
    comfort = '매우 춥습니다. 두꺼운 코트와 보온 액세서리가 필수예요.';
  }
  
  final rainNote = wd.willRain ? ' 비 소식이 있어요. 우산을 꼭 챙겨주세요.' : '';
  
  return '오늘 $region은 약 ${t}°C, "${wd.description}" 입니다. $comfort$rainNote';
}
```

**핵심**: 온도 구간별로 적절한 조언을 자동 생성하고, 비 예보 시 우산 추천을 추가합니다.

---

### 6. `lib/screens/profile_screen.dart` - 프로필

#### Firestore vs SharedPreferences 전략
```dart
Future<void> _loadProfile() async {
  // Firestore에서 이름 로드 (다중 기기 동기화)
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  
  if (doc.exists) {
    setState(() {
      _userName = doc.data()?['userName'] ?? '사용자';
    });
  }
  
  // SharedPreferences에서 이미지 경로 로드 (로컬 파일)
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _profileImagePath = prefs.getString('profile_image_path');
  });
}
```

**핵심**: 
- **이름**은 Firestore에 저장하여 다른 기기에서도 동일한 이름 사용
- **이미지 경로**는 로컬 파일 시스템 경로이므로 SharedPreferences에 저장

---

### 7. `.gitignore` - 보안

```gitignore
# 환경 변수
.env

# Firebase 구성
/lib/firebase_options.dart
/android/app/google-services.json
/ios/Runner/GoogleService-Info.plist

# Android 서명
android/key.properties
**/*.keystore
**/*.jks

# Firebase 서비스 계정
**/*serviceAccount*.json
**/firebase-adminsdk-*.json
```

**핵심**: API 키, Firebase 설정을 위한 키, 서명 키 등 민감한 정보를 Git에 올리지 않습니다.

---

## 💭 개발 회고

### 느낀 점

#### 1. API 를 가져와서 하는 앱 개발
AI, Weather API 키를 가져와서 앱을 개발하려는 시도를 처음 해봤는데 생각보다 고려할것이 많았고, 완전 새로운 위젯들, 방법들도 많이 배울 수 있는 시간이었고, 여러 API 들을 가져와서 코딩을 할 때 수준이 높은 , 완성도가 높은 앱이 만들어지는 경험을 할 수 있었습니다.


#### 2. Firebase의 편리함
서버를 직접 구축하지 않고도 **인증, 데이터베이스, 실시간 동기화**를 구현할 수 있었던 점이 너무나도 편리했습니다. 특히 Firestore의 `SetOptions(merge: true)`로 기존 데이터를 보존하면서 업데이트하는 기능이 유용했습니다.

#### 3. 사용자 경험의 중요성
초기에는 AI가 패션에 평가기준 7가지 항목에 맞게 모두 나열했는데, 사용자 테스트 결과 **정보 과부하**로 피로감을 느낀다는 피드백을 받았습니다. 그래서 4문단 요약만 제공하고, 원하면 자세한 설명을 듣도록 변경했습니다. **"적을수록 좋다"**는 UX 원칙을 실감했습니다.
추가로 AI 응답 형태를 디테일하게 지시를 내려주면서 어떤 방향으로 학습을 시켜야 하는지를 조금이나마 경험할 수 있는 시간이었습니다.

---

### 어려웠던 점

#### 1. 보안 관련 문제점
오픈소스로 깃허브에 public 으로 대형 프로젝트를 push 하는 일이 처음이라 보안 관련 생각을 크게 못한점이 많이 아쉬웠습니다. 
AI API 키를 .env 파일에 저장을 하는것 뿐만이 아닌 push 할 때 .env 파일까지 같이 올라갈 것을 염두에 두고, gitignore에 env 파일을 추가해줬어야 했는데 그 방법을 알지 못했습니다. 그래서 AI API 정보를 담고있는 .env 파일이 github 에 public 으로 올라가게 되었고, 다른 사람이 GEMINI_API_KEY 를 검색해서 들어왔는지 제 API키로 막대한 사용을 하였고, 치킨 5마리 값에 금액을 청구받았습니다. ㅠㅠ
이 사건을 통해 많은 것을 배웠고, 오픈 소스로 올릴 때에 주의점들을 느낄 수 있었습니다. 

추가로 Firebase Database 에 권한에 관련해서 규칙을 설정하는데에도 보안이 사용되는 만큼 다양한 종류에 보안을 신경써줘야 한다는 부분을 알게 되었습니다.

---

#### 2. Flutter 코드 
특히 chat screen 관련 코드를 할 때 많이 느낀 부분인데, 코드를 작성하기 전에 여러 조건에 맞는 각각에 UI들을 어떻게 디자인 해야할 지에 대해서 미리 생각을 하고 코드를 시작하는 것에 중요성을 느낄 수 있는 시간이었습니다. 
특히 삼항연산자를 적절하게 사용을 해줌으로써 chat Screen 파일같은 경우에는 채팅을 치는것이 AI인지 사용자인지, 사진을 포함한 텍스트인지 아닌지 등등에 따라 많은 코드가 각각 나뉘어진다는 것을 느꼈고, 앞으로도 다양한 파일들을 코딩할 때에 이러한 경우들을 미리 생각을 해주고 코딩을 시작하면 많은 시간을 세이브할 수 있겠다는 생각을 할 수 있었습니다

---

#### 3. 한글 지역명 처리
OpenWeather API는 영문 지역명을 기본으로 하기 때문에, "서울"을 입력하면 찾지 못했습니다. 다음 전략으로 해결했습니다:
1. 입력 그대로 시도
2. 국가 코드 추가 ("서울,KR")
3. Geocoding API로 좌표 변환

덕분에 한글 지역명도 정확하게 처리할 수 있었습니다.

---

#### 4. SharedPreferences vs Firestore 혼용
처음에는 프로필 이름을 SharedPreferences에 저장했는데, 다른 기기에서 로그인하면 Firestore의 이름이 다시 덮어씌워지는 문제가 있었습니다. 두 개의 다른 저장방법을 적절히 같이 사용을 하는 좋은 경험을 할 수 있었습니다.

**교훈**: 
- **다중 기기 동기화가 필요한 데이터**는 Firestore
- **로컬 파일 경로**는 SharedPreference
였으나... 같은 기기 내에서 다른 계정으로 로그인을 하게 된다면 폴더에 내용이 그대로 남아있는 불편함이 있었음
 -> Firebase Migration 으로 전체 folder_screen 파일을 수정을 하였음

---

### 앞으로의 도전

- 가장 아쉬웠던 점은 시간상 커뮤니티에 대한 기능을 구현하지 못한 부분이 아쉬웠습니다. 각자 자신들에 패션과 이에따른 AI 비서에 평가를 커뮤니티에 올리고 서로 도움을 주며 AI 뿐만이 아닌 다른 사람들에 시각도 반영을 함으로써 패션에 많은 도움이 될 수 있게 코딩을 한다면 더욱 좋은 앱이 될 것이라 생각이 되고, 방학을 한 이후에 도전을 해보려 합니다!

- 두번째로 아쉬웠던 점은 처음에 기획을 할 때에는 TensorFlow , Python 등을 통해 미리 어느정도 학습이 되어있는 AI를 가져와 강화학습과 파인튜닝을 해줌으로써 챗봇에 포함을 시키고자 하였으나, 전문 지식이 없는 상황에 시간은 많지 않았고, 어쩔 수 없이 일단 대중화된 AI를 가져왔습니다. 나중에 시간이 된다면 꼭 직접 학습을 시킨 AI를 사용해보고 싶다는 생각을 하였습니다!

- 마지막으로 아쉬웠던 점은 기존에는 각각에 계정에 맞게 모든 AI와의 대화를 Firebase Database 에 저장을 하려 했으나 대화가 너무나 많은 저장공간을 잡아먹어 이번에는 하지 못하였고, 나중에 상업화를 한다면 이러한 Firebase 저장소가 아닌 직접 데이터베이스를 SQL 을 통해 만들고 관리 및 저장을 해보고싶다는 생각을 하게 되었습니다

---

## 📚 참고 자료

### 공식 문서
- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Google Generative AI API](https://ai.google.dev/docs)
- [OpenWeather API](https://openweathermap.org/api)

### 튜토리얼
- [Firebase AI Logic 시작하기](https://firebase.google.com/docs/ai-logic/get-started?hl=ko)
- [Flutter Chat UI 구현](https://www.youtube.com/watch?v=aBNZvkj-YpE)
- [Gemini 프롬프트 엔지니어링](https://ai.google.dev/docs/prompt_best_practices)

### 주요 패키지
- [google_generative_ai](https://pub.dev/packages/google_generative_ai) - Gemini AI SDK
- [firebase_core](https://pub.dev/packages/firebase_core) - Firebase 초기화
- [firebase_auth](https://pub.dev/packages/firebase_auth) - 인증
- [cloud_firestore](https://pub.dev/packages/cloud_firestore) - 데이터베이스
- [table_calendar](https://pub.dev/packages/table_calendar) - 캘린더 UI
- [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) - 환경 변수

---

## 📄 라이센스

이 프로젝트는 **MIT License** 하에 배포됩니다.  
자세한 내용은 [LICENSE](https://github.com/dsiaked/lias/blob/main/LICENSE) 파일을 참조하세요.

---

## 👨‍💻 개발자 정보

**이름**: 김예중  
**학번**: 24101194  
**GitHub**: [@dsiaked](https://github.com/dsiaked)

---
