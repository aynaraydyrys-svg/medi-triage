import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_gradient_background.dart';
import '../common/profile_settings_screen.dart';
import 'doctor_list_screen.dart';
import 'my_appointments_screen.dart';
import 'patient_home_screen.dart';
import 'symptom_input_screen.dart';

class PatientShellScreen extends StatefulWidget {
  const PatientShellScreen({super.key});

  @override
  State<PatientShellScreen> createState() => _PatientShellScreenState();
}

class _PatientShellScreenState extends State<PatientShellScreen> {
  int _currentIndex = 0;
  String? _aiInitialSymptoms;

  List<Widget> get _pages => [
    PatientHomeScreen(
      onOpenSearch: () => _selectTab(1),
      onOpenAi: () => _openAiTab(),
      onOpenAiWithSymptoms: _openAiTab,
    ),
    const DoctorListScreen(embedded: true),
    SymptomInputScreen(
      key: ValueKey(_aiInitialSymptoms ?? 'ai_tab'),
      embedded: true,
      initialSymptoms: _aiInitialSymptoms,
    ),
    const MyAppointmentsScreen(),
    const ProfileSettingsScreen(),
  ];

  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openAiTab([String? symptoms]) {
    setState(() {
      _aiInitialSymptoms = symptoms;
      _currentIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: AppGradientBackground(
          child: SafeArea(
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),
        ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppColors.softShadow,
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _selectTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_outlined),
                  selectedIcon: Icon(Icons.search_rounded),
                  label: 'Search',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome_rounded),
                  label: 'AI',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: 'Visits',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
