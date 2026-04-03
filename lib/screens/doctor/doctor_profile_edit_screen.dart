import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/enums/doctor_availability_status.dart';
import '../../core/utils/app_constants.dart';
import '../../models/doctor_profile.dart';
import '../../providers/auth_controller.dart';
import '../../repositories/doctor_repository.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/adaptive_image.dart';
import '../../widgets/app_gradient_background.dart';
import '../../widgets/section_card.dart';
import '../../widgets/xfile_image_preview.dart';

class DoctorProfileEditScreen extends StatefulWidget {
  const DoctorProfileEditScreen({super.key});

  @override
  State<DoctorProfileEditScreen> createState() =>
      _DoctorProfileEditScreenState();
}

class _DoctorProfileEditScreenState extends State<DoctorProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _clinicController = TextEditingController();
  final _cityController = TextEditingController();
  final _experienceController = TextEditingController();
  final _statusNoteController = TextEditingController();
  final _picker = ImagePicker();

  String _specialty = AppConstants.specialties.first;
  DoctorAvailabilityStatus _availabilityStatus =
      DoctorAvailabilityStatus.accepting;
  bool _offersTelehealth = false;
  XFile? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPickingImage = false;
  DoctorProfile? _currentProfile;

  static const Duration _profileLoadTimeout = Duration(seconds: 20);
  static const Duration _pickerTimeout = Duration(seconds: 45);

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _clinicController.dispose();
    _cityController.dispose();
    _experienceController.dispose();
    _statusNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: AppGradientBackground(
        child: SafeArea(
          top: false,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentProfile == null
                                    ? 'Doctor profile'
                                    : 'Edit profile',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Visible to patients',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 20),
                              _buildImagePreview(),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: (_isSaving || _isPickingImage)
                                    ? null
                                    : _pickImage,
                                icon: _isPickingImage
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.photo_camera_back_outlined,
                                      ),
                                label: Text(
                                  _isPickingImage ? 'Photo...' : 'Photo',
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                ),
                                validator: _required,
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                initialValue: _specialty,
                                items: AppConstants.specialties
                                    .map(
                                      (specialty) => DropdownMenuItem(
                                        value: specialty,
                                        child: Text(
                                          AppConstants.specialtyLabel(
                                            specialty,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setState(() {
                                    _specialty = value;
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Specialty',
                                ),
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<DoctorAvailabilityStatus>(
                                initialValue: _availabilityStatus,
                                items: DoctorAvailabilityStatus.values
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(status.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setState(() {
                                    _availabilityStatus = value;
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _clinicController,
                                decoration: const InputDecoration(
                                  labelText: 'Clinic',
                                ),
                                validator: _required,
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                initialValue:
                                    AppConstants.kzCities.contains(
                                      _cityController.text,
                                    )
                                    ? _cityController.text
                                    : AppConstants.kzCities.first,
                                items: AppConstants.kzCities
                                    .map(
                                      (city) => DropdownMenuItem<String>(
                                        value: city,
                                        child: Text(
                                          AppConstants.cityLabel(city),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  _cityController.text = value;
                                },
                                decoration: const InputDecoration(
                                  labelText: 'City',
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _experienceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Experience',
                                ),
                                validator: _required,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _bioController,
                                maxLines: 5,
                                decoration: const InputDecoration(
                                  labelText: 'About',
                                ),
                                validator: _required,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _statusNoteController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Note',
                                  hintText: 'Optional',
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: SwitchListTile.adaptive(
                                  value: _offersTelehealth,
                                  onChanged: (value) {
                                    setState(() {
                                      _offersTelehealth = value;
                                    });
                                  },
                                  title: const Text('Online'),
                                  subtitle: const Text('Video visit'),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _isSaving ? null : _saveProfile,
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
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _loadDoctorProfile() async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    debugPrint('DOCTOR PROFILE LOAD: started for uid=${user.uid}');
    try {
      final doctor = await context
          .read<DoctorRepository>()
          .fetchDoctor(user.uid)
          .timeout(_profileLoadTimeout);
      debugPrint('DOCTOR PROFILE LOAD: fetch finished');

      _currentProfile = doctor;
      _nameController.text = doctor?.name ?? user.fullName;
      _bioController.text = doctor?.bio ?? '';
      _clinicController.text =
          doctor?.clinicName ??
          (user.city.isEmpty
              ? 'MediTriage Clinic'
              : 'Clinic ${AppConstants.cityLabel(user.city)}');
      _cityController.text = doctor?.city ?? user.city;
      _experienceController.text = doctor?.yearsExperience.toString() ?? '';
      if (doctor == null) {
        _experienceController.text = '1';
      }
      _statusNoteController.text =
          doctor?.statusNote ??
          (user.city.isEmpty
              ? 'Ready for visits'
              : 'Visits in ${AppConstants.cityLabel(user.city)}');
      _specialty = doctor?.specialty ?? _specialty;
      _availabilityStatus = doctor?.availabilityStatus ?? _availabilityStatus;
      _offersTelehealth = doctor?.offersTelehealth ?? false;
      _existingImageUrl = doctor?.profileImageUrl;

      if (_cityController.text.trim().isEmpty) {
        _cityController.text = AppConstants.kzCities.first;
      }
      if (_clinicController.text.trim().isEmpty) {
        _clinicController.text = 'MediTriage Clinic';
      }
    } catch (error, stackTrace) {
      debugPrint('DOCTOR PROFILE LOAD ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        _showSnackBar(
          _friendlyError(
            error,
            'Unable to load your doctor profile. Please try again.',
          ),
        );
      }
    } finally {
      debugPrint('DOCTOR PROFILE LOAD: loading reset');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    debugPrint('PHOTO 1: button tapped');
    if (_isPickingImage) {
      return;
    }

    setState(() {
      _isPickingImage = true;
    });

    try {
      debugPrint('PHOTO 2: file pick started');
      final image = await _picker
          .pickImage(source: ImageSource.gallery, imageQuality: 82)
          .timeout(_pickerTimeout);
      if (image == null) {
        debugPrint('PHOTO 3: no file selected');
        return;
      }

      debugPrint('PHOTO 4: file selected');
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedImage = image;
      });
    } catch (error, stackTrace) {
      debugPrint('PHOTO PICK ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        _showSnackBar(
          _friendlyError(
            error,
            'Unable to select a photo right now. Please try again.',
          ),
        );
      }
    } finally {
      debugPrint('PHOTO PICK: picker loading reset');
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    debugPrint('SAVE 1: button tapped');
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    bool shouldLogPhotoReset = false;

    try {
      debugPrint('SAVE 2: validation started');
      final isValid = _formKey.currentState?.validate() ?? false;
      if (!isValid) {
        _showSnackBar('Please complete the required fields.');
        return;
      }

      final auth = context.read<AuthController>();
      final doctorRepository = context.read<DoctorRepository>();
      final user = auth.currentUser;
      if (user == null) {
        throw Exception('User profile unavailable. Please sign in again.');
      }

      final trimmedName = _nameController.text.trim();
      final trimmedClinic = _clinicController.text.trim();
      final trimmedCity = _cityController.text.trim();
      final trimmedBio = _bioController.text.trim();
      final trimmedStatusNote = _statusNoteController.text.trim();

      if (trimmedCity.isEmpty) {
        _showSnackBar('Please select a city.');
        return;
      }

      debugPrint('SAVE 3: validation passed');

      String? imageUrl = _existingImageUrl;
      if (_selectedImage != null) {
        shouldLogPhotoReset = true;
        imageUrl = await context.read<StorageService>().uploadImage(
          file: _selectedImage!,
          folder: 'doctor_profiles',
          ownerId: user.uid,
        );
      }

      final profile = DoctorProfile(
        doctorId: user.uid,
        uid: user.uid,
        name: trimmedName,
        specialty: _specialty,
        bio: trimmedBio,
        clinicName: trimmedClinic,
        address: _currentProfile?.address ?? '',
        city: trimmedCity,
        yearsExperience: int.tryParse(_experienceController.text.trim()) ?? 0,
        ratingAverage: _currentProfile?.ratingAverage ?? 0,
        reviewCount: _currentProfile?.reviewCount ?? 0,
        profileImageUrl: imageUrl,
        availableSlots: _currentProfile?.availableSlots ?? const [],
        createdAt: _currentProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        availabilityStatus: _availabilityStatus,
        statusNote: trimmedStatusNote,
        offersTelehealth: _offersTelehealth,
      );

      debugPrint('SAVE 4: firestore write started');
      if (shouldLogPhotoReset) {
        debugPrint('PHOTO 9: firestore update started');
      }
      await doctorRepository.upsertDoctorProfile(profile);
      await auth.updateProfile(fullName: trimmedName, photoUrl: imageUrl);
      debugPrint('SAVE 5: firestore write finished');
      if (shouldLogPhotoReset) {
        debugPrint('PHOTO 10: firestore update finished');
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _currentProfile = profile;
        _existingImageUrl = imageUrl;
        _selectedImage = null;
      });
      debugPrint('SAVE 6: local refresh finished');
      if (shouldLogPhotoReset) {
        debugPrint('PHOTO 11: done');
      }
      debugPrint('SAVE 7: done');
      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      debugPrint('SAVE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        _showSnackBar(
          _friendlyError(error, 'Unable to save doctor profile right now.'),
        );
      }
    } finally {
      debugPrint('SAVE 8: loading reset');
      if (shouldLogPhotoReset) {
        debugPrint('PHOTO 12: loading reset');
      }
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return XFileImagePreview(file: _selectedImage!, height: 220);
    }

    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AdaptiveImage(
          imageUrl: _existingImageUrl!,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: Text('Add photo')),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
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
    if (error is TimeoutException) {
      return fallback;
    }
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
