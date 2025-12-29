import 'package:flutter_test/flutter_test.dart';
import 'package:acadsync/services/timetable_generator_service.dart';
import 'package:acadsync/models/subject.dart';
import 'package:acadsync/models/faculty.dart';
import 'package:acadsync/models/timetable_slot.dart';

void main() {
  test(
    'Timetable Generator respects 0 credits and distributes evenly',
    () async {
      final service = TimetableGeneratorService();

      // Setup Data
      final fac1 = Faculty(
        id: 'f1',
        facultyName: 'F1',
        subjectsHandled: ['s1', 's2', 's3', 's4'],
      );

      // Subject with 0 credits -> Should get exactly 1 slot
      final subZero = Subject(
        id: 'sZero',
        subjectName: 'Zero Credit',
        subjectCode: 'S0',
        credits: 0,
        facultyId: 'f1',
        department: 'CSE',
        section: 'A',
        year: '4',
      );

      // Regular subjects -> Should share remainder evenly
      final sub1 = Subject(
        id: 's1',
        subjectName: 'Subject 1',
        subjectCode: 'S1',
        credits: 3,
        facultyId: 'f1',
        department: 'CSE',
        section: 'A',
        year: '4',
      );
      final sub2 = Subject(
        id: 's2',
        subjectName: 'Subject 2',
        subjectCode: 'S2',
        credits: 3,
        facultyId: 'f1',
        department: 'CSE',
        section: 'A',
        year: '4',
      );

      // Total slots = 5 days * 6 hours = 30 slots.
      // Zero credit -> 1 slot.
      // Remaining = 29 slots.
      // Sub1 and Sub2 should split 29 slots.
      // Ideally 14 and 15, or closest possible.

      final subjects = [subZero, sub1, sub2];
      final faculties = [fac1];
      final manualSlots = <TimetableSlot>[];

      final result = await service.generate(
        subjects: subjects,
        faculties: faculties,
        totalDays: 5,
        hoursPerDay: 6,
        manualSlots: manualSlots,
        workingDaysPerSemester: 90,
      );

      print('Generated slots: ${result.timetable.length}');

      int countZero = result.timetable
          .where((s) => s.subjectId == 'sZero')
          .length;
      int count1 = result.timetable.where((s) => s.subjectId == 's1').length;
      int count2 = result.timetable.where((s) => s.subjectId == 's2').length;

      print('Zero: $countZero');
      print('Sub1: $count1');
      print('Sub2: $count2');

      // Assertions
      expect(result.timetable.length, 30);
      expect(
        countZero,
        1,
        reason: 'Zero credit subject should have exactly 1 slot',
      );

      // Check even distribution (diff should be at most 1)
      expect(
        (count1 - count2).abs() <= 1,
        true,
        reason: 'Slots should be distributed evenly',
      );
    },
  );
}
