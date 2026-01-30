import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _aiInsightsKey = 'ai_insights_cache';
  static const String _aiInsightsTimestampKey = 'ai_insights_timestamp';
  static const Duration _cacheExpiry = Duration(hours: 24);

  static Future<void> cacheAIInsights(String insights) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiInsightsKey, insights);
    await prefs.setInt(_aiInsightsTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<String?> getCachedAIInsights() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_aiInsightsTimestampKey);
    
    if (timestamp == null) return null;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    
    if (now.difference(cacheTime) > _cacheExpiry) {
      await clearAIInsightsCache();
      return null;
    }
    
    return prefs.getString(_aiInsightsKey);
  }

  static Future<void> clearAIInsightsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_aiInsightsKey);
    await prefs.remove(_aiInsightsTimestampKey);
  }

  static Future<bool> hasValidCache() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_aiInsightsTimestampKey);
    
    if (timestamp == null) return false;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    
    return now.difference(cacheTime) <= _cacheExpiry;
  }
}
