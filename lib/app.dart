import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medical_management_app/theme/app_theme.dart';

import 'auth_wrapper.dart';
import 'config/flavor_config.dart';
import 'providers/auth_provider.dart';
import 'providers/checklist_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/medicine_provider.dart';
import 'screens/appointment_history_screen.dart';
import 'screens/chat_thread_list_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_sample_request_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/specialist_availability_screen.dart';
import 'screens/specialist_dashboard_screen.dart';
import 'screens/specialist_discovery_screen.dart';
import 'screens/specialist_home_samples_screen.dart';
import 'screens/specialist_profile_screen.dart';
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
        theme: AppTheme.light(),
        themeAnimationDuration: const Duration(milliseconds: 250),
        themeAnimationCurve: Curves.easeInOut,
        initialRoute: AuthWrapper.routeName,
        routes: {
          AuthWrapper.routeName: (_) => const AuthWrapper(),
          LoginScreen.routeName: (_) => const LoginScreen(),
          RegisterScreen.routeName: (_) => const RegisterScreen(),
          AppointmentHistoryScreen.patientRouteName: (_) =>
              const AppointmentHistoryScreen(role: 'patient'),
          AppointmentHistoryScreen.specialistRouteName: (_) =>
              const AppointmentHistoryScreen(role: 'specialist'),
          ChatThreadListScreen.patientRouteName: (_) =>
              const ChatThreadListScreen(role: 'patient'),
          ChatThreadListScreen.specialistRouteName: (_) =>
              const ChatThreadListScreen(role: 'specialist'),
          HomeSampleRequestScreen.routeName: (_) =>
              const HomeSampleRequestScreen(),
          DashboardScreen.routeName: (_) => const DashboardScreen(),
          SpecialistDashboardScreen.routeName: (_) =>
              const SpecialistDashboardScreen(),
          SpecialistAvailabilityScreen.routeName: (_) =>
              const SpecialistAvailabilityScreen(),
          SpecialistDiscoveryScreen.routeName: (_) =>
              const SpecialistDiscoveryScreen(),
          SpecialistHomeSamplesScreen.routeName: (_) =>
              const SpecialistHomeSamplesScreen(),
          SpecialistProfileScreen.routeName: (_) =>
              const SpecialistProfileScreen(),
        },
      ),
    );
  }
}
