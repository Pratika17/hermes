import 'package:equatable/equatable.dart';

class TimetableSlot extends Equatable {
  final int dayOrder; // 1 to 5 (or configured max)
  final int hour; // 1 to 6 (or configured max)
  final String classId; // e.g., "CSE-A-3" (Dept-Sec-Year)
  final String subjectId;
  final String facultyId;
  final bool isManual; // To distinguish manually fixed slots

  const TimetableSlot({
    required this.dayOrder,
    required this.hour,
    required this.classId,
    required this.subjectId,
    required this.facultyId,
    this.isManual = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'dayOrder': dayOrder,
      'hour': hour,
      'classId': classId,
      'subjectId': subjectId,
      'facultyId': facultyId,
      'isManual': isManual,
    };
  }

  factory TimetableSlot.fromJson(Map<String, dynamic> json) {
    return TimetableSlot(
      dayOrder: json['dayOrder'],
      hour: json['hour'],
      classId: json['classId'],
      subjectId: json['subjectId'],
      facultyId: json['facultyId'],
      isManual: json['isManual'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
        dayOrder,
        hour,
        classId,
        subjectId,
        facultyId,
        isManual,
      ];
}
