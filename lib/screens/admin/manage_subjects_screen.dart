import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subject_provider.dart';
import '../../models/subject.dart'; // Added Import
import 'add_subject_screen.dart';

class ManageSubjectsScreen extends StatelessWidget {
  const ManageSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Subjects')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddSubjectScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<SubjectProvider>(
        builder: (ctx, subjectProvider, _) {
          final subjects = subjectProvider.subjects;
          if (subjects.isEmpty) {
            return const Center(child: Text('No subjects added yet.'));
          }

          // Group by Subject Code
          final Map<String, List<Subject>> grouped = {};
          for (var s in subjects) {
            if (!grouped.containsKey(s.subjectCode)) {
              grouped[s.subjectCode] = [];
            }
            grouped[s.subjectCode]!.add(s);
          }

          final keys = grouped.keys.toList();

          return ListView.builder(
            itemCount: keys.length,
            itemBuilder: (ctx, index) {
              final code = keys[index];
              final group = grouped[code]!;
              final first = group.first;
              final count = group.length;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text('${first.subjectName} ($code)'),
                  subtitle: Text('$count allocation(s)'),
                  trailing: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       IconButton(
                         icon: const Icon(Icons.edit, color: Colors.blue),
                         onPressed: () {
                           Navigator.of(context).push(
                             MaterialPageRoute(
                               builder: (context) => AddSubjectScreen(
                                 existingSubjectCode: code, // Pass code to edit group
                               ),
                             ),
                           );
                         },
                       ),
                       IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Confirm generic delete for entire group?
                          // For now allow individual delete by swipe or just delete all?
                          // Let's rely on Edit screen to remove allocations or Swipe here deletes ALL?
                          // Let's implement Delete All for Code here.
                          showDialog(
                            context: context, 
                            builder: (ctx) => AlertDialog(
                              title: Text("Delete $code?"),
                              content: Text("This will delete all $count allocations for this subject."),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                                TextButton(
                                  onPressed: () {
                                    for(var s in group) {
                                      subjectProvider.removeSubject(s.id);
                                    }
                                    Navigator.pop(ctx);
                                  }, 
                                  child: const Text("Delete", style: TextStyle(color: Colors.red))
                                )
                              ],
                            )
                          );
                        },
                      ),
                     ],
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
