import 'package:flutter/material.dart';
import '../models/timetable_slot.dart';
import '../services/storage_service.dart';

class TimetableProvider with ChangeNotifier {
  List<TimetableSlot> _slots = [];
  final StorageService _storage = StorageService();

  List<TimetableSlot> get slots => [..._slots];

  TimetableProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final list = await _storage.loadList(StorageService.keyTimetable);
    _slots = list.map((e) => TimetableSlot.fromJson(e)).toList();
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
     await _storage.saveList(StorageService.keyTimetable, _slots.map((e) => e.toJson()).toList());
  }

  void setTimetable(List<TimetableSlot> slots) {
    _slots = slots;
    _saveToStorage();
    notifyListeners();
  }

  void clearTimetable() {
    _slots.clear();
    _saveToStorage();
    notifyListeners();
  }

  void addManualSlot(TimetableSlot slot) {
    // Remove existing slot at same position if any
    _slots.removeWhere((s) =>
        s.dayOrder == slot.dayOrder &&
        s.hour == slot.hour &&
        s.classId == slot.classId);
    _slots.add(slot);
    _saveToStorage();
    notifyListeners();
  }

  void removeManualSlot(String classId, int day, int hour) {
    _slots.removeWhere((s) =>
        s.classId == classId &&
        s.dayOrder == day &&
        s.hour == hour &&
        s.isManual);
    _saveToStorage();
    notifyListeners();
  }
  
  List<TimetableSlot> getSlotsForClass(String classId) {
    return _slots.where((s) => s.classId == classId).toList();
  }
  
  List<TimetableSlot> getSlotsForFaculty(String facultyId) {
    return _slots.where((s) => s.facultyId == facultyId).toList();
  }
  
  List<TimetableSlot> get manualSlots => _slots.where((s) => s.isManual).toList();
}
