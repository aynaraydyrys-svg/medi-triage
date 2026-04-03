class AppEnvironment {
  const AppEnvironment({
    required this.firebaseEnabled,
    required this.previewMode,
    this.startupNotice,
    this.startupError,
  });

  final bool firebaseEnabled;
  final bool previewMode;
  final String? startupNotice;
  final Object? startupError;

  bool get hasStartupNotice =>
      startupNotice != null && startupNotice!.isNotEmpty;
}
