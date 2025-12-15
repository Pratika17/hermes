import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/timetable_provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/day_order_provider.dart';
import '../../models/timetable_slot.dart';

class ManualConstraintsScreen extends StatefulWidget {
  const ManualConstraintsScreen({super.key});

  @override
  State<ManualConstraintsScreen> createState() => _ManualConstraintsScreenState();
}

class _ManualConstraintsScreenState extends State<ManualConstraintsScreen> {
  // Filters or Sort? Group by Class ID
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Constraints')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddConstraintDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<TimetableProvider>(
        builder: (ctx, timeProv, _) {
          final manualSlots = timeProv.manualSlots;
          
          if (manualSlots.isEmpty) {
            return const Center(child: Text("No manual constraints added."));
          }
          
          // Group by Class ID
          final Map<String, List<TimetableSlot>> grouped = {};
          for (var slot in manualSlots) {
             if (!grouped.containsKey(slot.classId)) {
               grouped[slot.classId] = [];
             }
             grouped[slot.classId]!.add(slot);
          }
          
          final sortedClasses = grouped.keys.toList()..sort();

          return ListView.builder(
            itemCount: sortedClasses.length,
            itemBuilder: (ctx, i) {
              final classId = sortedClasses[i];
              final slots = grouped[classId]!;
              slots.sort((a,b) {
                if(a.dayOrder != b.dayOrder) return a.dayOrder.compareTo(b.dayOrder);
                return a.hour.compareTo(b.hour);
              });

              return ExpansionTile(
                title: Text(classId, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${slots.length} fixed slots"),
                children: slots.map((slot) {
                   // Resovle Subject Name
                   final subjProv = Provider.of<SubjectProvider>(context, listen: false);
                   final subject = subjProv.getSubjectById(slot.subjectId);
                   final subjName = subject?.subjectName ?? slot.subjectId;
                   
                   return ListTile(
                     title: Text("Day ${slot.dayOrder} - Period ${slot.hour}"),
                     subtitle: Text(subjName),
                     trailing: IconButton(
                       icon: const Icon(Icons.delete, color: Colors.red),
                       onPressed: () {
                         timeProv.removeManualSlot(slot.classId, slot.dayOrder, slot.hour);
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Constraint removed")));
                       },
                     ),
                   );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddConstraintDialog(BuildContext context) {
    showDialog(
      context: context, 
      builder: (context) => const _AddConstraintDialog()
    );
  }
}

class _AddConstraintDialog extends StatefulWidget {
  const _AddConstraintDialog();

  @override
  State<_AddConstraintDialog> createState() => _AddConstraintDialogState();
}

class _AddConstraintDialogState extends State<_AddConstraintDialog> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedClass;
  int? _selectedDay;
  int? _selectedHour;
  String? _selectedSubjectId;

  @override
  Widget build(BuildContext context) {
    final subjProv = Provider.of<SubjectProvider>(context, listen: false);
    final dayProv = Provider.of<DayOrderProvider>(context, listen: false);

    // Get all Class IDs from Subjects
    final classes = subjProv.subjects
      .map((s) => "${s.department}-${s.section}-${s.year}")
      .toSet()
      .toList()..sort();
      
    // Filter subjects based on selected Class?
    final availableSubjects = _selectedClass == null 
        ? subjProv.subjects 
        : subjProv.subjects.where((s) => "${s.department}-${s.section}-${s.year}" == _selectedClass).toList();

    return AlertDialog(
      title: const Text("Add Constraint"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Class"),
                items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedClass = val;
                    _selectedSubjectId = null; // Reset subject as list changes
                  });
                },
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                       decoration: const InputDecoration(labelText: "Day"),
                       items: List.generate(dayProv.totalDayOrders, (i) => i + 1)
                           .map((d) => DropdownMenuItem(value: d, child: Text("Day $d"))).toList(),
                       onChanged: (val) => setState(() => _selectedDay = val),
                       validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                       decoration: const InputDecoration(labelText: "Hour"),
                       items: List.generate(dayProv.hoursPerDay, (i) => i + 1)
                           .map((h) => DropdownMenuItem(value: h, child: Text("Per $h"))).toList(),
                       onChanged: (val) => setState(() => _selectedHour = val),
                       validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Subject"),
                value: _selectedSubjectId,
                items: availableSubjects.map((s) => DropdownMenuItem(value: s.id, child: Text("${s.subjectName} (${s.subjectCode})"))).toList(),
                onChanged: (val) => setState(() => _selectedSubjectId = val),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
                final subj = subjProv.getSubjectById(_selectedSubjectId!);
                if (subj != null) {
                  final slot = TimetableSlot(
                    dayOrder: _selectedDay!,
                    hour: _selectedHour!,
                    classId: _selectedClass!,
                    subjectId: subj.id,
                    facultyId: subj.facultyId,
                    isManual: true,
                  );
                  Provider.of<TimetableProvider>(context, listen: false).addManualSlot(slot);
                  Navigator.pop(context);
                }
            }
          }, 
          child: const Text("Save")
        ),
      ],
    );
  }
}
