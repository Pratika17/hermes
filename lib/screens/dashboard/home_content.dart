import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/faculty_provider.dart';
import '../admin/manage_subjects_screen.dart';
import '../admin/manage_faculty_screen.dart';
import '../admin/manual_constraints_screen.dart'; // Added Import

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Subjects',
                  context.watch<SubjectProvider>().subjects.length.toString(),
                  Icons.menu_book,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Faculty',
                  context.watch<FacultyProvider>().faculties.length.toString(),
                  Icons.person_outline,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Builder(
                  builder: (ctx) {
                    final subjects = ctx.watch<SubjectProvider>().subjects;
                    final classes = subjects
                        .map((s) => "${s.department}-${s.section}-${s.year}")
                        .toSet();
                    return _buildSummaryCard(
                      context,
                      'Classes',
                      classes.length.toString(),
                      Icons.class_outlined,
                      Colors.orange,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Administration',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildActionItem(
            context,
            'Manage Subjects',
            'Add, edit, or remove subjects',
            Icons.book,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageSubjectsScreen()),
            ),
          ),
          _buildActionItem(
            context,
            'Manage Faculty',
            'Register or remove faculty members',
            Icons.people_alt,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageFacultyScreen()),
            ),
          ),
          _buildActionItem(
            context,
            'Manual Constraints',
            'Fix slots before generation',
            Icons.push_pin,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ManualConstraintsScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              count,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
