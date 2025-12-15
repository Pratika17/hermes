import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/faculty_provider.dart';
import '../admin/manage_subjects_screen.dart';
import '../admin/manage_faculty_screen.dart';
import '../admin/manual_constraints_screen.dart';
import '../../theme/app_theme.dart';

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Text(
            "Welcome Back!",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Let's organize your academic schedule.",
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textLight),
          ),
          const SizedBox(height: 32),

          // Summary Cards Row
          Row(
            children: [
              Expanded(
                child: _buildGradientSummaryCard(
                  context,
                  'Subjects',
                  context.watch<SubjectProvider>().subjects.length.toString(),
                  Icons.menu_book,
                  [
                    const Color(0xFFA0EACD),
                    const Color(0xFFE2F0CB),
                  ], // Teal -> Green
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGradientSummaryCard(
                  context,
                  'Faculty',
                  context.watch<FacultyProvider>().faculties.length.toString(),
                  Icons.person,
                  [
                    const Color(0xFFFFD1DC),
                    const Color(0xFFFFE5D9),
                  ], // Pink -> Peach
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
                    return _buildGradientSummaryCard(
                      context,
                      'Classes',
                      classes.length.toString(),
                      Icons.class_outlined,
                      [
                        const Color(0xFFC7CEEA),
                        const Color(0xFFE2F0CB),
                      ], // Purple -> Green
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Action Section
          Text(
            'Quick Actions',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildModernActionItem(
            context,
            'Manage Subjects',
            'Add, edit, or remove subjects',
            Icons.book,
            Colors.blueAccent.withOpacity(0.1),
            Colors.blueAccent,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageSubjectsScreen()),
            ),
          ),
          _buildModernActionItem(
            context,
            'Manage Faculty',
            'Register or remove faculty members',
            Icons.people_alt,
            Colors.orangeAccent.withOpacity(0.1),
            Colors.orangeAccent,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageFacultyScreen()),
            ),
          ),
          _buildModernActionItem(
            context,
            'Manual Constraints',
            'Fix slots before generation',
            Icons.push_pin,
            Colors.redAccent.withOpacity(0.1),
            Colors.redAccent,
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

  Widget _buildGradientSummaryCard(
    BuildContext context,
    String title,
    String count,
    IconData icon,
    List<Color> gradientColors,
  ) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(icon, size: 80, color: Colors.white.withOpacity(0.2)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  count,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: Colors.grey,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
