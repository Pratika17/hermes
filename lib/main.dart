import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/subject_provider.dart';
import 'providers/faculty_provider.dart';
import 'providers/timetable_provider.dart';
import 'providers/day_order_provider.dart';
import 'providers/theme_provider.dart';
import 'services/timetable_generator_service.dart';
import 'screens/auth/login_screen.dart';

import 'providers/time_config_provider.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const AcadSyncApp());
}

class AcadSyncApp extends StatelessWidget {
  const AcadSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SubjectProvider()),
        ChangeNotifierProvider(create: (_) => FacultyProvider()),
        ChangeNotifierProvider(create: (_) => TimetableProvider()),
        ChangeNotifierProvider(create: (_) => DayOrderProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TimeConfigProvider()), // Added
        Provider(create: (_) => TimetableGeneratorService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'AcadSync',
            theme: AppTheme.lightTheme,
            darkTheme: ThemeData.dark(), // Placeholder for now
            themeMode: themeProvider.themeMode,
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}
