import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/faculty.dart';
import '../../providers/faculty_provider.dart';

class AddFacultyScreen extends StatefulWidget {
  final Faculty? existingFaculty;
  const AddFacultyScreen({super.key, this.existingFaculty});

  @override
  State<AddFacultyScreen> createState() => _AddFacultyScreenState();
}

class _AddFacultyScreenState extends State<AddFacultyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingFaculty != null) {
      _nameController.text = widget.existingFaculty!.facultyName;
    }
  }

  void _saveFaculty() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      
      final isEditing = widget.existingFaculty != null;
      final newFaculty = Faculty(
        id: isEditing ? widget.existingFaculty!.id : const Uuid().v4(),
        facultyName: name,
        subjectsHandled: isEditing ? widget.existingFaculty!.subjectsHandled : [],
      );

      if (isEditing) {
        Provider.of<FacultyProvider>(context, listen: false).updateFaculty(newFaculty);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faculty Updated Successfully')),
        );
      } else {
        Provider.of<FacultyProvider>(context, listen: false).addFaculty(newFaculty);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faculty Added Successfully')),
        );
      }
      
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existingFaculty != null ? 'Edit Faculty' : 'Add Faculty')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Faculty Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saveFaculty,
                icon: const Icon(Icons.save),
                label: Text(widget.existingFaculty != null ? 'Update Faculty' : 'Save Faculty'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
