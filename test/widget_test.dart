import 'package:flutter_test/flutter_test.dart';

import 'package:medical_management_app/app.dart';
import 'package:medical_management_app/config/flavor_config.dart';
import 'package:medical_management_app/services/api_service.dart';

void main() {
  testWidgets('App widget builds', (WidgetTester tester) async {
    FlavorConfig.initialize(flavor: AppFlavor.dev);

    await tester.pumpWidget(MyApp(apiService: ApiService()));
    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);
  });
}
