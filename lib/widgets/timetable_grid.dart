import 'package:flutter/material.dart';
import '../models/timetable_slot.dart';
import '../providers/subject_provider.dart';
import '../providers/time_config_provider.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart'; // Added
import 'package:google_fonts/google_fonts.dart'; // Added

class TimetableGrid extends StatelessWidget {
  final List<TimetableSlot> slots;
  final int totalDays;
  final int hoursPerDay;
  final String title;
  final SubjectProvider subjectProvider;
  final String? year;
  final bool showClassInfo;

  const TimetableGrid({
    super.key,
    required this.slots,
    required this.totalDays,
    required this.hoursPerDay,
    required this.title,
    required this.subjectProvider,
    this.year,
    this.showClassInfo = false, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    // ... items from previous build ...
    // NOTE: Maintain all logic from previous step, just updating _buildCell and constructor
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  Colors.grey.shade200,
                ),
                border: TableBorder.all(color: Colors.grey.shade300),
                columnSpacing: 10,
                columns: _buildColumns(context),
                rows: [
                  for (int d = 1; d <= totalDays; d++)
                    DataRow(
                      cells: [
                        DataCell(
                          Container(
                            alignment: Alignment.center,
                            child: Text(
                              'Day $d',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        for (final slotConfig in _getTimeConfig(context))
                          DataCell(_buildCell(context, d, slotConfig)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to fetch config (refactored for clean access in loop)
  List<TimeConfigSlot> _getTimeConfig(BuildContext context) {
    final timeConfigProvider = Provider.of<TimeConfigProvider>(context);
    if (year != null) {
      return timeConfigProvider.getConfigForYear(year!);
    } else {
      return timeConfigProvider.getConfigForYear('1');
    }
  }

  List<DataColumn> _buildColumns(BuildContext context) {
    final configSlots = _getTimeConfig(context);
    return [
      const DataColumn(
        label: Text('Day', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      for (final slotConfig in configSlots)
        DataColumn(
          label: Container(
            width: slotConfig.type == 'period' ? 80 : 40,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slotConfig.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "${slotConfig.startTime}-${slotConfig.endTime}",
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _buildCell(BuildContext context, int day, TimeConfigSlot slotConfig) {
    if (slotConfig.type == 'break') {
      return Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            slotConfig.label, // "BREAK"
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      );
    }
    if (slotConfig.type == 'lunch') {
      return Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            slotConfig.label, // "LUNCH"
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      );
    }

    // It's a period
    final hour = slotConfig.index;
    TimetableSlot? slot;
    try {
      slot = slots.firstWhere((s) => s.dayOrder == day && s.hour == hour);
    } catch (_) {}

    if (slot == null) {
      return const SizedBox(height: 50, width: 80);
    }

    final subject = subjectProvider.getSubjectById(slot.subjectId);
    final displayText = subject?.subjectName ?? slot.subjectId;

    // Determine Color
    Color pillColor;
    if (slot.isManual) {
      pillColor = Colors.orangeAccent.shade100;
    } else {
      // Hash subject name/id to pick a color from AppTheme.subjectColors
      final hash = (subject?.subjectName ?? slot.subjectId).hashCode;
      pillColor =
          AppTheme.subjectColors[hash.abs() % AppTheme.subjectColors.length];
    }

    return Container(
      width: 80,
      height: 50,
      alignment: Alignment.center,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(16), // Pill shape
        boxShadow: [
          BoxShadow(
            color: pillColor.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              displayText,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
              maxLines: showClassInfo ? 2 : 3, // Reduce lines if showing class
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showClassInfo) // Show Class ID if requested
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                slot.classId,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w400,
                  fontSize: 9,
                  color: AppTheme.textLight,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

// Removed _ColType and _TimeColumn classes as they are replaced by TimeConfigSlot logic
