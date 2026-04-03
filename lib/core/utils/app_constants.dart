class AppConstants {
  static const appName = 'MediTriage';
  static const valueProposition = 'AI triage. Doctor. Booking.';
  static const matchingDisclaimer = 'Not a diagnosis.';
  static const triageDisclaimer = 'Not a diagnosis.';
  static const problemStatement = 'Start with symptoms.';
  static const businessModelNote = 'Quick start.';
  static const startupPromise = 'Symptoms. Doctor. Booking.';

  static const specialties = <String>[
    'General Practitioner',
    'Cardiologist',
    'Neurologist',
    'Dermatologist',
    'Gastroenterologist',
    'ENT',
    'Pulmonologist',
    'Orthopedic',
    'Gynecologist',
    'Pediatrician',
    'Surgeon',
  ];

  static const specialtyLabels = <String, String>{
    'General Practitioner': 'Therapist',
    'Cardiologist': 'Cardiologist',
    'Neurologist': 'Neurologist',
    'Dermatologist': 'Dermatologist',
    'Gastroenterologist': 'Gastroenterologist',
    'ENT': 'ENT',
    'Pulmonologist': 'Pulmonologist',
    'Orthopedic': 'Orthopedic',
    'Gynecologist': 'Gynecologist',
    'Pediatrician': 'Pediatrician',
    'Surgeon': 'Surgeon',
  };

  // Keep stored values compatible with existing preview/profile data.
  static const patientGenders = <String>['Женщина', 'Мужчина', 'Другое'];

  // Keep stored values compatible with existing family records.
  static const familyRelations = <String>[
    'Ребёнок',
    'Мама',
    'Папа',
    'Бабушка',
    'Дедушка',
    'Супруга',
    'Супруг',
    'Сестра',
    'Брат',
    'Другой',
  ];

  // Keep stored values compatible with existing doctor/user city data.
  static const kzCities = <String>[
    'Алматы',
    'Астана',
    'Шымкент',
    'Тараз',
    'Актобе',
    'Караганда',
    'Атырау',
    'Актау',
    'Павлодар',
    'Семей',
    'Костанай',
    'Уральск',
    'Кызылорда',
    'Усть-Каменогорск',
    'Туркестан',
    'Петропавловск',
    'Кокшетау',
    'Талдыкорган',
  ];

  static const symptomPrompts = <String>[
    'Chest pain',
    'Rash',
    'Migraine',
    'Stomach pain',
    'Ear pain',
    'Bite',
    'Joint swelling',
  ];

  static String specialtyLabel(String specialty) {
    return specialtyLabels[specialty] ?? specialty;
  }

  static String cityLabel(String city) {
    switch (city.trim()) {
      case 'Алматы':
        return 'Almaty';
      case 'Астана':
        return 'Astana';
      case 'Шымкент':
        return 'Shymkent';
      case 'Тараз':
        return 'Taraz';
      case 'Актобе':
        return 'Aktobe';
      case 'Караганда':
        return 'Karaganda';
      case 'Атырау':
        return 'Atyrau';
      case 'Актау':
        return 'Aktau';
      case 'Павлодар':
        return 'Pavlodar';
      case 'Семей':
        return 'Semey';
      case 'Костанай':
        return 'Kostanay';
      case 'Уральск':
        return 'Oral';
      case 'Кызылорда':
        return 'Kyzylorda';
      case 'Усть-Каменогорск':
        return 'Oskemen';
      case 'Туркестан':
        return 'Turkistan';
      case 'Петропавловск':
        return 'Petropavl';
      case 'Кокшетау':
        return 'Kokshetau';
      case 'Талдыкорган':
        return 'Taldykorgan';
      default:
        return city;
    }
  }

  static String genderLabel(String gender) {
    switch (gender.trim()) {
      case 'Женщина':
        return 'Female';
      case 'Мужчина':
        return 'Male';
      case 'Другое':
        return 'Other';
      default:
        return gender;
    }
  }

  static String relationLabel(String relation) {
    switch (relation.trim()) {
      case 'Ребёнок':
        return 'Child';
      case 'Мама':
        return 'Mother';
      case 'Папа':
        return 'Father';
      case 'Бабушка':
        return 'Grandmother';
      case 'Дедушка':
        return 'Grandfather';
      case 'Супруга':
        return 'Wife';
      case 'Супруг':
        return 'Husband';
      case 'Сестра':
        return 'Sister';
      case 'Брат':
        return 'Brother';
      case 'Другой':
        return 'Other';
      default:
        return relation;
    }
  }

  static List<String> parseItems(String input) {
    return input
        .split(RegExp(r'[\n,;]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String familyBookingLabel(String relation) {
    switch (relation.trim()) {
      case 'Ребёнок':
      case 'Child':
        return 'For child';
      case 'Мама':
      case 'Mother':
        return 'For mother';
      case 'Папа':
      case 'Father':
        return 'For father';
      case 'Бабушка':
      case 'Grandmother':
        return 'For grandmother';
      case 'Дедушка':
      case 'Grandfather':
        return 'For grandfather';
      case 'Супруга':
      case 'Wife':
        return 'For wife';
      case 'Супруг':
      case 'Husband':
        return 'For husband';
      case 'Сестра':
      case 'Sister':
        return 'For sister';
      case 'Брат':
      case 'Brother':
        return 'For brother';
      default:
        return 'For family member';
    }
  }
}
