import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/subject.dart';
import '../services/storage_service.dart';

class SubjectAllocation {
  final String? id; // Null for new allocations
  final String department;
  final String section;
  final String year;
  final int hours;
  final String facultyId;

  SubjectAllocation({
    this.id,
    required this.department,
    required this.section,
    required this.year,
    required this.hours,
    required this.facultyId,
  });
}

class SubjectProvider with ChangeNotifier {
  final List<Subject> _subjects = [];
  final StorageService _storage = StorageService();

  List<Subject> get subjects => [..._subjects];

  SubjectProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final list = await _storage.loadList(StorageService.keySubjects);
    _subjects.clear();
    _subjects.addAll(list.map((e) => Subject.fromJson(e)).toList());
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    await _storage.saveList(StorageService.keySubjects, _subjects.map((e) => e.toJson()).toList());
  }

  void addSubject(Subject subject) {
    _subjects.add(subject);
    _saveToStorage();
    notifyListeners();
  }

  void removeSubject(String id) {
    _subjects.removeWhere((element) => element.id == id);
    _saveToStorage();
    notifyListeners();
  }

  void updateSubject(Subject subject) {
    final index = _subjects.indexWhere((element) => element.id == subject.id);
    if (index >= 0) {
      _subjects[index] = subject;
      _saveToStorage();
      notifyListeners();
    }
  }

  Subject? getSubjectById(String id) {
    try {
      return _subjects.firstWhere((element) => element.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Subject> getSubjectsByCode(String code) {
    return _subjects.where((s) => s.subjectCode == code).toList();
  }

  void syncSubjects({
    required String oldCode, // If creating new, this can be empty or null
    required String newName,
    required String newCode,
    required List<SubjectAllocation> allocations,
  }) {
    // 1. Find existing subjects that belonged to this group (by oldCode)
    // If oldCode is empty, we are creating fresh.
    final existingSubjects = oldCode.isNotEmpty ? getSubjectsByCode(oldCode) : <Subject>[];
    
    // Track which IDs are kept/updated so we can delete the rest
    final Set<String> keptIds = {};

    for (var allocation in allocations) {
      if (allocation.id != null) {
        // Update existing
        final index = _subjects.indexWhere((s) => s.id == allocation.id);
        if (index != -1) {
          final updated = Subject(
            id: allocation.id!,
            subjectName: newName,
            subjectCode: newCode,
            hoursRequired: allocation.hours,
            facultyId: allocation.facultyId,
            department: allocation.department,
            section: allocation.section,
            year: allocation.year,
          );
          _subjects[index] = updated;
          keptIds.add(allocation.id!);
        }
      } else {
        // Create new
        final newSubject = Subject(
          id: const Uuid().v4(),
          subjectName: newName,
          subjectCode: newCode,
          hoursRequired: allocation.hours,
          facultyId: allocation.facultyId,
          department: allocation.department,
          section: allocation.section,
          year: allocation.year,
        );
        _subjects.add(newSubject);
      }
    }

    // 2. Delete subjects that were in the old group but not in the new allocations
    for (var existing in existingSubjects) {
      if (!keptIds.contains(existing.id)) {
        _subjects.removeWhere((s) => s.id == existing.id);
        // ideally we should also clean up timetable slots for this deleted subject
      }
    }

    _saveToStorage();
    notifyListeners();
  }
}
