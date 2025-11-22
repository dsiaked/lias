import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CalendarScreen extends StatefulWidget {
  final String userName;

  const CalendarScreen({super.key, required this.userName});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  // 메모를 저장할 Map 추가
  final Map<DateTime, List<String>> _memos = {};

  // 날짜 비교를 위한 helper 함수
  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void initState() {
    super.initState();
    _loadMemos(); // 앱 시작시 메모 불러오기
  }

  // 메모 저장 함수
  Future<void> _saveMemos() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedMemos = json.encode(
      _memos.map((key, value) => MapEntry(key.toString(), value)),
    );
    await prefs.setString('calendar_memos', encodedMemos);
  }

  // 메모 불러오기 함수
  Future<void> _loadMemos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedMemos = prefs.getString('calendar_memos');
    if (encodedMemos != null) {
      final Map<String, dynamic> decoded = json.decode(encodedMemos);
      setState(() {
        _memos.clear();
        decoded.forEach((key, value) {
          final date = DateTime.parse(key);
          _memos[date] = List<String>.from(value);
        });
      });
    }
  }

  // 메모 추가 다이얼로그를 보여주는 함수
  void _showMemoDialog(DateTime day) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '${day.year}년 ${day.month}월 ${day.day}일',
            style: GoogleFonts.notoSans(
              fontWeight: FontWeight.bold,
              color: Colors.brown[800],
            ),
          ),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(
              hintText: '메모를 입력하세요',
              hintStyle: TextStyle(color: Colors.brown[300]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.brown[400]!),
              ),
            ),
            maxLines: 3,
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
                    if (_memos[day] == null) {
                      // 메모장에 아무런 예전 메모가 없을 때
                      _memos[day] = []; // 새로운 메모장을 담을 공간을 만든다
                    }
                    _memos[day]!.add(
                      textController.text,
                    ); // 이후 그 메모장 안에 text 집어넣으면 끝!
                    _saveMemos(); // 메모 추가시 저장
                  });
                }
                Navigator.pop(context);
              },
              child: Text('저장', style: TextStyle(color: Colors.brown[800])),
            ),
          ],
        );
      },
    );
  }

  // 메모 리스트를 보여주는 함수
  void _showMemoList(DateTime day) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${day.year}년 ${day.month}월 ${day.day}일의 메모',
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
              ),
              const SizedBox(height: 16),
              if (_memos[day]?.isEmpty ?? true)
                Center(
                  child: Text(
                    '메모가 없습니다',
                    style: TextStyle(color: Colors.brown[400]),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _memos[day]?.length ?? 0,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.brown[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(_memos[day]![index]),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.brown[300]),
                            onPressed: () {
                              setState(() {
                                _memos[day]?.removeAt(index);
                                if (_memos[day]?.isEmpty ?? false) {
                                  _memos.remove(day);
                                }
                                _saveMemos(); // 메모 삭제시 저장
                              });
                              Navigator.pop(context);
                              _showMemoList(day); // 리스트 다시 표시
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showMemoDialog(day);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('새 메모 추가'),
                ),
              ),
            ],
          ),
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
        title: Text(
          '${widget.userName}\'s Calendar',
          style: GoogleFonts.pacifico(
            fontSize: 28,
            color: const Color(0xFF432C1C),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 달력 섹션
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2021, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay, // 월을 바꿨을 때 같이 바뀜
                  calendarFormat: _calendarFormat, // 한달 전체를 보여줌
                  rowHeight: 70, // 높이를 더 늘림
                  daysOfWeekHeight: 40,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _showMemoList(selectedDay); // 메모 리스트 표시
                  },
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    todayDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.brown[100],
                      border: Border.all(color: Colors.brown[400]!, width: 2.0),
                    ),
                    todayTextStyle: TextStyle(
                      color: Colors.brown[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    selectedDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      border: Border.all(color: Colors.brown[300]!, width: 1.0),
                    ),
                    selectedTextStyle: TextStyle(
                      color: Colors.brown[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    todayBuilder: (context, day, focusedDay) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.brown[100],
                          border: Border.all(
                            color: Colors.brown[400]!,
                            width: 2.0,
                          ),
                        ),
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: Colors.brown[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                    markerBuilder: (context, day, events) {
                      if (_memos[day]?.isNotEmpty ?? false) {
                        return Positioned(
                          bottom: 5,
                          child: Container(
                            width: 30,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.brown[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: Colors.brown[400],
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: Colors.brown[400],
                    ),
                    titleTextFormatter: (date, locale) =>
                        '${date.year}년 ${date.month}월',
                    titleTextStyle: GoogleFonts.notoSans(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
                  ),
                ),
              ),

              // 오늘의 추천 패션 섹션 (광고 자리)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF8B7355), const Color(0xFF6B5742)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.wb_sunny_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today\'s Recommendation',
                                style: GoogleFonts.pacifico(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '오늘의 추천 패션',
                                style: GoogleFonts.notoSans(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_size_select_actual_outlined,
                                color: Colors.white.withValues(alpha: 0.6),
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Advertisement Space',
                                style: GoogleFonts.notoSans(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '광고 영역',
                                style: GoogleFonts.notoSans(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Sponsored',
                                  style: GoogleFonts.notoSans(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
