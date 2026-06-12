import 'package:flutter/material.dart';

import 'l10n/l10n.dart';
import 'theme.dart';
import 'ui/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await localeController.load();
  runApp(const BorderlessMinerApp());
}

class BorderlessMinerApp extends StatelessWidget {
  const BorderlessMinerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Reconstrói todo o app quando o idioma muda.
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Borderless Miner',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          home: const DashboardScreen(),
        );
      },
    );
  }
}
