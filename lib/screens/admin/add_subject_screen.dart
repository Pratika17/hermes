import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/faculty_provider.dart';

class AddSubjectScreen extends StatefulWidget {
  final String? existingSubjectCode; // Pass Code instead of Subject object
  const AddSubjectScreen({super.key, this.existingSubjectCode});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Info
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  // Allocations
  List<SubjectAllocation> _allocations = [];
  // bool _isLoading = false; // Removed unused variable

  @override
  void initState() {
    super.initState();
    if (widget.existingSubjectCode != null) {
      _loadExistingData();
    } else {
      // Add one empty allocation by default
      _addAllocation();
    }
  }

  void _loadExistingData() {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    final subjects = provider.getSubjectsByCode(widget.existingSubjectCode!);

    if (subjects.isNotEmpty) {
      _nameController.text = subjects.first.subjectName;
      _codeController.text = subjects.first.subjectCode;

      _allocations = subjects
          .map(
            (s) => SubjectAllocation(
              id: s.id,
              department: s.department,
              section: s.section,
              year: s.year,
              credits: s.credits, // Changed
              facultyId: s.facultyId,
            ),
          )
          .toList();
    }
  }

  void _addAllocation() {
    setState(() {
      _allocations.add(
        SubjectAllocation(
          department: '',
          section: '',
          year: '',
          credits: 0, // Changed
          facultyId: '',
        ),
      );
    });
  }

  void _removeAllocation(int index) {
    setState(() {
      _allocations.removeAt(index);
    });
  }

  void _saveSubject() {
    if (_formKey.currentState!.validate()) {
      // Validate Allocations manually (or rely on form fields if we bind them)
      // We need to capture the current state of allocations from their controllers if we used controllers...
      // BUT, since we are dynamically generating rows, managing controllers is tricky.
      // BETTER APPROACH: Wrap each row in a widget that calls back on change, or
      // keep a list of Controllers.

      // Let's verify we have at least one allocation
      if (_allocations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one class allocation'),
          ),
        );
        return;
      }

      // Also check if valid faculty selected for each
      for (var a in _allocations) {
        if (a.facultyId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select faculty for all classes'),
            ),
          );
          return;
        }
        if (a.credits < 0) {
          // Changed to allow 0
          // Changed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Credits must be >= 0')),
          ); // Changed
          return;
        }
      }

      Provider.of<SubjectProvider>(context, listen: false).syncSubjects(
        oldCode: widget.existingSubjectCode ?? "",
        newName: _nameController.text,
        newCode: _codeController.text,
        allocations: _allocations,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject Saved Successfully')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingSubjectCode != null ? 'Edit Subject' : 'Add Subject',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Info Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Subject Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Subject Code',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Class Allocations",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Allocations List
              ..._allocations.asMap().entries.map((entry) {
                final index = entry.key;
                final allocation = entry.value;
                return _AllocationRow(
                  key: ValueKey(
                    allocation.id ?? index,
                  ), // Use ID or Index if new
                  initialAllocation: allocation,
                  onUpdate: (updated) {
                    _allocations[index] = updated;
                  },
                  onRemove: () => _removeAllocation(index),
                );
              }),

              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _addAllocation,
                icon: const Icon(Icons.add),
                label: const Text("Add Another Class"),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _saveSubject,
                icon: const Icon(Icons.save),
                label: const Text('Save Subject'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllocationRow extends StatefulWidget {
  final SubjectAllocation initialAllocation;
  final ValueChanged<SubjectAllocation> onUpdate;
  final VoidCallback onRemove;

  const _AllocationRow({
    super.key,
    required this.initialAllocation,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_AllocationRow> createState() => _AllocationRowState();
}

class _AllocationRowState extends State<_AllocationRow> {
  late TextEditingController _deptCtrl;
  late TextEditingController _secCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _creditsCtrl; // Changed
  String? _selectedFaculty;

  @override
  void initState() {
    super.initState();
    _deptCtrl = TextEditingController(
      text: widget.initialAllocation.department,
    );
    _secCtrl = TextEditingController(text: widget.initialAllocation.section);
    _yearCtrl = TextEditingController(text: widget.initialAllocation.year);
    _creditsCtrl = TextEditingController(
      // Changed
      text:
          widget.initialAllocation.credits ==
              0 // Changed
          ? ''
          : widget.initialAllocation.credits.toString(), // Changed
    );
    _selectedFaculty = widget.initialAllocation.facultyId.isEmpty
        ? null
        : widget.initialAllocation.facultyId;

    // Listeners to update parent
    void update() {
      widget.onUpdate(
        SubjectAllocation(
          id: widget.initialAllocation.id,
          department: _deptCtrl.text,
          section: _secCtrl.text,
          year: _yearCtrl.text,
          credits: int.tryParse(_creditsCtrl.text) ?? 0, // Changed
          facultyId: _selectedFaculty ?? '',
        ),
      );
    }

    _deptCtrl.addListener(update);
    _secCtrl.addListener(update);
    _yearCtrl.addListener(update);
    _creditsCtrl.addListener(update); // Changed
  }

  @override
  Widget build(BuildContext context) {
    final faculties = Provider.of<FacultyProvider>(context).faculties;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _deptCtrl,
                    decoration: const InputDecoration(labelText: 'Dept'),
                    validator: (v) => v!.isEmpty ? 'Req' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _secCtrl,
                    decoration: const InputDecoration(labelText: 'Sec'),
                    validator: (v) => v!.isEmpty ? 'Req' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _yearCtrl,
                    decoration: const InputDecoration(labelText: 'Year'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Req';
                      if (v == '5') {
                        if (_deptCtrl.text.toUpperCase() != 'M.TECH CSE') {
                          return 'Only M.TECH CSE can be 5th Year';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _creditsCtrl, // Changed
                    decoration: const InputDecoration(
                      labelText: 'Credits',
                    ), // Changed
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Req' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedFaculty,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Faculty'),
                    items: faculties
                        .map(
                          (f) => DropdownMenuItem(
                            value: f.id,
                            child: Text(
                              f.facultyName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedFaculty = val);
                      // Trigger update manually since it's not a controller
                      widget.onUpdate(
                        SubjectAllocation(
                          id: widget.initialAllocation.id,
                          department: _deptCtrl.text,
                          section: _secCtrl.text,
                          year: _yearCtrl.text,
                          credits:
                              int.tryParse(_creditsCtrl.text) ?? 0, // Changed
                          facultyId: val ?? '',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
