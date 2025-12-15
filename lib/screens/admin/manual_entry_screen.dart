import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/timetable_provider.dart';
import '../../providers/day_order_provider.dart';
import '../../models/timetable_slot.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedSubjectId;
  int? _selectedDay;
  int? _selectedHour;
  
  @override
  Widget build(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context);
    final dayOrderProvider = Provider.of<DayOrderProvider>(context);
    
    // Group subjects by class for easier selection
    // Or just simple list for now
    
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Timetable Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               const Card(
                 child: Padding(
                   padding: EdgeInsets.all(16.0),
                   child: Text(
                     'Override the generator by fixing specific slots here. These slots will be marked as "Manual" and will not be moved.',
                     style: TextStyle(fontStyle: FontStyle.italic),
                   ),
                 ),
               ),
               const SizedBox(height: 24),
               DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Subject (Class)', border: OutlineInputBorder()),
                items: subjectProvider.subjects.map((s) => DropdownMenuItem(
                  value: s.id, 
                  child: Text('${s.subjectName} (${s.department}-${s.section})')
                )).toList(),
                onChanged: (val) => setState(() => _selectedSubjectId = val),
                validator: (val) => val == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Day Order', border: OutlineInputBorder()),
                      items: List.generate(dayOrderProvider.totalDayOrders, (i) => i + 1)
                          .map((d) => DropdownMenuItem(value: d, child: Text('Day $d')))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedDay = val),
                      validator: (val) => val == null ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Hour', border: OutlineInputBorder()),
                      items: List.generate(dayOrderProvider.hoursPerDay, (i) => i + 1)
                          .map((h) => DropdownMenuItem(value: h, child: Text('Hour $h')))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedHour = val),
                      validator: (val) => val == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final subject = subjectProvider.getSubjectById(_selectedSubjectId!)!;
                    
                    final slot = TimetableSlot(
                      dayOrder: _selectedDay!,
                      hour: _selectedHour!,
                      classId: "${subject.department}-${subject.section}-${subject.year}",
                      subjectId: subject.id,
                      facultyId: subject.facultyId,
                      isManual: true,
                    );
                    
                    Provider.of<TimetableProvider>(context, listen: false).addManualSlot(slot);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Manual Constraint Added')),
                    );
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.push_pin),
                label: const Text('Add Fixed Slot'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
