import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart'; // Import your screens
import 'screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Logic to check if a token exists in local storage
    // For now, we use a placeholder. 
    bool hasToken = false; 

    // 2. Decide which screen to show
   // The Clean "Flutter" Way
return hasToken 
    ? const DashboardScreen() 
    : const LoginScreen();
  }
}