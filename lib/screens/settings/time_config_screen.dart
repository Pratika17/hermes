import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/time_config_provider.dart';

class TimeConfigScreen extends StatefulWidget {
  const TimeConfigScreen({super.key});

  @override
  State<TimeConfigScreen> createState() => _TimeConfigScreenState();
}

class _TimeConfigScreenState extends State<TimeConfigScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _years = ['1', '2', '3', '4', '5'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _years.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bell Schedule Configuration'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _years.map((y) => Tab(text: 'Year $y')).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _years.map((year) => _YearConfigEditor(year: year)).toList(),
      ),
    );
  }
}

class _YearConfigEditor extends StatefulWidget {
  final String year;
  const _YearConfigEditor({required this.year});

  @override
  State<_YearConfigEditor> createState() => _YearConfigEditorState();
}

class _YearConfigEditorState extends State<_YearConfigEditor> {
  // We need local state to edit before saving
  late List<TimeConfigSlot> _slots;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  void _loadSlots() {
    final provider = Provider.of<TimeConfigProvider>(context, listen: false);
    _slots = List.from(provider.getConfigForYear(widget.year));
  }

  void _save() {
    Provider.of<TimeConfigProvider>(
      context,
      listen: false,
    ).updateConfig(widget.year, _slots);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved settings for Year ${widget.year}')),
    );
  }

  void _editSlot(int index) async {
    final slot = _slots[index];
    final result = await showDialog<TimeConfigSlot>(
      context: context,
      builder: (ctx) => _EditSlotDialog(slot: slot),
    );

    if (result != null) {
      setState(() {
        _slots[index] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Configure Period, Break, and Lunch timings for Year ${widget.year}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ReorderableListView(
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = _slots.removeAt(oldIndex);
                _slots.insert(newIndex, item);
              });
            },
            children: [
              for (int i = 0; i < _slots.length; i++)
                ListTile(
                  key: ValueKey(
                    "${widget.year}-${_slots[i].label}-$i",
                  ), // Unique key
                  leading: Icon(_getIcon(_slots[i].type)),
                  title: Text(_slots[i].label),
                  subtitle: Text(
                    "${_slots[i].startTime} - ${_slots[i].endTime}",
                  ),
                  trailing: const Icon(Icons.edit),
                  tileColor: _getColor(_slots[i].type).withOpacity(0.1),
                  onTap: () => _editSlot(i),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text("Save Year Configuration"),
          ),
        ),
      ],
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'break':
        return Icons.coffee;
      case 'lunch':
        return Icons.restaurant;
      default:
        return Icons.schedule;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'break':
        return Colors.orange;
      case 'lunch':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}

class _EditSlotDialog extends StatefulWidget {
  final TimeConfigSlot slot;
  const _EditSlotDialog({required this.slot});

  @override
  State<_EditSlotDialog> createState() => _EditSlotDialogState();
}

class _EditSlotDialogState extends State<_EditSlotDialog> {
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late TextEditingController _labelCtrl;

  @override
  void initState() {
    super.initState();
    _startCtrl = TextEditingController(text: widget.slot.startTime);
    _endCtrl = TextEditingController(text: widget.slot.endTime);
    _labelCtrl = TextEditingController(text: widget.slot.label);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Time Slot"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _labelCtrl,
            decoration: const InputDecoration(labelText: "Label"),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _startCtrl,
                  decoration: const InputDecoration(labelText: "Start Time"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _endCtrl,
                  decoration: const InputDecoration(labelText: "End Time"),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              TimeConfigSlot(
                label: _labelCtrl.text,
                startTime: _startCtrl.text,
                endTime: _endCtrl.text,
                type: widget.slot.type,
                index: widget.slot.index,
              ),
            );
          },
          child: const Text("Update"),
        ),
      ],
    );
  }
}
