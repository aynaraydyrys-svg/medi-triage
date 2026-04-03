import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../providers/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_gradient_background.dart';
import '../../widgets/brand_badge.dart';
import '../../widgets/section_card.dart';
import 'role_selection_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthController>().clearError();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandBadge(),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[Color(0xFF0F6FFF), Color(0xFF55B2FF)],
                        ),
                      ),
                      child: const Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _SignInChip(label: 'AI'),
                          _SignInChip(label: 'Photo'),
                          _SignInChip(label: 'Doctor'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SectionCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Login',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                              ),
                              validator: Validators.email,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                              ),
                              validator: Validators.password,
                            ),
                            if (auth.errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                auth.errorMessage!,
                                style: const TextStyle(color: AppColors.danger),
                              ),
                            ],
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: auth.isBusy ? null : _handleEmailSignIn,
                              child: auth.isBusy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Login'),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: auth.isBusy
                                  ? null
                                  : () async {
                                      auth.clearError();
                                      try {
                                        await context.read<AuthController>().signInWithGoogle();
                                      } catch (_) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Google sign-in failed'),
                                          ),
                                        );
                                      }
                                    },
                              icon: const Icon(Icons.login),
                              label: const Text('Continue with Google'),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: auth.isBusy
                                  ? null
                                  : () {
                                      auth.clearError();
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => const RoleSelectionScreen(),
                                        ),
                                      );
                                    },
                              child: const Text('Sign Up'),
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
        ),
      ),
    );
  }

  Future<void> _handleEmailSignIn() async {
    final auth = context.read<AuthController>();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    auth.clearError();
    try {
      await auth.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (_) {}
  }
}

class _SignInChip extends StatelessWidget {
  const _SignInChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
