import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/faculty_provider.dart';
import 'add_faculty_screen.dart';

class ManageFacultyScreen extends StatelessWidget {
  const ManageFacultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Faculty')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddFacultyScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<FacultyProvider>(
        builder: (context, provider, _) {
          if (provider.faculties.isEmpty) {
            return const Center(child: Text('No faculty members added yet.'));
          }
          return ListView.builder(
            itemCount: provider.faculties.length,
            itemBuilder: (context, index) {
              final faculty = provider.faculties[index];
              return Dismissible(
                key: Key(faculty.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  provider.removeFaculty(faculty.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${faculty.facultyName} removed')),
                  );
                },
                child: ListTile(
                  leading: CircleAvatar(child: Text(faculty.facultyName[0])),
                  title: Text(faculty.facultyName),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddFacultyScreen(existingFaculty: faculty),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
