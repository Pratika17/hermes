import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String keySubjects = 'subjects';
  static const String keyFaculty = 'faculty';
  static const String keyTimetable = 'timetable';
  
  // Generic Save
  Future<void> saveList(String key, List<dynamic> list) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(list);
    await prefs.setString(key, jsonString);
  }

  // Generic Load
  Future<List<dynamic>> loadList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(key);
    if (jsonString == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list;
    } catch (e) {
      // In case of error (e.g. migration issue), return empty
      return [];
    }
  }

  // Clear all data (optional, for debug/reset)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
