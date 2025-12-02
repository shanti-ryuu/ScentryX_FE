import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/loading_indicator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await auth.login(email, password);
    if (!mounted) return;

    if (success) {
      Navigator.of(context)
          .pushReplacementNamed(AppRoutes.dashboard);
    } else {
      final pendingEmail = auth.pendingVerificationEmail;
      final message = pendingEmail != null
          ? 'Please verify the email we sent to $pendingEmail before logging in.'
          : auth.error ?? 'Login failed';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      if (pendingEmail != null) {
        Navigator.of(context)
            .pushReplacementNamed(AppRoutes.verifyEmail);
      }
    }
  }

  Widget _buildRememberMeToggle({required bool allowWrap}) {
    final label = Text(
      'Remember me',
      softWrap: true,
    );

    final checkbox = Checkbox(
      value: _rememberMe,
      onChanged: (value) {
        setState(() {
          _rememberMe = value ?? false;
        });
      },
    );

    if (allowWrap) {
      return InkWell(
        onTap: () {
          setState(() {
            _rememberMe = !_rememberMe;
          });
        },
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            checkbox,
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 0),
              child: label,
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () {
        setState(() {
          _rememberMe = !_rememberMe;
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          checkbox,
          const SizedBox(width: 8),
          label,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryBackground),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF5C6FF8), Color(0xFF8DA2FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.sensors,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'ScentryX',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Monitor gas leaks in real-time',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.black.withOpacity(0.65)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomTextField(
                              controller: _emailController,
                              label: 'Email',
                              hintText: 'sdca@gmail.com',
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hintText: 'Enter your password',
                              obscureText: _obscurePassword,
                              validator: _validatePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isTight = constraints.maxWidth < 360;

                                if (isTight) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: _buildRememberMeToggle(
                                            allowWrap: true,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pushNamed(
                                                AppRoutes.forgotPassword,
                                              );
                                            },
                                            child: const Text('Forgot Password?'),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: _buildRememberMeToggle(
                                        allowWrap: false,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pushNamed(
                                          AppRoutes.forgotPassword,
                                        );
                                      },
                                      child: const Text('Forgot Password?'),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            if (auth.isLoading)
                              const LoadingIndicator()
                            else
                              PrimaryButton(
                                label: 'LOGIN',
                                onPressed: _submit,
                              ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account?"),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pushNamed(AppRoutes.register);
                                  },
                                  child: const Text('Sign Up'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
