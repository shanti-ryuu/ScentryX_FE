import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/loading_indicator.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _TokenDisplay extends StatelessWidget {
  final String token;
  final String? verifyEndpoint;
  final VoidCallback onCopy;

  const _TokenDisplay({
    required this.token,
    required this.onCopy,
    this.verifyEndpoint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your verification token',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            token,
            style: theme.textTheme.bodyLarge?.copyWith(
              letterSpacing: 0.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (verifyEndpoint != null && verifyEndpoint!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Endpoint: $verifyEndpoint',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _tokenController = TextEditingController();
  bool _resendInProgress = false;
  String? _lastPrefilledToken;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final token = auth.pendingVerificationToken;
    if (token != null && token.isNotEmpty && token != _lastPrefilledToken) {
      _tokenController.text = token;
      _lastPrefilledToken = token;
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the token from your email.')),
      );
      return;
    }

    final success = await auth.verifyEmail(token);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verified! Welcome to ScentryX.')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.dashboard,
        (route) => false,
      );
    } else {
      final message = auth.error ?? 'Verification failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _copyToken(String token) async {
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification token copied to clipboard.')),
    );
  }

  Future<void> _resendEmail() async {
    final auth = context.read<AuthProvider>();
    final email = auth.pendingVerificationEmail;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending email to resend to.')),
      );
      return;
    }

    setState(() => _resendInProgress = true);
    final success = await auth.resendVerification(email);
    if (!mounted) return;

    setState(() => _resendInProgress = false);

    if (success) {
      final token = auth.pendingVerificationToken;
      if (token != null && token.isNotEmpty) {
        _tokenController.text = token;
      }
    }

    final message = success
        ? 'Verification email sent to $email'
        : auth.error ?? 'Failed to resend email';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pendingToken = auth.pendingVerificationToken;
    final verifyEndpoint = auth.pendingVerificationVerifyEndpoint;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF111431), Color(0xFF1D2A5E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.login,
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Verify Email',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete your setup',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        auth.pendingVerificationEmail != null
                            ? 'We saved your account and generated a verification token for\n${auth.pendingVerificationEmail}. Paste it below to activate your profile.'
                            : 'Enter the verification token to activate your profile.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.black.withOpacity(0.75)),
                      ),
                      if (pendingToken != null && pendingToken.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _TokenDisplay(
                          token: pendingToken,
                          verifyEndpoint: verifyEndpoint,
                          onCopy: () => _copyToken(pendingToken),
                        ),
                      ],
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: _tokenController,
                        label: 'Verification Token',
                        hintText: 'Paste token here',
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 24),
                      if (auth.isLoading)
                        const LoadingIndicator()
                      else
                        PrimaryButton(
                          label: 'VERIFY ACCOUNT',
                          onPressed: _submit,
                        ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF5C6FF8),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _resendInProgress ? null : _resendEmail,
                        icon: _resendInProgress
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: Text(
                          _resendInProgress
                              ? 'Generating new token...'
                              : 'Resend verification token',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.login,
                              (route) => false,
                            );
                          },
                          child: const Text('Back to Login'),
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
