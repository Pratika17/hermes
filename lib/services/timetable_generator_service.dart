import '../models/subject.dart';
import '../models/faculty.dart';
import '../models/timetable_slot.dart';
import '../models/generation_result.dart';

class TimetableGeneratorService {
  static const int _maxRetries = 10;

  Future<GenerationResult> generate({
    required List<Subject> subjects,
    required List<Faculty> faculties,
    required int totalDays,
    required int hoursPerDay,
    required List<TimetableSlot> manualSlots,
    String? targetClassId,
  }) async {
    GenerationResult? bestResult;

    // Group subjects by class (Dept-Sec-Year) once
    final classGroups = _groupSubjectsByClass(subjects);
    final classesToGenerate = targetClassId != null
        ? [targetClassId]
        : classGroups.keys.toList();

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      // Randomize class order to mitigate order dependence
      List<String> currentOrder = List.from(classesToGenerate)..shuffle();

      final result = _attemptGeneration(
        classGroups,
        currentOrder,
        faculties,
        totalDays,
        hoursPerDay,
        manualSlots,
      );

      // Keep the best result (highest score)
      if (bestResult == null || result.score > bestResult.score) {
        bestResult = result;
      }

      // If we found a perfect solution, stop early
      if (bestResult.isFullSuccess) break;
    }

    return bestResult!;
  }

  GenerationResult _attemptGeneration(
    Map<String, List<Subject>> classGroups,
    List<String> classesOrder,
    List<Faculty> faculties,
    int totalDays,
    int hoursPerDay,
    List<TimetableSlot> manualSlots,
  ) {
    List<TimetableSlot> currentTimetable = [...manualSlots];
    List<String> unallocated = [];
    int totalHoursRequired = 0;
    int totalHoursFilled = 0;

    // Global tracking of remaining hours for this attempt
    // Map<SubjectID, HoursRemaining>
    Map<String, int> globalRemainingHours = {};

    // Initialize remaining hours
    for (var classId in classesOrder) {
      final subjects = classGroups[classId] ?? [];
      for (var s in subjects) {
        int manualCount = manualSlots
            .where((slot) => slot.subjectId == s.id)
            .length;
        int needed = s.hoursRequired - manualCount;
        globalRemainingHours[s.id] = needed > 0 ? needed : 0;
        totalHoursRequired += (needed > 0 ? needed : 0);
      }
    }

    // Generate
    List<TimetableSlot> generatedSlots = [];

    for (var classId in classesOrder) {
      if (!classGroups.containsKey(classId)) continue;

      final classSubjects = classGroups[classId]!;

      // Filter subjects that still need hours
      final activeSubjects = classSubjects
          .where((s) => globalRemainingHours[s.id]! > 0)
          .toList();

      final slots = _generateForClass(
        classId,
        activeSubjects,
        faculties,
        totalDays,
        hoursPerDay,
        currentTimetable, // Global state (manual + previously generated in this run)
        globalRemainingHours, // REFERENCE to map to update decrements
      );

      generatedSlots.addAll(slots);
      currentTimetable.addAll(slots);
    }

    totalHoursFilled = generatedSlots.length; // From THIS generation run

    // Identify unallocated
    globalRemainingHours.forEach((subjectId, remaining) {
      if (remaining > 0) {
        unallocated.add(subjectId);
      }
    });

    double score = totalHoursRequired == 0
        ? 1.0
        : totalHoursFilled / totalHoursRequired;

    return GenerationResult(
      timetable: currentTimetable,
      unallocatedSubjects: unallocated,
      score: score,
    );
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
    Map<String, int> remainingHours,
  ) {
    List<TimetableSlot> newSlots = [];

    // Try to fill slots
    for (int day = 1; day <= totalDays; day++) {
      for (int hour = 1; hour <= hoursPerDay; hour++) {
        // Check if this slot is already filled for this class (by manual slot)
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
    return newSlots;
  }

  bool _isSlotFilled(
    List<TimetableSlot> globalSlots,
    String classId,
    int day,
    int hour,
  ) {
    return globalSlots.any(
      (s) => s.classId == classId && s.dayOrder == day && s.hour == hour,
    );
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
    // Candidates are subjects that still need hours
    var candidates = subjects.where((s) => remainingHours[s.id]! > 0).toList();
    if (candidates.isEmpty) return null;

    // Heuristics:
    // 1. Prioritize subjects with MORE remaining hours (tightest constraint).
    // 2. Shuffle ensuring randomness for equal weights.

    candidates.shuffle(); // Randomness
    candidates.sort(
      (a, b) => remainingHours[b.id]!.compareTo(remainingHours[a.id]!),
    );

    for (var subject in candidates) {
      if (!_isFacultyBusy(
        subject.facultyId,
        day,
        hour,
        globalSlots,
        currentClassNewSlots,
      )) {
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
    // AND check slots we just generated for this class in this run (currentClassNewSlots)

    bool busyInGlobal = globalSlots.any(
      (s) => s.facultyId == facultyId && s.dayOrder == day && s.hour == hour,
    );

    bool busyInCurrent = currentClassNewSlots.any(
      (s) => s.facultyId == facultyId && s.dayOrder == day && s.hour == hour,
    );

    return busyInGlobal || busyInCurrent;
  }
}
