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
    required int workingDaysPerSemester, // New Argument
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
        workingDaysPerSemester, // Pass down
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
    int workingDaysPerSemester,
  ) {
    List<TimetableSlot> currentTimetable = [...manualSlots];
    List<String> unallocated = [];
    int totalHoursRequired = 0;

    // Global tracking of remaining hours for this attempt
    Map<String, int> globalRemainingHours = {};

    // Initialize remaining hours
    for (var classId in classesOrder) {
      final subjects = classGroups[classId] ?? [];
      for (var s in subjects) {
        double weeklyHoursDouble = (s.credits * 75) / workingDaysPerSemester;
        int calculatedHours = weeklyHoursDouble.ceil();
        int hoursRequired = (calculatedHours > s.credits)
            ? calculatedHours
            : s.credits;

        if (s.credits > 0 && hoursRequired == 0) hoursRequired = 1;
        if (s.credits == 0) hoursRequired = 1;

        int manualCount = manualSlots
            .where((slot) => slot.subjectId == s.id)
            .length;

        int needed = hoursRequired - manualCount;
        globalRemainingHours[s.id] = needed > 0 ? needed : 0;
        totalHoursRequired += (needed > 0 ? needed : 0);
      }
    }

    List<TimetableSlot> generatedSlots = [];

    // Phase 1: Generate based on Requirements
    for (var classId in classesOrder) {
      if (!classGroups.containsKey(classId)) continue;
      final classSubjects = classGroups[classId]!;

      final activeSubjects = classSubjects
          .where((s) => globalRemainingHours[s.id]! > 0)
          .toList();

      final slots = _generateForClass(
        classId,
        activeSubjects,
        faculties,
        totalDays,
        hoursPerDay,
        currentTimetable,
        globalRemainingHours,
        false, // fillMode = false
      );

      generatedSlots.addAll(slots);
      currentTimetable.addAll(slots);
    }

    // Phase 2: Fill Remaining Empty Slots (Greedy Fill)
    for (var classId in classesOrder) {
      if (!classGroups.containsKey(classId)) continue;
      final classSubjects = classGroups[classId]!;

      // In fill mode, we use ALL subjects as potential candidates
      final filledSlots = _generateForClass(
        classId,
        classSubjects,
        faculties,
        totalDays,
        hoursPerDay,
        currentTimetable,
        globalRemainingHours,
        true, // fillMode = true
      );

      generatedSlots.addAll(filledSlots);
      currentTimetable.addAll(filledSlots);
    }

    globalRemainingHours.forEach((subjectId, remaining) {
      if (remaining > 0) {
        unallocated.add(subjectId);
      }
    });

    // Score calculation logic
    int totalMissing = 0;
    for (var rem in globalRemainingHours.values) {
      if (rem > 0) totalMissing += rem;
    }
    int totalMet = totalHoursRequired - totalMissing;

    double score = totalHoursRequired == 0
        ? 1.0
        : totalMet / totalHoursRequired;

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
    bool fillMode,
  ) {
    List<TimetableSlot> newSlots = [];

    // Try to fill slots
    for (int day = 1; day <= totalDays; day++) {
      for (int hour = 1; hour <= hoursPerDay; hour++) {
        // Check if slot filled in GLOBAL (prev classes or manual) or CURRENT (this class progress)
        if (_isSlotFilled(existingGlobalSlots, newSlots, classId, day, hour))
          continue;

        Subject? bestSubject = _findBestSubject(
          classId,
          subjects,
          remainingHours,
          faculties,
          existingGlobalSlots,
          newSlots,
          day,
          hour,
          fillMode,
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
          if (!fillMode) {
            remainingHours[bestSubject.id] =
                remainingHours[bestSubject.id]! - 1;
          }
        }
      }
    }
    return newSlots;
  }

  bool _isSlotFilled(
    List<TimetableSlot> globalSlots,
    List<TimetableSlot> localSlots,
    String classId,
    int day,
    int hour,
  ) {
    if (globalSlots.any(
      (s) => s.classId == classId && s.dayOrder == day && s.hour == hour,
    ))
      return true;
    if (localSlots.any(
      (s) => s.classId == classId && s.dayOrder == day && s.hour == hour,
    ))
      return true;
    return false;
  }

  Subject? _findBestSubject(
    String classId,
    List<Subject> subjects,
    Map<String, int> remainingHours,
    List<Faculty> faculties,
    List<TimetableSlot> globalSlots,
    List<TimetableSlot> currentClassNewSlots,
    int day,
    int hour,
    bool fillMode,
  ) {
    List<Subject> candidates;

    if (fillMode) {
      // Exclude subjects with 0 credits from receiving EXTRA slots.
      candidates = subjects.where((s) => s.credits > 0).toList();
    } else {
      candidates = subjects.where((s) => remainingHours[s.id]! > 0).toList();
    }

    if (candidates.isEmpty) return null;

    candidates.shuffle(); // Randomness

    if (!fillMode) {
      candidates.sort(
        (a, b) => remainingHours[b.id]!.compareTo(remainingHours[a.id]!),
      );
    } else {
      // Phase 2: Even Distribution (Least Allocated First)
      // Calculate current allocation for this class
      candidates.sort((a, b) {
        int countA = _countForSubject(
          a.id,
          classId,
          globalSlots,
          currentClassNewSlots,
        );
        int countB = _countForSubject(
          b.id,
          classId,
          globalSlots,
          currentClassNewSlots,
        );
        return countA.compareTo(countB);
      });
    }

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

  int _countForSubject(
    String subjectId,
    String classId,
    List<TimetableSlot> globalSlots,
    List<TimetableSlot> localSlots,
  ) {
    int count = 0;
    count += globalSlots
        .where((s) => s.classId == classId && s.subjectId == subjectId)
        .length;
    count += localSlots
        .where((s) => s.classId == classId && s.subjectId == subjectId)
        .length;
    return count;
  }

  bool _isFacultyBusy(
    String facultyId,
    int day,
    int hour,
    List<TimetableSlot> globalSlots,
    List<TimetableSlot> currentClassNewSlots,
  ) {
    bool busyInGlobal = globalSlots.any(
      (s) => s.facultyId == facultyId && s.dayOrder == day && s.hour == hour,
    );

    bool busyInCurrent = currentClassNewSlots.any(
      (s) => s.facultyId == facultyId && s.dayOrder == day && s.hour == hour,
    );

    return busyInGlobal || busyInCurrent;
  }
}
