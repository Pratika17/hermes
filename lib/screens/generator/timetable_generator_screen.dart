import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/faculty_provider.dart';
import '../../providers/timetable_provider.dart';
import '../../providers/day_order_provider.dart';
import '../../services/timetable_generator_service.dart';
import '../../models/timetable_slot.dart'; // Fixed Import
import '../view/view_timetable_screen.dart'; // Added Import

class TimetableGeneratorScreen extends StatefulWidget {
  const TimetableGeneratorScreen({super.key});

  @override
  State<TimetableGeneratorScreen> createState() =>
      _TimetableGeneratorScreenState();
}

class _TimetableGeneratorScreenState extends State<TimetableGeneratorScreen> {
  bool _isGenerating = false;
  String? _statusMessage;
  String? _selectedClass; // null means 'All Classes'

  void _generateTimetable() async {
    final timetableProvider = Provider.of<TimetableProvider>(
      context,
      listen: false,
    );

    // 1. Overwrite Check for Specific Class
    if (_selectedClass != null) {
      final existingForClass = timetableProvider.slots.any(
        (s) => s.classId == _selectedClass && !s.isManual,
      );
      if (existingForClass) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Timetable Exists"),
            content: Text(
              "A timetable already exists for $_selectedClass. Please delete it first using the trash icon in the View screen.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        return;
      }
    }

    setState(() {
      _isGenerating = true;
      _statusMessage = 'Initializing...';
    });

    try {
      final subjectProvider = Provider.of<SubjectProvider>(
        context,
        listen: false,
      );
      final facultyProvider = Provider.of<FacultyProvider>(
        context,
        listen: false,
      );
      final dayOrderProvider = Provider.of<DayOrderProvider>(
        context,
        listen: false,
      );
      final generator = Provider.of<TimetableGeneratorService>(
        context,
        listen: false,
      );

      if (subjectProvider.subjects.isEmpty) {
        throw Exception('No subjects found. Please add data first.');
      }

      setState(() => _statusMessage = 'Generating Timetable...');

      // Artificial delay for UX
      await Future.delayed(const Duration(seconds: 1));

      // 2. Prepare Slots to Keep (Incremental Logic)
      // If generating for a specific class, we keep ALL existing slots (manual + other classes generated).
      // They act as constraints (faculty busy).
      // If generating ALL, we only keep manual slots.
      List<TimetableSlot> slotsToKeep;
      if (_selectedClass != null) {
        slotsToKeep = timetableProvider.slots; // Keep everything
      } else {
        slotsToKeep = timetableProvider.slots.where((s) => s.isManual).toList();
      }

      final timetable = await generator.generate(
        subjects: subjectProvider.subjects,
        faculties: facultyProvider.faculties,
        totalDays: dayOrderProvider.totalDayOrders,
        hoursPerDay: dayOrderProvider.hoursPerDay,
        manualSlots: slotsToKeep, // Pass as constraints
        targetClassId: _selectedClass,
      );

      timetableProvider.setTimetable(timetable);

      setState(() {
        _statusMessage = 'Generation Complete!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated ${timetable.length} slots successfully!'),
          ),
        );

        // 3. Auto-Navigate to View
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text("Generated Timetable")),
              body: ViewTimetableScreen(initialClassId: _selectedClass),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _statusMessage = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 64, color: Colors.deepPurple),
          const SizedBox(height: 24),
          if (_isGenerating) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_statusMessage ?? 'Processing...'),
          ] else ...[
            const Text(
              'Ready to Generate Timetables',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Consumer<SubjectProvider>(
              builder: (ctx, prov, _) {
                final classes = prov.subjects
                    .map((s) => "${s.department}-${s.section}-${s.year}")
                    .toSet()
                    .toList();
                classes.sort();

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedClass,
                    decoration: const InputDecoration(
                      labelText: 'Target Class (Optional)',
                      border: OutlineInputBorder(),
                      helperText: 'Leave empty to generate for ALL classes',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Classes'),
                      ),
                      ...classes.map(
                        (c) => DropdownMenuItem(value: c, child: Text(c)),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedClass = val),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _generateTimetable,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Generation'),
            ),
          ],
        ],
      ),
    );
  }
}
