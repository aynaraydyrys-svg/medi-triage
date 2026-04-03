import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../core/utils/app_constants.dart';
import '../models/photo_triage_result.dart';

class SymptomPhotoTriageService {
  static const _apiKey = String.fromEnvironment('SYMPTOM_PHOTO_TRIAGE_API_KEY');
  static const _endpoint = String.fromEnvironment(
    'SYMPTOM_PHOTO_TRIAGE_ENDPOINT',
  );

  final Map<String, List<String>> _visualKeywords = const {
    'Dermatologist': <String>[
      'rash',
      'сыпь',
      'itch',
      'зуд',
      'itching',
      'skin',
      'кожа',
      'mole',
      'родинка',
      'acne',
      'акне',
      'eczema',
      'экзема',
      'redness',
      'покраснение',
      'hives',
      'крапивница',
      'lesion',
      'пятно',
      'patch',
    ],
    'Orthopedic': <String>[
      'sprain',
      'растяжение',
      'ankle',
      'лодыжка',
      'knee',
      'колено',
      'joint',
      'сустав',
      'wrist',
      'запястье',
      'fall',
      'падение',
      'twist',
    ],
    'Surgeon': <String>[
      'swelling',
      'отек',
      'bruise',
      'синяк',
      'wound',
      'рана',
      'cut',
      'порез',
      'bleeding',
      'кровотечение',
      'injury',
      'травма',
      'stitch',
      'шов',
    ],
    'ENT': <String>[
      'throat',
      'горло',
      'tonsil',
      'ear',
      'ухо',
      'sinus',
      'mouth',
      'рот',
      'tongue',
      'язык',
    ],
    'General Practitioner': <String>['bite', 'укус', 'fever', 'температура'],
  };

  Future<PhotoTriageResult> analyzePhoto({
    required String symptomsText,
    required String imageName,
    String? imageUrl,
    String? specialtyHint,
  }) async {
    if (imageUrl != null && _endpoint.isNotEmpty && _apiKey.isNotEmpty) {
      final remote = await _remoteAnalyze(
        symptomsText: symptomsText,
        imageUrl: imageUrl,
        specialtyHint: specialtyHint,
      );
      if (remote != null) {
        return remote;
      }
    }

    return _localAnalyze(
      symptomsText: symptomsText,
      imageName: imageName,
      specialtyHint: specialtyHint,
    );
  }

  Future<PhotoTriageResult?> _remoteAnalyze({
    required String symptomsText,
    required String imageUrl,
    String? specialtyHint,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(<String, dynamic>{
          'task': 'photo_assisted_medical_triage',
          'symptomsText': symptomsText,
          'imageUrl': imageUrl,
          'specialtyHint': specialtyHint,
          'guardrails': const <String>[
            'Do not diagnose.',
            'Return a suggested medical specialty only.',
            'Emphasize whether in-person assessment is recommended.',
          ],
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final specialty = data['suggestedSpecialty']?.toString();
      if (specialty == null || specialty.isEmpty) {
        return null;
      }

      return PhotoTriageResult(
        suggestedSpecialty: specialty,
        summary: data['summary']?.toString() ?? 'Photo analyzed',
        visualSignals: (data['visualSignals'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(),
        needsInPersonExam: data['needsInPersonExam'] == true,
        confidenceScore:
            double.tryParse(data['confidence']?.toString() ?? '') ?? 0.78,
        usedExternalAi: true,
        sourceLabel: 'Photo AI',
      );
    } catch (_) {
      return null;
    }
  }

  PhotoTriageResult _localAnalyze({
    required String symptomsText,
    required String imageName,
    String? specialtyHint,
  }) {
    final context = '${symptomsText.toLowerCase()} ${imageName.toLowerCase()}';
    String bestSpecialty = specialtyHint ?? 'General Practitioner';
    int bestScore = 0;
    List<String> visualSignals = const <String>[];

    for (final entry in _visualKeywords.entries) {
      final matches = entry.value.where(context.contains).toList();
      if (matches.length > bestScore) {
        bestScore = matches.length;
        bestSpecialty = entry.key;
        visualSignals = matches;
      }
    }

    if (bestScore == 0 && (specialtyHint == null || specialtyHint.isEmpty)) {
      bestSpecialty = 'General Practitioner';
      visualSignals = const <String>['photo added'];
    }

    final summary = bestScore == 0
        ? 'Photo saved'
        : '${AppConstants.specialtyLabel(bestSpecialty)} fits';

    return PhotoTriageResult(
      suggestedSpecialty: bestSpecialty,
      summary: summary,
      visualSignals: visualSignals,
      needsInPersonExam: true,
      confidenceScore: min(0.88, 0.58 + (bestScore * 0.1)),
      usedExternalAi: false,
      sourceLabel: 'Photo AI',
    );
  }
}
