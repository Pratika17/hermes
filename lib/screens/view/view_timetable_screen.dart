import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/timetable_slot.dart'; // Added Import
import '../../providers/timetable_provider.dart';
import '../../providers/day_order_provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/time_config_provider.dart'; // Added Import
import '../../widgets/timetable_grid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ViewTimetableScreen extends StatefulWidget {
  final String? initialClassId;
  const ViewTimetableScreen({super.key, this.initialClassId});
  @override
  State<ViewTimetableScreen> createState() => _ViewTimetableScreenState();
}

class _ViewTimetableScreenState extends State<ViewTimetableScreen> {
  String? _selectedClass;

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.initialClassId;
  }

  @override
  Widget build(BuildContext context) {
    final timetableProvider = Provider.of<TimetableProvider>(context);
    final dayOrderProvider = Provider.of<DayOrderProvider>(context);

    // Extract unique classes from subjects (or timetable slots if generated)
    // Ideally, we should have a ClassProvider or list of valid classes.
    // We can infer from SubjectProvider.
    final subjectProvider = Provider.of<SubjectProvider>(context);
    final classes = subjectProvider.subjects
        .map((s) => "${s.department}-${s.section}-${s.year}")
        .toSet()
        .toList();
    classes.sort();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedClass,
                  decoration: const InputDecoration(labelText: 'Select Class'),
                  items: classes
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedClass = val);
                  },
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                tooltip: "Clear All Timetables",
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear Timetable?'),
                      content: const Text(
                        'This will delete all generated timetable slots. This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            timetableProvider.clearTimetable();
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Timetable cleared'),
                              ),
                            );
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              if (_selectedClass != null)
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.blue),
                  tooltip: "Download PDF",
                  onPressed: () => _generatePdf(
                    context,
                    timetableProvider.getSlotsForClass(_selectedClass!),
                    dayOrderProvider,
                  ),
                ),
            ],
          ),
        ),
        if (_selectedClass != null)
          Expanded(
            child: SingleChildScrollView(
              child: TimetableGrid(
                title: 'Timetable for $_selectedClass',
                slots: timetableProvider.getSlotsForClass(_selectedClass!),
                totalDays: dayOrderProvider.totalDayOrders,
                hoursPerDay: dayOrderProvider.hoursPerDay,
                subjectProvider: subjectProvider,
                year: _selectedClass!
                    .split('-')
                    .last, // Assumes format Dept-Sec-Year
              ),
            ),
          )
        else
          const Expanded(child: Center(child: Text('Please select a class'))),
      ],
    );
  }

  Future<void> _generatePdf(
    BuildContext context,
    List<TimetableSlot> slots,
    DayOrderProvider dayProvider,
  ) async {
    final pdf = pw.Document();
    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );
    // Fetch time config
    final timeConfigProvider = Provider.of<TimeConfigProvider>(
      context,
      listen: false,
    );
    final year = _selectedClass!.split('-').last;
    final configSlots = timeConfigProvider.getConfigForYear(year);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Timetable for $_selectedClass',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              _buildPdfGrid(slots, dayProvider, subjectProvider, configSlots),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPdfGrid(
    List<TimetableSlot> slots,
    DayOrderProvider dayProvider,
    SubjectProvider subjectProvider,
    List<TimeConfigSlot> configSlots,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                "Day",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            ...configSlots.map(
              (slotConfig) => pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      slotConfig.label,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      "${slotConfig.startTime}-${slotConfig.endTime}",
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Data Rows
        for (int d = 1; d <= dayProvider.totalDayOrders; d++)
          pw.TableRow(
            children: [
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(10),
                child: pw.Text(
                  "Day $d",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              ...configSlots.map((slotConfig) {
                if (slotConfig.type == 'break') {
                  return pw.Container(
                    color: PdfColors.grey100,
                    height: 40,
                    alignment: pw.Alignment.center,
                    child: pw.Transform.rotate(
                      angle: -1.5708,
                      child: pw.Text(
                        slotConfig.label,
                        style: const pw.TextStyle(
                          color: PdfColors.grey,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  );
                }
                if (slotConfig.type == 'lunch') {
                  return pw.Container(
                    color: PdfColors.grey100,
                    height: 40,
                    alignment: pw.Alignment.center,
                    child: pw.Transform.rotate(
                      angle: -1.5708,
                      child: pw.Text(
                        slotConfig.label,
                        style: const pw.TextStyle(
                          color: PdfColors.grey,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  );
                }

                // Period
                final slot = slots.firstWhere(
                  (s) => s.dayOrder == d && s.hour == slotConfig.index,
                  orElse: () => TimetableSlot(
                    dayOrder: d,
                    hour: slotConfig.index,
                    classId: "",
                    subjectId: "",
                    facultyId: "",
                  ),
                );

                if (slot.subjectId.isEmpty) return pw.Container(height: 40);

                final subject = subjectProvider.getSubjectById(slot.subjectId);
                final text =
                    subject?.subjectName ?? slot.subjectId; // Use Name Logic

                return pw.Container(
                  height: 40,
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        text,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
      ],
    );
  }
}
