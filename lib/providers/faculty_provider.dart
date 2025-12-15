import 'package:flutter/material.dart';
import '../models/faculty.dart';
import '../services/storage_service.dart';

class FacultyProvider with ChangeNotifier {
  final List<Faculty> _faculties = [];
  final StorageService _storage = StorageService();

  List<Faculty> get faculties => [..._faculties];

  FacultyProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final list = await _storage.loadList(StorageService.keyFaculty);
    _faculties.clear();
    _faculties.addAll(list.map((e) => Faculty.fromJson(e)).toList());
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    await _storage.saveList(StorageService.keyFaculty, _faculties.map((e) => e.toJson()).toList());
  }

  void addFaculty(Faculty faculty) {
    _faculties.add(faculty);
    _saveToStorage();
    notifyListeners();
  }

  void removeFaculty(String id) {
    _faculties.removeWhere((element) => element.id == id);
    _saveToStorage();
    notifyListeners();
  }

  void updateFaculty(Faculty faculty) {
    final index = _faculties.indexWhere((element) => element.id == faculty.id);
    if (index >= 0) {
      _faculties[index] = faculty;
      _saveToStorage();
      notifyListeners();
    }
  }
  
    Faculty? getFacultyById(String id) {
    try {
      return _faculties.firstWhere((element) => element.id == id);
    } catch (e) {
      return null;
    }
  }
}
