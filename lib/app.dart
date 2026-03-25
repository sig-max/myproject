import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/flavor_config.dart';
import 'providers/auth_provider.dart';
import 'providers/checklist_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/medicine_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/checklist_service.dart';
import 'services/expense_service.dart';
import 'services/medicine_service.dart';
import 'services/notification_service.dart';

Future<void> runMedicalApp(AppFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.initialize(flavor: flavor);
  await NotificationService.instance.initialize();

  final apiService = ApiService();
  runApp(MyApp(apiService: apiService));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.apiService});

  final ApiService apiService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: AuthService(apiService)),
        ),
        ChangeNotifierProvider(
          create: (_) => MedicineProvider(
            medicineService: MedicineService(apiService),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ChecklistProvider(
            checklistService: ChecklistService(apiService),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider(
            expenseService: ExpenseService(apiService),
          ),
        ),
      ],
      child: MaterialApp(
        title: FlavorConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const DashboardScreen(),
        routes: {
          LoginScreen.routeName: (_) => const LoginScreen(),
          RegisterScreen.routeName: (_) => const RegisterScreen(),
          DashboardScreen.routeName: (_) => const DashboardScreen(),
        },
      ),
    );
  }
}
