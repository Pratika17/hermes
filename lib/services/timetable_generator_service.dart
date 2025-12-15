import '../models/subject.dart';
import '../models/faculty.dart';
import '../models/timetable_slot.dart';

class TimetableGeneratorService {
  Future<List<TimetableSlot>> generate({
    required List<Subject> subjects,
    required List<Faculty> faculties,
    required int totalDays,
    required int hoursPerDay,
    required List<TimetableSlot> manualSlots,
    String? targetClassId,
  }) async {
    // 1. Initialize empty timetable
    List<TimetableSlot> timetable = [...manualSlots];

    // 2. Map subjects to required slots
    // For simplicity, we assume one class generation at a time or handle all.
    // Here we will generate for all distinct classes found in subjects.
    
    // Group subjects by class (Dept-Sec-Year)
    final classGroups = _groupSubjectsByClass(subjects);

    final classesToGenerate = targetClassId != null 
        ? [targetClassId] 
        : classGroups.keys;

    for (var classId in classesToGenerate) {
      if (!classGroups.containsKey(classId)) continue;
      
      final classSubjects = classGroups[classId]!;
      List<TimetableSlot> classSlots = _generateForClass(
        classId,
        classSubjects,
        faculties,
        totalDays,
        hoursPerDay,
        timetable, // Pass current global state to check conflicts
      );
      timetable.addAll(classSlots);
    }

    return timetable;
  }

  Map<String, List<Subject>> _groupSubjectsByClass(List<Subject> subjects) {
    final Map<String, List<Subject>> groups = {};
    for (var s in subjects) {
      final key = "${s.department}-${s.section}-${s.year}";
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(s);
    }
    return groups;
  }

  List<TimetableSlot> _generateForClass(
    String classId,
    List<Subject> subjects,
    List<Faculty> faculties,
    int totalDays,
    int hoursPerDay,
    List<TimetableSlot> existingGlobalSlots,
  ) {
    List<TimetableSlot> newSlots = [];
    
    // Prepare a list of 'remaining hours' for each subject
    Map<String, int> remainingHours = {};
    for (var s in subjects) {
      remainingHours[s.id] = s.hoursRequired;
    }

    // Try to fill slots
    for (int day = 1; day <= totalDays; day++) {
      for (int hour = 1; hour <= hoursPerDay; hour++) {
        // Check if this slot is already manually filled
        if (_isSlotFilled(existingGlobalSlots, classId, day, hour)) continue;

        // Try to find a subject that fits
        Subject? bestSubject = _findBestSubject(
          subjects,
          remainingHours,
          faculties,
          existingGlobalSlots,
          newSlots,
          day,
          hour,
        );

        if (bestSubject != null) {
          // Assign
           // Determine faculty for this subject (assuming one faculty per subject for now, 
           // or logic to pick one if subject has specific faculty assigned in a pivot table, 
           // but here Subject model has facultyId? No, Subject has facultyId directly).
           // Wait, User request said Subject has "facultyId".
           
          final slot = TimetableSlot(
            dayOrder: day,
            hour: hour,
            classId: classId,
            subjectId: bestSubject.id,
            facultyId: bestSubject.facultyId,
          );
          newSlots.add(slot);
          remainingHours[bestSubject.id] = remainingHours[bestSubject.id]! - 1;
        }
      }
    }

    // Validation: Check if all hours are allocated ?
    // Basic CSP might fail if constraints are too tight.
    // For this MVP, we return what we could generate.
    
    return newSlots;
  }

  bool _isSlotFilled(
    List<TimetableSlot> globalSlots,
    String classId,
    int day,
    int hour,
  ) {
    return globalSlots.any((s) =>
        s.classId == classId && s.dayOrder == day && s.hour == hour);
  }

  Subject? _findBestSubject(
    List<Subject> subjects,
    Map<String, int> remainingHours,
    List<Faculty> faculties,
    List<TimetableSlot> globalSlots,
    List<TimetableSlot> currentClassNewSlots,
    int day,
    int hour,
  ) {
    // Basic heuristic: Pick subject with most remaining hours first? 
    // Or random shuffle to vary? Let's shuffle for variety if counts are equal.
    
    var candidates = subjects.where((s) => remainingHours[s.id]! > 0).toList();
    if (candidates.isEmpty) return null;

    candidates.shuffle();
    candidates.sort((a, b) => remainingHours[b.id]!.compareTo(remainingHours[a.id]!));

    for (var subject in candidates) {
      if (!_isFacultyBusy(subject.facultyId, day, hour, globalSlots, currentClassNewSlots)) {
        return subject;
      }
    }
    return null;
  }

  bool _isFacultyBusy(
    String facultyId,
    int day,
    int hour,
    List<TimetableSlot> globalSlots,
    List<TimetableSlot> currentClassNewSlots,
  ) {
    // Check global slots (slots from manual entries AND other classes already generated)
    bool busyInGlobal = globalSlots.any((s) =>
        s.facultyId == facultyId && s.dayOrder == day && s.hour == hour);
    
    return busyInGlobal;
  }
}
