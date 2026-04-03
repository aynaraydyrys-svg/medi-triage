import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/enums/subscription_plan.dart';
import '../../core/utils/app_constants.dart';
import '../../models/care_recommendation.dart';
import '../../models/symptom_log.dart';
import '../../providers/auth_controller.dart';
import '../../repositories/symptom_repository.dart';
import '../../services/care_recommendation_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_gradient_background.dart';
import '../../widgets/section_card.dart';
import '../../widgets/xfile_image_preview.dart';
import '../common/plan_selection_screen.dart';
import 'specialty_recommendation_screen.dart';

class SymptomInputScreen extends StatefulWidget {
  const SymptomInputScreen({
    super.key,
    this.initialSymptoms,
    this.embedded = false,
  });

  final String? initialSymptoms;
  final bool embedded;

  @override
  State<SymptomInputScreen> createState() => _SymptomInputScreenState();
}

class _SymptomInputScreenState extends State<SymptomInputScreen> {
  final TextEditingController _symptomController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  bool _isSubmitting = false;
  String _loadingLabel = 'AI...';

  @override
  void initState() {
    super.initState();
    _symptomController.text = widget.initialSymptoms ?? '';
  }

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final nextPlan = auth.upgradeTargetPlan;
    final canSubmit =
        _selectedImage != null || _symptomController.text.trim().isNotEmpty;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.embedded ? 'AI Scan' : 'Symptoms',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFF0F6FFF),
                  Color(0xFF57B4FF),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Photo and text',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 10),
                const _InputModeRow(),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Symptoms',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _symptomController,
                  maxLines: 5,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Symptoms',
                    hintText: 'Pain, rash, cough',
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: AppConstants.symptomPrompts
                      .map(
                        (prompt) => ActionChip(
                          label: Text(prompt),
                          onPressed: _isSubmitting
                              ? null
                              : () => _appendPrompt(prompt),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Photo',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_selectedImage != null)
                  XFileImagePreview(file: _selectedImage!, height: 220)
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundAlt,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.photo_camera_back_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Upload',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(
                          _selectedImage == null ? 'Gallery' : 'Change',
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedImage != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            setState(() {
                              _selectedImage = null;
                            });
                            _showInfo('Photo removed');
                          },
                    child: const Text('Remove'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            backgroundColor: AppColors.backgroundAlt,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.currentPlanLabel,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            auth.subscriptionPlan.priceLabel,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: _isSubmitting ? null : _openPlans,
                      child: const Text('Upgrade'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _UsagePill(
                      label: auth.subscriptionPlan.aiAnalysisLimit == null
                          ? 'AI: no limit'
                          : 'AI: ${auth.remainingAiAnalyses}',
                    ),
                    _UsagePill(
                      label: auth.subscriptionPlan.photoAnalysisLimit == null
                          ? 'Photo: no limit'
                          : 'Photo: ${auth.remainingPhotoAnalyses}',
                    ),
                    _UsagePill(
                      label: auth.subscriptionPlan.familyMemberLimit == null
                          ? 'Family: no limit'
                          : 'Family: up to ${auth.subscriptionPlan.familyMemberLimit}',
                    ),
                  ],
                ),
                if (nextPlan != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Next: ${nextPlan.label}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            backgroundColor: AppColors.surfaceMuted,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSubmitting ? 'AI analysis' : 'Safety',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                if (_isSubmitting) ...[
                  const LinearProgressIndicator(minHeight: 8),
                  const SizedBox(height: 12),
                  Text(_loadingLabel),
                ] else
                  Text(AppConstants.matchingDisclaimer),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmitting || !canSubmit ? null : _submitSymptoms,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text('Analyze'),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AI Scan')),
      body: AppGradientBackground(
        child: SafeArea(top: false, child: content),
      ),
    );
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _appendPrompt(String prompt) {
    final existing = _symptomController.text.trim();
    setState(() {
      _symptomController.text = existing.isEmpty
          ? prompt
          : '$existing, $prompt';
      _symptomController.selection = TextSelection.fromPosition(
        TextPosition(offset: _symptomController.text.length),
      );
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;

    if (user == null) {
      _showInfo('Please log in again');
      return;
    }

    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 82,
      );

      if (image == null) {
        return;
      }

      setState(() {
        _selectedImage = image;
      });

      _showInfo(
        source == ImageSource.camera ? 'Photo captured' : 'Photo selected',
      );
    } catch (e) {
      _showInfo(
        source == ImageSource.camera
            ? 'Camera unavailable'
            : 'Gallery unavailable',
      );
    }
  }

  Future<void> _openPlans() async {
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PlanSelectionScreen(),
        ),
      );
    } catch (e) {
      _showInfo('Could not open plans');
    }
  }

  Future<void> _submitSymptoms() async {
    if (_isSubmitting) return;

    String symptomsText = _symptomController.text.trim();

    if (_selectedImage == null && symptomsText.isEmpty) {
      _showInfo('Add symptoms or photo');
      return;
    }

    if (symptomsText.isEmpty) {
      symptomsText = 'General symptoms';
    }

    final auth = context.read<AuthController>();
    final storageService = context.read<StorageService>();
    final careRecommendationService = context.read<CareRecommendationService>();
    final symptomRepository = context.read<SymptomRepository>();
    final user = auth.currentUser;

    if (user == null) {
      _showInfo('Please log in again');
      return;
    }

    final withPhoto = _selectedImage != null;

    if (!auth.canRunAnalysis(withPhoto: withPhoto)) {
      await _showLimitDialog(auth, withPhoto: withPhoto);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _loadingLabel = 'Preparing...';
    });

    try {
      String? imageUrl;

      if (_selectedImage != null) {
        setState(() {
          _loadingLabel = 'Uploading...';
        });

        imageUrl = await storageService.uploadImage(
          file: _selectedImage!,
          folder: 'symptom_images',
          ownerId: user.uid,
        );
      }

      setState(() {
        _loadingLabel = 'AI analysis...';
      });

      final recommendation = await careRecommendationService.analyzeCareNeed(
        symptomsText: symptomsText,
        symptomImageUrl: imageUrl,
        imageName: _selectedImage?.name,
      );

      final log = _buildSymptomLog(
        userId: user.uid,
        imageUrl: imageUrl,
        recommendation: recommendation,
        symptomsText: symptomsText,
      );

      setState(() {
        _loadingLabel = 'Saving...';
      });

      print('SAVE TEST 1: before createLog');
      await symptomRepository.createLog(log);
      print('SAVE TEST 2: after createLog');

      print('SAVE TEST 3: before recordAnalysisUsage');
      await auth.recordAnalysisUsage(withPhoto: withPhoto);
      print('SAVE TEST 4: after recordAnalysisUsage');

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SpecialtyRecommendationScreen(
            recommendation: recommendation,
            symptomLog: log,
          ),
        ),
      );
    } catch (error) {
      _showInfo('Analyze failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _loadingLabel = 'AI...';
        });
      }
    }
  }

  Future<void> _showLimitDialog(
    AuthController auth, {
    required bool withPhoto,
  }) async {
    final cta = auth.analysisLimitCtaLabel(withPhoto: withPhoto);

    final openPlans = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Limit reached'),
          content: Text(
            withPhoto
                ? 'Photo analysis unavailable'
                : 'AI analysis unavailable',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Later'),
            ),
            if (cta != null)
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(cta),
              ),
          ],
        );
      },
    );

    if (openPlans == true && mounted) {
      await _openPlans();
    }
  }

  SymptomLog _buildSymptomLog({
    required String userId,
    required String? imageUrl,
    required CareRecommendation recommendation,
    required String symptomsText,
  }) {
    final keywords = <String>{
      ...recommendation.specialtyMatch.matchedKeywords,
      ...?recommendation.photoTriageResult?.visualSignals,
    }.toList();

    return SymptomLog(
      logId: const Uuid().v4(),
      patientId: userId,
      symptomsText: symptomsText,
      symptomImageUrl: imageUrl,
      aiRecommendedSpecialty: recommendation.recommendedSpecialty,
      createdAt: DateTime.now(),
      matchedKeywords: keywords,
      urgencyLevel: recommendation.triageAssessment.urgencyLevel,
      triageSummary: recommendation.triageAssessment.summary,
      photoSuggestedSpecialty:
          recommendation.photoTriageResult?.suggestedSpecialty,
      photoTriageSummary: recommendation.photoTriageResult?.summary,
    );
  }
}

class _InputModeRow extends StatelessWidget {
  const _InputModeRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: const [
        _ModeChip(icon: Icons.edit_note_rounded, label: 'Symptoms'),
        _ModeChip(icon: Icons.photo_camera_back_outlined, label: 'Photo'),
        _ModeChip(icon: Icons.emergency_outlined, label: 'Urgency'),
      ],
    );
  }
}

class _UsagePill extends StatelessWidget {
  const _UsagePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}