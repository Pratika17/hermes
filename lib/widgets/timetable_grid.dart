import 'package:flutter/material.dart';
import '../models/timetable_slot.dart';
import '../providers/subject_provider.dart';
import '../providers/time_config_provider.dart'; // Added Import
import 'package:provider/provider.dart'; // Added

class TimetableGrid extends StatelessWidget {
  final List<TimetableSlot> slots;
  final int totalDays;
  final int hoursPerDay;
  final String title;
  final SubjectProvider subjectProvider;
  final String? year; // Added Year parameter

  const TimetableGrid({
    super.key,
    required this.slots,
    required this.totalDays,
    required this.hoursPerDay,
    required this.title,
    required this.subjectProvider,
    this.year, // Optional, can default to generic
  });

  @override
  Widget build(BuildContext context) {
    // 1. Fetch Layout from TimeConfig
    final timeConfigProvider = Provider.of<TimeConfigProvider>(context);
    List<TimeConfigSlot> configSlots;
    if (year != null) {
      configSlots = timeConfigProvider.getConfigForYear(year!);
    } else {
      // If no year, fallback to Year 1 or generic default
      configSlots = timeConfigProvider.getConfigForYear('1');
    }

    // Sort logic handled in Provider? No, Provider returns List.
    // Provider list is already ordered by user? Or we rely on index?
    // Let's assume list order IS the display order.

    // 2. Build Columns
    final columns = [
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
                columns: columns,
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
                        for (final slotConfig in configSlots)
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

  Widget _buildCell(BuildContext context, int day, TimeConfigSlot slotConfig) {
    if (slotConfig.type == 'break') {
      return Container(
        alignment: Alignment.center,
        color: Colors.grey.shade100,
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
        color: Colors.grey.shade100,
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
    final hour =
        slotConfig.index; // Logic relies on index matching generator logic
    TimetableSlot? slot;
    try {
      slot = slots.firstWhere((s) => s.dayOrder == day && s.hour == hour);
    } catch (_) {}

    if (slot == null) {
      return const SizedBox(height: 50, width: 80);
    }

    final subject = subjectProvider.getSubjectById(slot.subjectId);
    final displayText = subject?.subjectName ?? slot.subjectId;

    return Container(
      width: 80,
      height: 50,
      alignment: Alignment.center,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: slot.isManual
            ? Colors.orange.withOpacity(0.2)
            : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: slot.isManual ? Colors.orange : Colors.transparent,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            displayText,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Removed _ColType and _TimeColumn classes as they are replaced by TimeConfigSlot logic
