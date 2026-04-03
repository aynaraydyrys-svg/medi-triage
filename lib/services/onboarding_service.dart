import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService extends ChangeNotifier {
  static const _onboardingKey = 'medimatch_onboarding_seen';

  bool _isReady = false;
  bool _hasSeenOnboarding = false;

  bool get isReady => _isReady;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool(_onboardingKey) ?? false;
    _isReady = true;
    notifyListeners();
  }

  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    _hasSeenOnboarding = true;
    notifyListeners();
  }
}
