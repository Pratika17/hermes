import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/day_order_provider.dart';
import 'time_config_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _totalDaysController = TextEditingController();
  final _hoursPerDayController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<DayOrderProvider>(context, listen: false);
    _totalDaysController.text = provider.totalDayOrders.toString();
    _hoursPerDayController.text = provider.hoursPerDay.toString();
  }

  @override
  void dispose() {
    _totalDaysController.dispose();
    _hoursPerDayController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final int? days = int.tryParse(_totalDaysController.text);
    final int? hours = int.tryParse(_hoursPerDayController.text);

    if (days != null && hours != null) {
      Provider.of<DayOrderProvider>(
        context,
        listen: false,
      ).updateSettings(totalDays: days, hours: hours);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings Saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Bell Schedule (Time Config)'),
            subtitle: const Text('Set start/end times per year'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TimeConfigScreen()),
              );
            },
          ),
          const Text(
            'Timetable Configuration',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _totalDaysController,
            decoration: const InputDecoration(
              labelText: 'Total Day Orders',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hoursPerDayController,
            decoration: const InputDecoration(
              labelText: 'Hours per Day',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saveSettings,
            child: const Text('Save Configuration'),
          ),
        ],
      ),
    );
  }
}
