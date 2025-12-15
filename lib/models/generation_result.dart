import 'timetable_slot.dart';

class GenerationResult {
  final List<TimetableSlot> timetable;
  final List<String>
  unallocatedSubjects; // List of Subject IDs or descriptions that couldn't be placed
  final double
  score; // 0.0 to 1.0 representing percentage of required hours filled

  GenerationResult({
    required this.timetable,
    required this.unallocatedSubjects,
    required this.score,
  });

  bool get isFullSuccess => unallocatedSubjects.isEmpty && score >= 1.0;
}
