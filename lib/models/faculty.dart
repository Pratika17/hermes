import 'package:equatable/equatable.dart';

class Faculty extends Equatable {
  final String id;
  final String facultyName;
  final List<String> subjectsHandled; // List of Subject IDs

  const Faculty({
    required this.id,
    required this.facultyName,
    required this.subjectsHandled,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'facultyName': facultyName,
      'subjectsHandled': subjectsHandled,
    };
  }

  factory Faculty.fromJson(Map<String, dynamic> json) {
    return Faculty(
      id: json['id'],
      facultyName: json['facultyName'],
      subjectsHandled: List<String>.from(json['subjectsHandled'] ?? []),
    );
  }

  @override
  List<Object?> get props => [id, facultyName, subjectsHandled];
}
