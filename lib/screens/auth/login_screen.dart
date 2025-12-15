import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
           // Check if we are on wide screen (Web) -> show side banner
           if (MediaQuery.of(context).size.width > 800)
             Expanded(
               child: Container(
                 color: Theme.of(context).colorScheme.primaryContainer,
                 child: Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.calendar_today, size: 100, color: Theme.of(context).colorScheme.onPrimaryContainer),
                       const SizedBox(height: 32),
                       Text('AcadSync', style: Theme.of(context).textTheme.displayMedium),
                       const SizedBox(height: 16),
                       Text('Automated Timetable Management', style: Theme.of(context).textTheme.headlineSmall),
                     ],
                   )
                 ),
               ),
             ),
             
           Expanded(
             child: Center(
               child: Container(
                 constraints: const BoxConstraints(maxWidth: 400),
                 padding: const EdgeInsets.all(32),
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   crossAxisAlignment: CrossAxisAlignment.stretch,
                   children: [
                     const Text('Welcome Back', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 8),
                     const Text('Please sign in to continue', style: TextStyle(color: Colors.grey)),
                     const SizedBox(height: 48),
                     
                     TextField(
                       decoration: const InputDecoration(
                         labelText: 'Email Address',
                         prefixIcon: Icon(Icons.email_outlined),
                         border: OutlineInputBorder(),
                       ),
                     ),
                     const SizedBox(height: 16),
                     TextField(
                       obscureText: true,
                       decoration: const InputDecoration(
                         labelText: 'Password',
                         prefixIcon: Icon(Icons.lock_outline),
                         border: OutlineInputBorder(),
                       ),
                     ),
                     const SizedBox(height: 32),
                     
                     FilledButton(
                       onPressed: () {
                          // Admin Login
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
                       },
                       style: FilledButton.styleFrom(padding: const EdgeInsets.all(20)),
                       child: const Text('Login as Admin', style: TextStyle(fontSize: 16)),
                     ),
                     const SizedBox(height: 16),
                     OutlinedButton(
                       onPressed: () {
                          // Faculty Login (Read-Only? For now same dashboard)
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
                       },
                       style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(20)),
                       child: const Text('Login as Faculty'),
                     ),
                   ],
                 ),
               ),
             ),
           )
        ],
      ),
    );
  }
}
