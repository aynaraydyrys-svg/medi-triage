import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/bootstrap/app_environment.dart';

class PreviewModeNotice extends StatelessWidget {
  const PreviewModeNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final environment = context.watch<AppEnvironment>();
    if (!environment.hasStartupNotice) {
      return const SizedBox.shrink();
    }
    return Text(
      environment.startupNotice ?? '',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
