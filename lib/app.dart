import 'package:flutter/material.dart';

import 'screens/auth/sign_in_screen.dart';
import 'theme/app_theme.dart';

class MediTriageApp extends StatelessWidget {
  const MediTriageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediTriage',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // 🔥 ТІКЕЛЕЙ LOGIN-ҒА ӨТЕДІ
      home: const SignInScreen(),
    );
  }
}