import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/database_helper.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ExpenseApp(database: DatabaseHelper.instance));
}

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key, required this.database});
  final DatabaseHelper database;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Sổ chi tiêu',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: LoginScreen(database: database),
  );
}
