import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../core/utils/app_constants.dart';
import '../models/specialty_match_result.dart';

class AiSpecialtyMatcherService {
  static const _apiKey = String.fromEnvironment('AI_MATCHER_API_KEY');
  static const _endpoint = String.fromEnvironment('AI_MATCHER_ENDPOINT');

  final Map<String, List<String>> _keywordMap = const {
    'Cardiologist': [
      'chest pain',
      'боль в груди',
      'давит в груди',
      'palpitations',
      'сердцебиение',
      'shortness of breath',
      'одышка',
      'high blood pressure',
      'давление',
      'heart',
      'сердце',
      'tightness',
      'тяжесть',
    ],
    'Neurologist': [
      'migraine',
      'мигрень',
      'dizziness',
      'головокружение',
      'seizure',
      'судороги',
      'tingling',
      'покалывание',
      'numbness',
      'онемение',
      'headache',
      'головная боль',
      'memory',
      'память',
    ],
    'Dermatologist': [
      'rash',
      'сыпь',
      'itch',
      'зуд',
      'acne',
      'акне',
      'eczema',
      'экзема',
      'skin',
      'кожа',
      'hives',
      'крапивница',
      'mole',
      'родинка',
    ],
    'Gastroenterologist': [
      'stomach',
      'желудок',
      'bloating',
      'вздутие',
      'constipation',
      'запор',
      'diarrhea',
      'диарея',
      'heartburn',
      'изжога',
      'nausea',
      'тошнота',
      'vomiting',
      'рвота',
      'abdominal',
      'живот',
    ],
    'ENT': [
      'sinus',
      'нос',
      'sore throat',
      'горло',
      'ear pain',
      'ухо',
      'earache',
      'blocked nose',
      'заложенность',
      'hearing',
      'слух',
      'tonsil',
      'миндалины',
      'nose',
    ],
    'Pulmonologist': [
      'wheezing',
      'хрипы',
      'cough',
      'кашель',
      'breathing',
      'дыхание',
      'asthma',
      'астма',
      'phlegm',
      'мокрота',
      'chest congestion',
      'затрудненное дыхание',
    ],
    'Orthopedic': [
      'joint pain',
      'боль в суставе',
      'back pain',
      'боль в спине',
      'knee',
      'колено',
      'bone',
      'кость',
      'fracture',
      'перелом',
      'ankle',
      'лодыжка',
      'shoulder',
      'плечо',
    ],
    'Gynecologist': [
      'pelvic pain',
      'тазовая боль',
      'period',
      'месячные',
      'menstrual',
      'цикл',
      'pregnancy',
      'беременность',
      'vaginal',
      'вагин',
      'cycle',
    ],
    'Pediatrician': [
      'child',
      'ребенок',
      'infant',
      'младенец',
      'baby',
      'малыш',
      'toddler',
      'pediatric',
      'fever in child',
      'температура у ребенка',
    ],
    'Surgeon': [
      'wound',
      'рана',
      'cut',
      'порез',
      'bruise',
      'синяк',
      'swelling',
      'отек',
      'injury',
      'травма',
      'bleeding',
      'кровотечение',
    ],
  };

  Future<SpecialtyMatchResult> matchSymptoms({
    required String symptomsText,
    String? symptomImageUrl,
  }) async {
    if (_endpoint.isNotEmpty && _apiKey.isNotEmpty) {
      final remote = await _remoteMatch(symptomsText, symptomImageUrl);
      if (remote != null) {
        return remote;
      }
    }

    return _localMatch(symptomsText);
  }

  Future<SpecialtyMatchResult?> _remoteMatch(
    String symptomsText,
    String? symptomImageUrl,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'task': 'recommend_medical_specialty_only',
          'symptomsText': symptomsText,
          'symptomImageUrl': symptomImageUrl,
          'guardrails': [
            'Do not diagnose disease.',
            'Return only the best-fit medical specialty.',
          ],
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final specialty = data['specialty']?.toString();
      if (specialty == null || specialty.isEmpty) {
        return null;
      }

      final keywords = (data['matchedKeywords'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList();

      return SpecialtyMatchResult(
        specialty: specialty,
        explanation: data['explanation']?.toString() ?? 'Best match',
        matchedKeywords: keywords,
        confidenceScore:
            double.tryParse(data['confidence']?.toString() ?? '') ?? 0.82,
        usedExternalAi: true,
      );
    } catch (_) {
      return null;
    }
  }

  SpecialtyMatchResult _localMatch(String symptomsText) {
    final text = symptomsText.toLowerCase();
    String bestSpecialty = 'General Practitioner';
    int bestScore = 0;
    List<String> matchedKeywords = <String>[];

    for (final entry in _keywordMap.entries) {
      final currentMatches = entry.value
          .where((keyword) => text.contains(keyword.toLowerCase()))
          .toList();
      if (currentMatches.length > bestScore) {
        bestScore = currentMatches.length;
        bestSpecialty = entry.key;
        matchedKeywords = currentMatches;
      }
    }

    if (bestScore == 0) {
      matchedKeywords = ['general review'];
    }

    final confidence = min(0.94, 0.56 + (bestScore * 0.09));
    final explanation = bestSpecialty == 'General Practitioner'
        ? 'Start with a general practitioner'
        : '${AppConstants.specialtyLabel(bestSpecialty)} fits';

    return SpecialtyMatchResult(
      specialty: bestSpecialty,
      explanation: explanation,
      matchedKeywords: matchedKeywords,
      confidenceScore: confidence,
      usedExternalAi: false,
    );
  }
}
