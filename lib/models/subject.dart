import 'package:equatable/equatable.dart';

class Subject extends Equatable {
  final String id;
  final String subjectName;
  final String subjectCode;
  final int hoursRequired;
  final String facultyId;
  final String department;
  final String section;
  final String year;

  const Subject({
    required this.id,
    required this.subjectName,
    required this.subjectCode,
    required this.hoursRequired,
    required this.facultyId,
    required this.department,
    required this.section,
    required this.year,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'hoursRequired': hoursRequired,
      'facultyId': facultyId,
      'department': department,
      'section': section,
      'year': year,
    };
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      subjectName: json['subjectName'],
      subjectCode: json['subjectCode'],
      hoursRequired: json['hoursRequired'],
      facultyId: json['facultyId'],
      department: json['department'],
      section: json['section'],
      year: json['year'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        subjectName,
        subjectCode,
        hoursRequired,
        facultyId,
        department,
        section,
        year,
      ];
}
