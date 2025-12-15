import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class TimeConfigSlot {
  final String label;
  final String startTime;
  final String endTime;
  final String type; // 'period', 'break', 'lunch'
  final int index; // 1, 2, 3...

  TimeConfigSlot({
    required this.label,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.index = 0,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'startTime': startTime,
    'endTime': endTime,
    'type': type,
    'index': index,
  };

  factory TimeConfigSlot.fromJson(Map<String, dynamic> json) => TimeConfigSlot(
    label: json['label'],
    startTime: json['startTime'],
    endTime: json['endTime'],
    type: json['type'],
    index: json['index'] ?? 0,
  );
}

class TimeConfigProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  static const String _storageKey = 'time_config';

  // Map of Year -> List<TimeConfigSlot>
  Map<String, List<TimeConfigSlot>> _yearConfigs = {};

  TimeConfigProvider() {
    _loadFromStorage();
  }

  Map<String, List<TimeConfigSlot>> get yearConfigs => {..._yearConfigs};

  List<TimeConfigSlot> getConfigForYear(String year) {
    if (_yearConfigs.containsKey(year)) {
      return _yearConfigs[year]!;
    }
    return _getDefaultConfig(year);
  }

  Future<void> _loadFromStorage() async {
    final list = await _storage.loadList(_storageKey);
    if (list.isNotEmpty) {
      _yearConfigs = {};
      for (var item in list) {
        // item is { 'year': '1', 'slots': [...] }
        final year = item['year'];
        final slots = (item['slots'] as List)
            .map((s) => TimeConfigSlot.fromJson(s))
            .toList();
        _yearConfigs[year] = slots;
      }
    } else {
      // Seed defaults if empty
      _seedDefaults();
    }
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final list = _yearConfigs.entries
        .map(
          (e) => {
            'year': e.key,
            'slots': e.value.map((s) => s.toJson()).toList(),
          },
        )
        .toList();
    await _storage.saveList(_storageKey, list);
  }

  void updateConfig(String year, List<TimeConfigSlot> slots) {
    _yearConfigs[year] = slots;
    _saveToStorage();
    notifyListeners();
  }

  void _seedDefaults() {
    // Default Layout (Lunch at 1:15) used for Year 2, 3, 4 typically?
    final defaultSlots = [
      TimeConfigSlot(
        label: "Period 1",
        startTime: "08:45",
        endTime: "09:45",
        type: 'period',
        index: 1,
      ),
      TimeConfigSlot(
        label: "Period 2",
        startTime: "09:45",
        endTime: "10:45",
        type: 'period',
        index: 2,
      ),
      TimeConfigSlot(
        label: "BREAK",
        startTime: "10:45",
        endTime: "11:15",
        type: 'break',
        index: 0,
      ),
      TimeConfigSlot(
        label: "Period 3",
        startTime: "11:15",
        endTime: "12:15",
        type: 'period',
        index: 3,
      ),
      TimeConfigSlot(
        label: "Period 4",
        startTime: "12:15",
        endTime: "01:15",
        type: 'period',
        index: 4,
      ),
      TimeConfigSlot(
        label: "LUNCH",
        startTime: "01:15",
        endTime: "02:15",
        type: 'lunch',
        index: 0,
      ),
      TimeConfigSlot(
        label: "Period 5",
        startTime: "02:15",
        endTime: "03:15",
        type: 'period',
        index: 5,
      ),
      TimeConfigSlot(
        label: "Period 6",
        startTime: "03:15",
        endTime: "04:15",
        type: 'period',
        index: 6,
      ),
    ];

    // Early Lunch Layout (Lunch at 12:15) for Year 1
    final year1Slots = [
      TimeConfigSlot(
        label: "Period 1",
        startTime: "08:45",
        endTime: "09:45",
        type: 'period',
        index: 1,
      ),
      TimeConfigSlot(
        label: "Period 2",
        startTime: "09:45",
        endTime: "10:45",
        type: 'period',
        index: 2,
      ),
      TimeConfigSlot(
        label: "BREAK",
        startTime: "10:45",
        endTime: "11:15",
        type: 'break',
        index: 0,
      ),
      TimeConfigSlot(
        label: "Period 3",
        startTime: "11:15",
        endTime: "12:15",
        type: 'period',
        index: 3,
      ),
      TimeConfigSlot(
        label: "LUNCH",
        startTime: "12:15",
        endTime: "01:15",
        type: 'lunch',
        index: 0,
      ),
      TimeConfigSlot(
        label: "Period 4",
        startTime: "01:15",
        endTime: "02:15",
        type: 'period',
        index: 4,
      ),
      TimeConfigSlot(
        label: "Period 5",
        startTime: "02:15",
        endTime: "03:15",
        type: 'period',
        index: 5,
      ),
      TimeConfigSlot(
        label: "Period 6",
        startTime: "03:15",
        endTime: "04:15",
        type: 'period',
        index: 6,
      ),
    ];

    _yearConfigs['1'] = year1Slots;
    _yearConfigs['2'] = defaultSlots;
    _yearConfigs['3'] = defaultSlots;
    _yearConfigs['4'] = defaultSlots;
    _yearConfigs['5'] = defaultSlots;
  }

  List<TimeConfigSlot> _getDefaultConfig(String year) {
    // If not found, return defaultSlots logic
    return [
      TimeConfigSlot(
        label: "Period 1",
        startTime: "08:45",
        endTime: "09:45",
        type: 'period',
        index: 1,
      ),
      TimeConfigSlot(
        label: "Period 2",
        startTime: "09:45",
        endTime: "10:45",
        type: 'period',
        index: 2,
      ),
      TimeConfigSlot(
        label: "BREAK",
        startTime: "10:45",
        endTime: "11:15",
        type: 'break',
        index: 0,
      ),
      TimeConfigSlot(
        label: "Period 3",
        startTime: "11:15",
        endTime: "12:15",
        type: 'period',
        index: 3,
      ),
      TimeConfigSlot(
        label: "Period 4",
        startTime: "12:15",
        endTime: "01:15",
        type: 'period',
        index: 4,
      ),
      TimeConfigSlot(
        label: "LUNCH",
        startTime: "01:15",
        endTime: "02:15",
        type: 'lunch',
        index: 0,
      ),
      TimeConfigSlot(
        label: "Period 5",
        startTime: "02:15",
        endTime: "03:15",
        type: 'period',
        index: 5,
      ),
      TimeConfigSlot(
        label: "Period 6",
        startTime: "03:15",
        endTime: "04:15",
        type: 'period',
        index: 6,
      ),
    ];
  }
}
