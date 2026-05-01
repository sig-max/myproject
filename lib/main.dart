import 'package:flutter/foundation.dart';
import 'app.dart';
import 'config/flavor_config.dart';

Future<void> main() async {
  // Use production flavor for release builds, dev for others.
  final flavor = kReleaseMode ? AppFlavor.prod : AppFlavor.dev;
  await runMedicalApp(flavor);
}

