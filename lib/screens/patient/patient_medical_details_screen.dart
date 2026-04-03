import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/app_constants.dart';
import '../../providers/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_gradient_background.dart';
import '../../widgets/section_card.dart';

class PatientMedicalDetailsScreen extends StatefulWidget {
  const PatientMedicalDetailsScreen({super.key});

  @override
  State<PatientMedicalDetailsScreen> createState() =>
      _PatientMedicalDetailsScreenState();
}

class _PatientMedicalDetailsScreenState
    extends State<PatientMedicalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ageController;
  late final TextEditingController _basicInfoController;
  late final TextEditingController _diseasesController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _notesController;
  late String _selectedGender;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().currentUser;
    _ageController = TextEditingController(
      text: user?.age == null ? '' : '${user!.age}',
    );
    _basicInfoController = TextEditingController(
      text: user?.basicMedicalInfo ?? '',
    );
    _diseasesController = TextEditingController(
      text: user?.pastDiseases.join(', ') ?? '',
    );
    _allergiesController = TextEditingController(
      text: user?.allergies.join(', ') ?? '',
    );
    _notesController = TextEditingController(text: user?.notes ?? '');
    _selectedGender =
        user != null && AppConstants.patientGenders.contains(user.gender)
        ? user.gender
        : AppConstants.patientGenders.first;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _basicInfoController.dispose();
    _diseasesController.dispose();
    _allergiesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Medical details')),
      body: AppGradientBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFF0F6FFF), Color(0xFF57B4FF)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Only essentials',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add if needed',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SectionCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Age'),
                          validator: (value) {
                            final text = (value ?? '').trim();
                            if (text.isEmpty) {
                              return null;
                            }
                            final age = int.tryParse(text);
                            if (age == null || age < 1 || age > 120) {
                              return 'Age';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGender,
                          items: AppConstants.patientGenders
                              .map(
                                (gender) => DropdownMenuItem<String>(
                                  value: gender,
                                  child: Text(AppConstants.genderLabel(gender)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _selectedGender = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _basicInfoController,
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: 'Notes'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _diseasesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Conditions',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _allergiesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Allergies',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Extra notes',
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SectionCard(
                  backgroundColor: AppColors.surfaceMuted,
                  child: Text(
                    'AI summary uses this info',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    debugPrint('SAVE 1: button tapped');
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      debugPrint('SAVE 2: validation started');
      final isValid = _formKey.currentState?.validate() ?? false;
      if (!isValid) {
        _showSnackBar('Please fix the highlighted fields.');
        return;
      }

      final auth = context.read<AuthController>();
      final user = auth.currentUser;
      if (user == null) {
        throw Exception('User profile unavailable. Please sign in again.');
      }

      final trimmedAge = _ageController.text.trim();
      final trimmedBasicInfo = _basicInfoController.text.trim();
      final trimmedNotes = _notesController.text.trim();
      debugPrint('SAVE 3: validation passed');
      debugPrint('SAVE 4: firestore write started');
      await auth.updateProfile(
        age: int.tryParse(trimmedAge),
        gender: _selectedGender,
        basicMedicalInfo: trimmedBasicInfo,
        pastDiseases: AppConstants.parseItems(_diseasesController.text),
        allergies: AppConstants.parseItems(_allergiesController.text),
        notes: trimmedNotes,
      );
      debugPrint('SAVE 5: firestore write finished');

      if (!mounted) {
        return;
      }

      setState(() {
        _ageController.text = trimmedAge;
        _basicInfoController.text = trimmedBasicInfo;
        _notesController.text = trimmedNotes;
      });
      debugPrint('SAVE 6: local refresh finished');
      _showSnackBar('Details saved');
      debugPrint('SAVE 7: done');
    } catch (error, stackTrace) {
      debugPrint('SAVE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        _showSnackBar(_friendlyError(error, 'Unable to save medical details.'));
      }
    } finally {
      debugPrint('SAVE 8: loading reset');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlyError(Object error, String fallback) {
    final raw = error.toString().trim();
    if (raw.isEmpty || raw.contains('TimeoutException')) {
      return fallback;
    }
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }
}
