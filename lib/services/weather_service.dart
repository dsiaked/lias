import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherData {
  final double tempC;
  final String description; // e.g., "light rain"
  final String main; // e.g., "Rain"
  final bool willRain;

  WeatherData({
    required this.tempC,
    required this.description,
    required this.main,
    required this.willRain,
  });
}

class WeatherService {
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  static const _geoUrl = 'https://api.openweathermap.org/geo/1.0/direct';

  // Fetch current weather by city/region name
  static Future<WeatherData?> fetchCurrent(
    String region, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null; // gracefully skip

    // Helper to parse weather JSON
    WeatherData? parse(Map<String, dynamic> data) {
      final weatherList = (data['weather'] as List<dynamic>?);
      final main = data['main'] as Map<String, dynamic>?;
      if (weatherList == null || weatherList.isEmpty || main == null) {
        return null;
      }
      final w0 = weatherList.first as Map<String, dynamic>;
      final temp = (main['temp'] as num?)?.toDouble();
      final mainStr = (w0['main'] as String?) ?? '';
      final desc = (w0['description'] as String?) ?? mainStr;
      final codeMain = mainStr.toLowerCase();
      final willRain =
          codeMain.contains('rain') ||
          codeMain.contains('drizzle') ||
          codeMain.contains('thunder') ||
          (data['rain'] != null);
      if (temp == null) return null;
      return WeatherData(
        tempC: temp,
        description: desc,
        main: mainStr,
        willRain: willRain,
      );
    }

    Future<WeatherData?> byCity(String q) async {
      final uri = Uri.parse(
        '$_baseUrl?q=${Uri.encodeComponent(q)}&appid=$apiKey&units=metric&lang=kr',
      );
      final resp = await http.get(uri).timeout(timeout);
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return parse(data);
    }

    Future<WeatherData?> byLatLon(double lat, double lon) async {
      final uri = Uri.parse(
        '$_baseUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=kr',
      );
      final resp = await http.get(uri).timeout(timeout);
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return parse(data);
    }

    try {
      // 1) Try as-is (whatever user typed)
      final byName = await byCity(region);
      if (byName != null) return byName;

      // 2) If likely Korean locale, try adding country code (KR)
      final containsNonAscii = region.codeUnits.any((c) => c > 127);
      if (containsNonAscii && !region.contains(',')) {
        final byKr = await byCity('$region,KR');
        if (byKr != null) return byKr;
      }

      // 3) Geocoding fallback
      final geo = Uri.parse(
        '$_geoUrl?q=${Uri.encodeComponent(region)}&limit=1&appid=$apiKey',
      );
      final gResp = await http.get(geo).timeout(timeout);
      if (gResp.statusCode == 200) {
        final list = jsonDecode(gResp.body) as List<dynamic>;
        if (list.isNotEmpty) {
          final first = list.first as Map<String, dynamic>;
          final lat = (first['lat'] as num?)?.toDouble();
          final lon = (first['lon'] as num?)?.toDouble();
          if (lat != null && lon != null) {
            final byCoord = await byLatLon(lat, lon);
            if (byCoord != null) return byCoord;
          }
        }
      }

      return null;
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  // Build a short, friendly fashion-oriented advice string
  static String buildAdvice(String region, WeatherData wd) {
    final t = wd.tempC;
    String comfort;
    if (t >= 28) {
      comfort = '꽤 덥습니다. 통기성 좋은 소재와 밝은 톤을 추천해요.';
    } else if (t >= 23) {
      comfort = '약간 덥습니다. 반소매나 가벼운 아우터면 충분해요.';
    } else if (t >= 18) {
      comfort = '선선합니다. 가벼운 니트나 얇은 아우터가 좋아요.';
    } else if (t >= 12) {
      comfort = '조금 쌀쌀합니다. 가벼운 코트나 재킷을 고려하세요.';
    } else if (t >= 5) {
      comfort = '추운 편입니다. 보온성 있는 아우터가 필요해요.';
    } else {
      comfort = '매우 춥습니다. 두꺼운 코트와 보온 액세서리를 권장해요.';
    }

    final rainNote = wd.willRain ? ' 비 소식이 있어요. 우산을 꼭 챙겨주세요.' : '';

    return '오늘 $region은 약 ${t.toStringAsFixed(0)}°C, "${wd.description}" 입니다. $comfort$rainNote';
  }
}
