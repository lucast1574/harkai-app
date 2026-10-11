import 'package:flutter/material.dart';
import 'core/api_client.dart';
import 'core/app_controller.dart';
import 'core/app_scope.dart';
import 'core/theme.dart';
import 'features/navigation/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController(ApiClient());
  runApp(HarkaiApp(controller: controller));
  await controller.initialize();
  return;
}

class HarkaiApp extends StatelessWidget {
  final AppController controller;
  const HarkaiApp({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => AppScope(
    controller: controller,
    child: ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final theme = controller.account?.preferences.theme;
        return MaterialApp(
          title: 'Harkai',
          debugShowCheckedModeBanner: false,
          theme: appTheme(Brightness.light),
          darkTheme: appTheme(Brightness.dark),
          themeMode: theme == 'dark'
              ? ThemeMode.dark
              : theme == 'light'
              ? ThemeMode.light
              : ThemeMode.system,
          home: const AppShell(),
        );
      },
    ),
  );
}
