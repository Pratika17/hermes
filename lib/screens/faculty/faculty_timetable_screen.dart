import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/timetable_provider.dart';
import '../../providers/day_order_provider.dart';
import '../../providers/faculty_provider.dart';
import '../../providers/subject_provider.dart';
import '../../widgets/timetable_grid.dart';

class FacultyTimetableScreen extends StatefulWidget {
  const FacultyTimetableScreen({super.key});
  @override
  State<FacultyTimetableScreen> createState() => _FacultyTimetableScreenState();
}

class _FacultyTimetableScreenState extends State<FacultyTimetableScreen> {
  String? _selectedFacultyId;

  @override
  Widget build(BuildContext context) {
    final timetableProvider = Provider.of<TimetableProvider>(context);
    final dayOrderProvider = Provider.of<DayOrderProvider>(context);
    final facultyProvider = Provider.of<FacultyProvider>(context);
    
    final subjectProvider = Provider.of<SubjectProvider>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButtonFormField<String>(
            value: _selectedFacultyId,
            decoration: const InputDecoration(labelText: 'Select Faculty'),
            items: facultyProvider.faculties
                .map((f) => DropdownMenuItem(value: f.id, child: Text(f.facultyName)))
                .toList(),
            onChanged: (val) {
              setState(() => _selectedFacultyId = val);
            },
          ),
        ),
        if (_selectedFacultyId != null)
           Expanded(
            child: SingleChildScrollView(
              child: TimetableGrid(
                title: 'Timetable for Faculty',
                slots: timetableProvider.getSlotsForFaculty(_selectedFacultyId!),
                totalDays: dayOrderProvider.totalDayOrders,
                hoursPerDay: dayOrderProvider.hoursPerDay,
                subjectProvider: subjectProvider,
              ),
            ),
          )
        else
          const Expanded(child: Center(child: Text('Please select a faculty member'))),
      ],
    );
  }
}
