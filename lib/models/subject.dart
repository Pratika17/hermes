import 'package:equatable/equatable.dart';

class Subject extends Equatable {
  final String id;
  final String subjectName;
  final String subjectCode;
  final int credits; // Changed from hoursRequired
  final String facultyId;
  final String department;
  final String section;
  final String year;

  const Subject({
    required this.id,
    required this.subjectName,
    required this.subjectCode,
    required this.credits,
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
      'credits': credits, // Changed
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
      // Handle migration or fallback if 'credits' is missing but 'hoursRequired' exists
      credits: json['credits'] ?? json['hoursRequired'] ?? 3,
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
    credits, // Changed
    facultyId,
    department,
    section,
    year,
  ];
}
