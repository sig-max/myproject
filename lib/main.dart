import 'app.dart';
import 'config/flavor_config.dart';

Future<void> main() async {
  await runMedicalApp(AppFlavor.dev);
} 

