import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/specialist_dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return FutureBuilder<void>(
      future: auth.status == AuthStatus.initial
          ? auth.tryAutoLogin()
          : Future.value(),
      builder: (context, _) {
        if (auth.status == AuthStatus.loading || auth.status == AuthStatus.initial) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        final userRole = auth.user?.role.toLowerCase() ?? 'patient';
        if (userRole == 'specialist') {
          return const SpecialistDashboardScreen();
        }

        return const DashboardScreen();
      },
    );
  }
}
