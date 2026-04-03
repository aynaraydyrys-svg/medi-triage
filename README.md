# MediMatch

MediMatch is an AI-powered healthcare MVP that helps users describe symptoms, get matched to the right specialist, and instantly book a real doctor.

## Problem

When symptoms appear, many people do not know which doctor to visit first. They often rely on friends, generic internet searches, or the nearest clinic instead of a focused path from symptom to specialist to booking.

## Solution

MediMatch solves one focused chain end-to-end:

`symptom → AI specialty recommendation → doctor list → doctor profile → slot booking → confirmation → review`

The app does **not** diagnose disease. It only recommends the most relevant medical specialty and helps users continue into real doctor booking.

## MVP Scope

### Patient flow
- Sign up with role selection
- Email/password authentication
- Google sign-in
- Email verification gate
- Symptom submission with optional image upload
- AI specialty recommendation with safe disclaimer
- Browse filtered doctors
- View doctor profile and available slots
- Book appointment
- See bookings in real time
- Leave and delete reviews

### Doctor flow
- Sign up as doctor
- Create and edit doctor profile
- Upload doctor profile image
- Add and delete available slots
- View patient bookings
- Update appointment status
- View reviews

## Technical Highlights

- Flutter + Dart
- Firebase Authentication
- Cloud Firestore as the main database
- Firebase Storage image upload
- Firebase Cloud Messaging-ready notification service
- Local notifications for booking confirmation/reminder placeholders
- Provider state management
- Clean, production-style folder architecture
- Real-time Firestore streams for bookings, doctors, reviews, and symptom logs

## Firebase Usage

### Collections

`users`
- `uid`
- `fullName`
- `email`
- `role`
- `photoUrl`
- `createdAt`
- `isEmailVerified`
- `fcmToken`

`doctors`
- `doctorId`
- `uid`
- `name`
- `specialty`
- `bio`
- `clinicName`
- `city`
- `yearsExperience`
- `ratingAverage`
- `reviewCount`
- `profileImageUrl`
- `availableSlots`
- `createdAt`
- `updatedAt`

`appointments`
- `appointmentId`
- `patientId`
- `patientName`
- `doctorId`
- `doctorName`
- `doctorImageUrl`
- `specialty`
- `symptomsText`
- `symptomImageUrl`
- `slotTime`
- `status`
- `createdAt`
- `updatedAt`

`reviews`
- `reviewId`
- `doctorId`
- `patientId`
- `patientName`
- `rating`
- `comment`
- `createdAt`

`symptom_logs`
- `logId`
- `patientId`
- `symptomsText`
- `symptomImageUrl`
- `aiRecommendedSpecialty`
- `matchedKeywords`
- `createdAt`

## Firebase Setup

This repository includes a compile-safe placeholder `lib/firebase_options.dart`.

Before using real Firebase services:

1. Create a Firebase project.
2. Enable:
   - Email/Password Authentication
   - Google Sign-In Authentication
   - Cloud Firestore
   - Firebase Storage
   - Firebase Cloud Messaging
3. Replace the placeholder values in [`lib/firebase_options.dart`](/Users/ainara/Desktop/MediMatch/lib/firebase_options.dart) with your real Firebase config, or regenerate it using FlutterFire CLI.
4. Configure Android and iOS Google sign-in according to your Firebase project.
5. Set Firestore and Storage rules suitable for your demo environment.

## AI Matching

The AI specialty matcher is implemented in [`lib/services/ai_specialty_matcher_service.dart`](/Users/ainara/Desktop/MediMatch/lib/services/ai_specialty_matcher_service.dart).

Behavior:
- If `AI_MATCHER_API_KEY` and `AI_MATCHER_ENDPOINT` are provided through `--dart-define`, the app can call a real remote specialty-matching endpoint.
- If no API configuration is present, the app falls back to a deterministic keyword-based specialty engine for demo reliability.

Example:

```bash
flutter run \
  --dart-define=AI_MATCHER_API_KEY=your_key \
  --dart-define=AI_MATCHER_ENDPOINT=https://your-endpoint.example.com/match
```

## Notifications

The project includes notification-ready architecture in [`lib/services/notification_service.dart`](/Users/ainara/Desktop/MediMatch/lib/services/notification_service.dart):

- notification permission request
- FCM token fetch and Firestore save
- foreground message listener
- local booking confirmation notification
- local reminder scheduling placeholder
- background message hook

For full production FCM delivery, connect Firebase Messaging fully on both mobile platforms and optionally add backend/cloud function triggers.

## Demo Data

On app startup, `SeedService` attempts to create sample doctors and reviews if the `doctors` collection is empty. This makes the patient booking flow easy to demo even before multiple real doctor accounts exist.

## Business Model Note

- Patients use MediMatch for free.
- Doctors can later pay subscription fees for profile visibility and booking exposure.

No payment flow is included in this MVP.

## Project Structure

```text
lib/
  core/
    enums/
    utils/
  models/
  providers/
  repositories/
  screens/
    auth/
    common/
    doctor/
    onboarding/
    patient/
    splash/
  services/
  theme/
  widgets/
```

## Launcher Icon Placeholder

A placeholder launcher icon config is already set in [`pubspec.yaml`](/Users/ainara/Desktop/MediMatch/pubspec.yaml) and points to:

[`assets/branding/launcher_icon_placeholder.png`](/Users/ainara/Desktop/MediMatch/assets/branding/launcher_icon_placeholder.png)

To generate icons:

```bash
dart run flutter_launcher_icons
```

## Run Locally

```bash
flutter pub get
flutter test
flutter run
```

## Suggested Judge Demo Flow

### Patient demo
1. Register a patient account.
2. Verify email.
3. Sign in.
4. Enter symptoms and optionally upload an image.
5. Get a specialty recommendation.
6. Open the filtered doctor list.
7. View a doctor profile.
8. Pick a slot and book.
9. Confirm the appointment.
10. Open My Appointments.
11. Mark the appointment completed from a doctor account.
12. Return and leave a review.

### Doctor demo
1. Register a doctor account.
2. Create the doctor profile.
3. Upload a profile image.
4. Add slots.
5. View bookings in the doctor dashboard.
6. Update appointment status.
7. Open doctor reviews.

## Notes

- The app is mobile-first and scaffolded for Android and iOS.
- Firebase is the primary backend source of truth.
- UI is focused on a polished healthcare startup MVP rather than extra non-core features.
