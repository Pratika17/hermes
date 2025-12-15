import 'package:flutter/material.dart';

class DayOrderProvider with ChangeNotifier {
  int _totalDayOrders = 5;
  int _hoursPerDay = 6;

  int get totalDayOrders => _totalDayOrders;
  int get hoursPerDay => _hoursPerDay;

  void updateSettings({int? totalDays, int? hours}) {
    if (totalDays != null) _totalDayOrders = totalDays;
    if (hours != null) _hoursPerDay = hours;
    notifyListeners();
  }
}
