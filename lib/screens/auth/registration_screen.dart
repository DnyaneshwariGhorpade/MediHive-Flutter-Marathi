import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/language_toggle_button.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _clinicNameCtrl = TextEditingController();
  final _clinicPhoneCtrl = TextEditingController();
  final _clinicAddressCtrl = TextEditingController();

  bool _showPassword = false;
  bool _showConfirm = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _clinicNameCtrl.dispose();
    _clinicPhoneCtrl.dispose();
    _clinicAddressCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.passwordsDoNotMatchExclaim);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.registerClinic(
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        clinicName: _clinicNameCtrl.text.trim(),
        clinicEmail: _emailCtrl.text.trim(),
        clinicPhone: _clinicPhoneCtrl.text.trim(),
        clinicAddress: _clinicAddressCtrl.text.trim(),
      );

      if (mounted) {
        final auth = context.read<AuthProvider>();
        auth.setUsername(_usernameCtrl.text.trim());
        auth.setPassword(_passwordCtrl.text);
        auth.setRememberMe(true);
        await auth.saveClinicInfo(data);

        final success = await auth.signIn();
        if (success && mounted) {
          context.go('/app');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          final t = AppLocalizations.of(context)!;
          _errorMessage = e.toString().contains('already exists')
              ? t.usernameAlreadyExists
              : t.registrationFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
                    decoration: const BoxDecoration(
                      gradient: AppTheme.headerGradient,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Column(children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.local_hospital, size: 48, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            t.createClinicAccount,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.registerClinicSubtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ]),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: LanguageToggleButton(isCompact: true),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(children: [
                        // Clinic Info Section
                        _sectionHeader(t.clinicInformation),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _clinicNameCtrl,
                          enabled: !_isSubmitting,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(t.clinicNameField, Icons.local_hospital),
                          validator: (v) => (v == null || v.trim().isEmpty) ? t.clinicNameRequired : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _clinicPhoneCtrl,
                          enabled: !_isSubmitting,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.phone,
                          decoration: _inputDecoration(t.phoneOptional, Icons.phone),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _clinicAddressCtrl,
                          enabled: !_isSubmitting,
                          textInputAction: TextInputAction.next,
                          maxLines: 2,
                          decoration: _inputDecoration(t.addressOptional, Icons.location_on),
                        ),
                        const SizedBox(height: 20),
                        // Doctor Info Section
                        _sectionHeader(t.doctorInformationSection),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameCtrl,
                          enabled: !_isSubmitting,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(t.fullName, Icons.person),
                          validator: (v) => (v == null || v.trim().isEmpty) ? t.enterYourName : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _emailCtrl,
                          enabled: !_isSubmitting,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration(t.emailOptional, Icons.email),
                        ),
                        const SizedBox(height: 20),
                        // Login Credentials Section
                        _sectionHeader(t.loginCredentialsSection),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _usernameCtrl,
                          enabled: !_isSubmitting,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(t.username, Icons.person_outline),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return t.enterUsernamePlaceholder;
                            if (v.length < 3) return t.atLeast3Characters;
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordCtrl,
                          enabled: !_isSubmitting,
                          obscureText: !_showPassword,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(t.password, Icons.lock_outline, suffix: IconButton(
                            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, size: 22),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          )),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return t.enterPasswordPlaceholder;
                            if (v.length < 4) return t.atLeast4CharactersLabel;
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmCtrl,
                          enabled: !_isSubmitting,
                          obscureText: !_showConfirm,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _register(),
                          decoration: _inputDecoration(t.confirmPasswordLabel, Icons.lock_outline, suffix: IconButton(
                            icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility, size: 22),
                            onPressed: () => setState(() => _showConfirm = !_showConfirm),
                          )),
                          validator: (v) => (v == null || v.trim().isEmpty) ? t.confirmYourPassword : null,
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(children: [
                              Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_errorMessage!, style: TextStyle(color: AppTheme.danger, fontSize: 13))),
                            ]),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                : Text(t.createClinicBtn, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _isSubmitting ? null : () => context.go('/login'),
                          child: Text(t.alreadyHaveAccountSignIn, style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary)),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppTheme.surfaceVariant,
      prefixIcon: Padding(padding: const EdgeInsets.only(left: 16, right: 8), child: Icon(icon, size: 22, color: AppTheme.primary)),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
