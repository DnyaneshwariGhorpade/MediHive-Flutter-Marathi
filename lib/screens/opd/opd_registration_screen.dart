import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/opd_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/standard_header.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/section_card.dart';
import '../../widgets/chip_selector.dart';
import '../../widgets/scrollable_date_picker.dart';
import '../../widgets/medi_chip_input_field.dart';
import '../../widgets/chip_input_field.dart';
import '../../widgets/shake_widget.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/success_overlay.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/medical_data.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../l10n/app_localizations.dart';
import '../../utils/medicine_localizer.dart';

class OpdRegistrationScreen extends StatefulWidget {
  final String? editPatientId;
  final String? editOpdId;
  const OpdRegistrationScreen({super.key, this.editPatientId, this.editOpdId});

  @override
  State<OpdRegistrationScreen> createState() => _OpdRegistrationScreenState();
}

class _OpdRegistrationScreenState extends State<OpdRegistrationScreen> {
  // GlobalKeys for Step Forms
  final List<GlobalKey<FormState>> _formKeys = List.generate(
    3,
    (_) => GlobalKey<FormState>(),
  );
  final _scrollController = ScrollController();
  TextEditingController? _autocompleteController;
  String? _documentPath;
  Uint8List? _documentBytes;
  bool _showFab = true;

  // Shake animation triggers for Step 0 (Patient Information)
  bool _shakeName = false;
  bool _shakeDob = false;
  bool _shakeMobile = false;
  bool _shakeAddress = false;
  bool _isSubmitting = false;
  bool _hasTriedSubmit = false;
  Timer? _lookupDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final show =
          _scrollController.position.userScrollDirection ==
          ScrollDirection.forward;
      if (show != _showFab) {
        setState(() => _showFab = show);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<OpdProvider>();
      if (widget.editPatientId != null && widget.editPatientId!.isNotEmpty) {
        p.loadPatientForEdit(widget.editPatientId!, opdId: widget.editOpdId);
      } else {
        p.loadDraftFromHive();
      }
      if (p.hasDraft) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            content: Text('${l10n.resumingDraft} — ${p.patientName}'),
            action: SnackBarAction(label: l10n.discard, onPressed: p.clearDraft),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _lookupDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  int calculateAge(DateTime dob) {
    final today = DateTime.now();
    int years = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      years--;
    }
    return years;
  }

  String formatAgeString(DateTime dob) {
    final today = DateTime.now();
    int years = today.year - dob.year;
    int months = today.month - dob.month;
    if (months < 0 || (months == 0 && today.day < dob.day)) {
      years--;
      months += 12;
    }
    if (today.day < dob.day) {
      months--;
    }
    if (months < 0) {
      months = 11;
    }
    return "Age: $years years $months months";
  }

  void _onMobileChanged(OpdProvider opd, String value) {
    final normalized = Helpers.normalizePhone(value);
    final fieldValue = normalized.isNotEmpty ? normalized : value;
    opd.updateField('mobile', fieldValue);
    _lookupDebounce?.cancel();
    if (normalized.length == 10) {
      _lookupDebounce = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        opd.searchPatientsByMobile(normalized);
      });
    } else {
      opd.clearMobileLookup();
    }
  }

  Widget _buildMobileLookup(OpdProvider opd) {
    final l10n = AppLocalizations.of(context)!;
    final patients = opd.matchedPatients;
    final isSingle = patients.length == 1;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withAlpha(76)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (patients.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                isSingle ? '' : l10n.availablePatients,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            ...patients.asMap().entries.map((entry) {
              final patient = entry.value;
              final name = patient['full_name']?.toString() ?? '';
              final gender = patient['gender']?.toString() ?? '';
              final ageStr = _formatLookupAge(patient);
              final dobStr = _formatLookupDob(patient);
              return InkWell(
                onTap: () => opd.autoFillFromPatient(patient),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primary.withAlpha(30),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$gender${ageStr.isNotEmpty ? ' | $ageStr' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (dobStr.isNotEmpty)
                        Text(
                          dobStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const Divider(height: 1, thickness: 1),
          ],
          InkWell(
            onTap: () => opd.selectNewPatientRegistration(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.person_add_outlined, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.registerNewPatient,
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLookupAge(Map<String, dynamic> patient) {
    final age = patient['age'];
    if (age == null) return '';
    final ageStr = age.toString();
    if (ageStr.contains('yr') || ageStr.contains('mo')) return ageStr;
    final ageNum = int.tryParse(ageStr);
    if (ageNum != null) return '$ageNum yrs';
    return ageStr;
  }

  String _formatLookupDob(Map<String, dynamic> patient) {
    final dob = patient['dob']?.toString() ?? '';
    if (dob.isEmpty) return '';
    final date = DateTime.tryParse(dob);
    if (date != null) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    return dob;
  }

  bool _validateStep1(OpdProvider opd) {
    bool isValid = true;
    bool shouldScroll = false;
    _hasTriedSubmit = true;

    if (opd.formData.name.trim().isEmpty) {
      isValid = false;
      shouldScroll = true;
      setState(() => _shakeName = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _shakeName = false);
      });
    }
    if (opd.formData.dob.trim().isEmpty) {
      isValid = false;
      shouldScroll = true;
      setState(() => _shakeDob = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _shakeDob = false);
      });
    }
    if (opd.formData.mobile.trim().isEmpty ||
        opd.formData.mobile.trim().replaceAll(RegExp(r'[^0-9]'), '').length !=
            10) {
      isValid = false;
      shouldScroll = true;
      setState(() => _shakeMobile = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _shakeMobile = false);
      });
    }
    if (opd.formData.address.trim().isEmpty) {
      isValid = false;
      shouldScroll = true;
      setState(() => _shakeAddress = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _shakeAddress = false);
      });
    }

    if (shouldScroll) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }

    // Trigger form validation to display standard inline help errors
    _formKeys[0].currentState?.validate();

    return isValid;
  }

  Widget buildRequiredLabel(String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            TextSpan(
              text: ' *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBack(BuildContext context) async {
    final provider = context.read<OpdProvider>();
    final l10n = AppLocalizations.of(context)!;
    if (!provider.hasUnsavedData) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/app/opd');
      }
      return;
    }
    await showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(l10n.saveDraft),
            leading: const Icon(Icons.save, color: Colors.orange),
            onTap: () {
              provider.saveDraft();
              Navigator.pop(context); // close sheet
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/app/opd');
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.draftSaved)),
              );
            },
          ),
          ListTile(
            title: Text(l10n.discard),
            leading: const Icon(Icons.delete, color: Colors.red),
            onTap: () {
              provider.clearDraft();
              Navigator.pop(context); // close sheet
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/app/opd');
              }
            },
          ),
          ListTile(
            title: Text(l10n.continueEditing),
            leading: const Icon(Icons.edit),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context)!;
    final opd = context.watch<OpdProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  StandardHeader(
                    title: l10n.opdRegistration,
                    showBack: true,
                    onBack: () => _handleBack(context),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child:                       MediStepProgressIndicator(
                        currentStep: opd.currentStep,
                        stepLabels: [
                          l10n.patientInformation,
                          l10n.medicalClinicalDetails,
                          l10n.billingPayment,
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKeys[opd.currentStep],
                        child: _buildStepContent(opd, context, opd.currentStep),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border)),
                boxShadow: AppTheme.cardShadow,
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    if (opd.currentStep > 0) ...[
                      Expanded(
                        child: AnimatedButton(
                          onTap: () {
                            opd.previousStep();
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primary,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              l10n.previous,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: AnimatedButton(
                        onTap: () async {
                          // Perform validation for current step
                          if (opd.currentStep == 0) {
                            if (!_validateStep1(opd)) return;
                          } else {
                            if (!(_formKeys[opd.currentStep].currentState
                                    ?.validate() ??
                                false)) {
                              return;
                            }
                          }

                          if (opd.currentStep < 2) {
                            opd.nextStep();
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            if (_isSubmitting) return;
                            setState(() => _isSubmitting = true);
                            debugPrint('OPD SAVE START');
                            try {
                              final dashboardProvider = context.read<DashboardProvider>();
                              final appointmentProvider = context.read<AppointmentProvider>();
                              final notificationProvider = context.read<NotificationProvider>();

                              await context
                                  .read<PatientProvider>()
                                  .addPatientFromOpd(opd.formData);
                              if (!context.mounted) return;
                              final patientNameForNotification =
                                  opd.formData.name;
                              // Find existing record ID if editing
                              String? existingId;
                              debugPrint('OPD SAVE: editPatientId="${widget.editPatientId}" editOpdId="${widget.editOpdId}"');
                              if (widget.editOpdId != null &&
                                  widget.editOpdId!.isNotEmpty) {
                                existingId = widget.editOpdId;
                                debugPrint('OPD SAVE: using direct editOpdId=$existingId (EDIT MODE)');
                              } else {
                                debugPrint('OPD SAVE: creating NEW OPD visit (CREATE MODE)');
                              }
                              debugPrint('OPD SAVE: existingId=$existingId');
                              final success = await opd.submitRecord(
                                dashboardProvider: dashboardProvider,
                                appointmentProvider: appointmentProvider,
                                existingRecordId: existingId,
                                documentBytes: _documentBytes,
                              );
                              if (!success) {
                                if (mounted) setState(() => _isSubmitting = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.failedToSaveRecord),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }
                              notificationProvider.addNotification(
                                'OPD Record Saved',
                                'Patient $patientNameForNotification record saved',
                              );
                            } catch (e) {
                              if (mounted) setState(() => _isSubmitting = false);
                              rethrow;
                            }

                            if (!context.mounted) return;
                            showGeneralDialog(
                              context: context,
                              barrierColor: Colors.black.withValues(
                                alpha: 0.45,
                              ),
                              barrierDismissible: false,
                              pageBuilder: (dialogContext, __, ___) =>
                                  SuccessOverlay(
                                    title: l10n.recordSaved,
                                    subtitle: l10n.patientAddedSuccessfully,
                                    onComplete: () {
                                      Navigator.of(
                                        dialogContext,
                                        rootNavigator: true,
                                      ).pop();
                                      Future.delayed(Duration.zero, () {
                                        _isSubmitting = false;
                                        opd.clearDraft();
                                        if (context.mounted) {
                                          context.pop();
                                        }
                                      });
                                    },
                                  ),
                            );
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (opd.currentStep == 2)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8.0),
                                  child: Icon(
                                    Icons.save,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              Text(
                                opd.currentStep < 2
                                    ? l10n.nextStep
                                    : l10n.saveOpdRecord,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(OpdProvider opd, BuildContext context, int index) {
    switch (index) {
      case 0:
        return _buildStep1(opd, context);
      case 1:
        return _buildStep2(opd, context);
      case 2:
        return _buildStep3(opd);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1(OpdProvider opd, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.patientInformation,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ShakeWidget(
            shake: _shakeMobile,
            child: _textField(
              l10n.mobileNumber,
              l10n.enterMobileNumber,
              opd.formData.mobile,
              (v) => _onMobileChanged(opd, v),
              keyboardType: TextInputType.phone,
              isRequired: true,
              prefixIcon: Icons.phone_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.mobileRequired;
                }
                final numStr = value.trim().replaceAll(RegExp(r'[^0-9]'), '');
                if (numStr.length != 10) {
                  return l10n.enterExactly10Digits;
                }
                return null;
              },
            ),
          ),
          if (opd.showMobileLookup) _buildMobileLookup(opd),
          const SizedBox(height: 16),
          ShakeWidget(
            shake: _shakeName,
            child: _textField(
              l10n.fullName,
              l10n.enterPatientName,
              opd.formData.name,
              (v) => opd.updateField('name', v),
              isRequired: true,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.fullNameRequired;
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShakeWidget(
                      shake: _shakeDob,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () async {
                              final initial = DateTime.tryParse(
                                opd.formData.dob,
                              );
                              final picked = await showScrollableDatePicker(
                                context: context,
                                initialDate: initial,
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                final iso =
                                    '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                final today = DateTime.now();
                                int years = today.year - picked.year;
                                int months = today.month - picked.month;
                                if (today.day < picked.day) {
                                  months--;
                                }
                                if (months < 0) {
                                  years--;
                                  months += 12;
                                }
                                if (years < 0) {
                                  years = 0;
                                  months = 0;
                                }
                                opd.setDob(iso);
                                opd.setAge('$years yr $months mo');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.dateOfBirth,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _hasTriedSubmit && opd.formData.dob.isEmpty
                                                ? AppTheme.danger
                                                : AppTheme.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Builder(
                                          builder: (context) {
                                            final date = DateTime.tryParse(
                                              opd.formData.dob,
                                            );
                                            final display = date != null
                                                ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                                                : '';
                                            return Text(
                                              opd.formData.dob.isEmpty
                                                  ? l10n.tapToSelectDate
                                                  : display,
                                              style: AppTheme.body.copyWith(
                                                color: opd.formData.dob.isEmpty
                                                    ? AppTheme.textHint
                                                    : AppTheme.textPrimary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_month_outlined,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (opd.formData.dob.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Builder(
                              builder: (context) {
                                final dobDate = DateTime.tryParse(
                                  opd.formData.dob,
                                );
                                if (dobDate != null) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Text(
                                      formatAgeString(dobDate),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _textField(
                      l10n.age,
                      l10n.yearsMonths,
                      opd.formData.age,
                      (v) => opd.updateField('age', v),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final numStr = value.replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          );
                          if (numStr.isNotEmpty &&
                              (int.tryParse(numStr) ?? -1) < 0) {
                            return l10n.invalidAge;
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      l10n.weight,
                      l10n.enterWeight,
                      opd.formData.weight,
                      (v) => opd.updateField('weight', v),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return l10n.invalidWeight;
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label(l10n.gender),
          ChipSelector(
            options: AppConstants.genders,
            selected: opd.formData.gender,
            onSelected: (v) => opd.updateField('gender', v),
          ),
          const SizedBox(height: 16),
          ShakeWidget(
            shake: _shakeAddress,
            child: _textField(
              l10n.address,
              l10n.enterFullAddress,
              opd.formData.address,
              (v) => opd.updateField('address', v),
              maxLines: 3,
              isRequired: true,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.addressRequired;
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          _label(l10n.bloodGroup),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: opd.formData.bloodGroup,
                items: AppConstants.bloodGroups
                    .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                    .toList(),
                onChanged: (v) => opd.updateField('bloodGroup', v ?? 'O+'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2SectionHeader({
    required String title,
    required IconData icon,
    String? badgeText,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        if (badgeText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showImageSourceSheet(BuildContext context) async {
    final locale = Localizations.localeOf(context);
    final isMarathi = locale.languageCode == 'mr';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppTheme.cardBg,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isMarathi ? 'कागदपत्र / फोटो जोडा' : 'Attach Document / Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMarathi
                      ? 'प्रिस्क्रिप्शन किंवा लॅब रिपोर्टचा फोटो निवडा'
                      : 'Choose source for prescription or lab report',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
                  ),
                  title: Text(
                    isMarathi ? 'कॅमेरा वापरून फोटो घ्या' : 'Take Photo with Camera',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    isMarathi ? 'थेट कॅमेऱ्याने फोटो काढा' : 'Capture directly from device camera',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickDocument(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryLight),
                  ),
                  title: Text(
                    isMarathi ? 'गॅलरीमधून निवडा' : 'Choose from Gallery',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    isMarathi ? 'मोबाईलमधील फोटो निवडा' : 'Pick existing image from phone gallery',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickDocument(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDocument(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _documentPath = image.path;
          _documentBytes = bytes;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.documentUploaded),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to pick document: $e'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showImagePreviewDialog(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isMarathi = locale.languageCode == 'mr';

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.image_outlined, size: 20, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isMarathi ? 'कागदपत्र पूर्वावलोकन' : 'Document Preview',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.55,
                      ),
                      color: Colors.black,
                      child: Center(
                        child: InteractiveViewer(
                          panEnabled: true,
                          minScale: 0.8,
                          maxScale: 4.0,
                          child: (kIsWeb || _documentBytes != null)
                              ? Image.memory(
                                  _documentBytes!,
                                  fit: BoxFit.contain,
                                )
                              : Image.file(
                                  File(_documentPath!),
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            icon: Icon(Icons.delete_outline, color: AppTheme.danger, size: 18),
                            label: Text(
                              isMarathi ? 'काढून टाका' : 'Remove',
                              style: TextStyle(color: AppTheme.danger),
                            ),
                            onPressed: () {
                              setState(() {
                                _documentPath = null;
                                _documentBytes = null;
                              });
                              Navigator.pop(ctx);
                            },
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh, size: 18),
                            label: Text(isMarathi ? 'फोटो बदला' : 'Change'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showImageSourceSheet(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStep2(OpdProvider opd, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final isMarathi = locale.languageCode == 'mr';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Card 1: Clinical Impression (Diagnosis & Symptoms) ──
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStep2SectionHeader(
                title: l10n.medicalClinicalDetails,
                icon: Icons.health_and_safety_outlined,
                badgeText: isMarathi ? 'निदान व लक्षणे' : 'Diagnosis',
              ),
              const SizedBox(height: 18),
              MediChipInputField(
                label: l10n.diagnosisLabel,
                hint: l10n.searchOrAddDiagnosis,
                suggestions: MedicalData.diagnoses,
                initialValue: opd.formData.diagnosis,
                onChanged: (v) => opd.updateField('diagnosis', v),
              ),
              const SizedBox(height: 18),
              _label(l10n.symptoms),
              const SizedBox(height: 6),
              // Quick Symptom Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (final sym in [
                      isMarathi ? 'ताप (Fever)' : 'Fever',
                      isMarathi ? 'सर्दी/खोकला (Cough)' : 'Cough / Cold',
                      isMarathi ? 'डोकेदुखी (Headache)' : 'Headache',
                      isMarathi ? 'अ‍ॅसिडिटी (Acidity)' : 'Acidity',
                      isMarathi ? 'अंगदुखी (Body Ache)' : 'Body Ache',
                      isMarathi ? 'सांधेदुखी (Joint Pain)' : 'Joint Pain',
                      isMarathi ? 'अशक्तपणा (Weakness)' : 'Weakness',
                      isMarathi ? 'अपचन (Indigestion)' : 'Indigestion',
                    ]) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 6.0, bottom: 4.0),
                        child: FilterChip(
                          label: Text(
                            sym,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: opd.selectedSymptoms.contains(sym)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: opd.selectedSymptoms.contains(sym)
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          selected: opd.selectedSymptoms.contains(sym),
                          selectedColor: AppTheme.primary,
                          backgroundColor: AppTheme.surfaceVariant,
                          checkmarkColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: opd.selectedSymptoms.contains(sym)
                                  ? AppTheme.primary
                                  : AppTheme.border,
                            ),
                          ),
                          onSelected: (selected) {
                            final current = List<String>.from(opd.selectedSymptoms);
                            if (selected) {
                              if (!current.contains(sym)) current.add(sym);
                            } else {
                              current.remove(sym);
                            }
                            opd.setSelectedSymptoms(current);
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ChipInputField(
                label: '',
                suggestions: kSymptoms,
                selectedItems: opd.selectedSymptoms,
                onChanged: opd.setSelectedSymptoms,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Card 2: Treatment & Prescriptions ──
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStep2SectionHeader(
                title: l10n.prescriptions,
                icon: Icons.medication_outlined,
                badgeText: '${opd.prescribedMedicines.length} ${isMarathi ? "औषधे" : "Medicines"}',
              ),
              const SizedBox(height: 16),
              Autocomplete<Map<String, String>>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final query = textEditingValue.text.toLowerCase();
                  if (query.isEmpty) {
                    return const Iterable<Map<String, String>>.empty();
                  }
                  final matches = kMedicines
                      .where((med) => med['name']!.toLowerCase().contains(query))
                      .toList();

                  if (query.isNotEmpty &&
                      !matches.any((m) => m['name']!.toLowerCase() == query)) {
                    matches.add({'name': textEditingValue.text, 'type': 'Custom'});
                  }
                  return matches;
                },
                displayStringForOption: (option) => option['name']!,
                fieldViewBuilder:
                    (context, textEditingController, focusNode, onFieldSubmitted) {
                      _autocompleteController = textEditingController;
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: l10n.prescribeMedicine,
                          hintText: l10n.typeMedicineSearch,
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          filled: true,
                          fillColor: AppTheme.surface,
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                optionsViewBuilder: (context, onSelected, options) {
                  final grouped = <String, List<Map<String, String>>>{};
                  for (final opt in options) {
                    grouped.putIfAbsent(opt['type']!, () => []).add(opt);
                  }

                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 6.0,
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 280,
                          maxWidth: MediaQuery.of(context).size.width - 48,
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: grouped.length,
                          itemBuilder: (context, index) {
                            final type = grouped.keys.elementAt(index);
                            final meds = grouped[type]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  color: AppTheme.primary.withValues(alpha: 0.08),
                                  width: double.infinity,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.category_outlined, size: 14, color: AppTheme.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        type,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...meds.map(
                                  (med) => ListTile(
                                    dense: true,
                                    title: Text(
                                      localizeMedicineName(med['name']!, Localizations.localeOf(context)),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      localizeMedicineType(med['type']!, Localizations.localeOf(context)),
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: const Icon(Icons.add_circle_outline, size: 20, color: AppTheme.primary),
                                    onTap: () => onSelected(med),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
                onSelected: (option) {
                  final newList = List<Map<String, dynamic>>.from(
                    opd.prescribedMedicines,
                  );
                  newList.add({
                    'name': option['name'],
                    'type': option['type'],
                    'dosage': kDosageOptions.first,
                    'frequency': '1-0-1 (BD)',
                    'duration': '5 days',
                  });
                  opd.setPrescribedMedicines(newList);
                  _autocompleteController?.clear();
                },
              ),
              if (opd.prescribedMedicines.isNotEmpty) ...[
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: opd.prescribedMedicines.length,
                  itemBuilder: (context, index) {
                    final item = opd.prescribedMedicines[index];
                    final medType = item['type']?.toString() ?? '';
                    final currentDosage = item['dosage']?.toString() ?? kDosageOptions.first;
                    final currentFreq = item['frequency']?.toString() ?? '1-0-1 (BD)';
                    final currentDur = item['duration']?.toString() ?? '5 days';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.medication, size: 18, color: AppTheme.primary),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        localizeMedicineName(item['name'].toString(), Localizations.localeOf(context)),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      if (medType.isNotEmpty)
                                        Text(
                                          localizeMedicineType(medType, Localizations.localeOf(context)),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: AppTheme.danger,
                                    size: 20,
                                  ),
                                  tooltip: isMarathi ? 'काढून टाका' : 'Remove',
                                  onPressed: () {
                                    final newList = List<Map<String, dynamic>>.from(
                                      opd.prescribedMedicines,
                                    );
                                    newList.removeAt(index);
                                    opd.setPrescribedMedicines(newList);
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            // Quick Dosage Dropdown
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: kDosageOptions.contains(currentDosage) ? currentDosage : kDosageOptions.first,
                              decoration: InputDecoration(
                                labelText: l10n.dosage,
                                isDense: true,
                                filled: true,
                                fillColor: AppTheme.surface,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: kDosageOptions
                                  .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12))))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  final newList = List<Map<String, dynamic>>.from(opd.prescribedMedicines);
                                  newList[index]['dosage'] = val;
                                  opd.setPrescribedMedicines(newList);
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            // Quick Frequency Presets
                            Text(
                              isMarathi ? 'वेळ / प्रमाण (Frequency):' : 'Frequency & Timing:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  for (final freq in ['1-0-1 (BD)', '1-1-1 (TDS)', '1-0-0 (Morning)', '0-0-1 (Night)', 'After Food', 'Before Food', 'SOS']) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6.0),
                                      child: ChoiceChip(
                                        label: Text(freq, style: TextStyle(fontSize: 11, color: currentFreq == freq ? Colors.white : AppTheme.textPrimary)),
                                        selected: currentFreq == freq,
                                        selectedColor: AppTheme.primary,
                                        backgroundColor: AppTheme.surface,
                                        visualDensity: VisualDensity.compact,
                                        onSelected: (selected) {
                                          if (selected) {
                                            final newList = List<Map<String, dynamic>>.from(opd.prescribedMedicines);
                                            newList[index]['frequency'] = freq;
                                            opd.setPrescribedMedicines(newList);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Duration Presets
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  Text(
                                    isMarathi ? 'कालावधी: ' : 'Duration: ',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                                  ),
                                  for (final dur in ['3 days', '5 days', '7 days', '15 days', '1 month']) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6.0),
                                      child: ChoiceChip(
                                        label: Text(dur, style: TextStyle(fontSize: 11, color: currentDur == dur ? Colors.white : AppTheme.textPrimary)),
                                        selected: currentDur == dur,
                                        selectedColor: AppTheme.primaryLight,
                                        backgroundColor: AppTheme.surface,
                                        visualDensity: VisualDensity.compact,
                                        onSelected: (selected) {
                                          if (selected) {
                                            final newList = List<Map<String, dynamic>>.from(opd.prescribedMedicines);
                                            newList[index]['duration'] = dur;
                                            opd.setPrescribedMedicines(newList);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Card 3: Clinical & Panchakarma Notes ──
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStep2SectionHeader(
                title: isMarathi ? 'वैद्यकीय नोंदी' : 'Clinical Observations',
                icon: Icons.notes_outlined,
              ),
              const SizedBox(height: 14),
              // Quick observation snippets
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (final note in [
                      isMarathi ? 'सर्व तपासण्या सामान्य (Vitals Normal)' : 'Vitals Normal',
                      isMarathi ? 'ताप नाही (Afebrile)' : 'Afebrile',
                      isMarathi ? 'विश्रांतीचा सल्ला (Rest Advised)' : 'Rest Advised',
                      isMarathi ? 'पथ्य पाळणे (Diet Advice)' : 'Diet Control Advised',
                      isMarathi ? 'रक्ततपासणी आवश्यक (Labs Needed)' : 'Blood Test Advised',
                    ]) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 6.0, bottom: 4.0),
                        child: ActionChip(
                          avatar: const Icon(Icons.add, size: 14, color: AppTheme.primary),
                          label: Text(note, style: const TextStyle(fontSize: 11)),
                          backgroundColor: AppTheme.surfaceVariant,
                          onPressed: () {
                            final curr = opd.formData.clinicalNotes;
                            final updated = curr.isEmpty ? note : '$curr, $note';
                            opd.updateField('clinicalNotes', updated);
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _textField(
                l10n.clinicalNotes,
                l10n.enterObservationsNotes,
                opd.formData.clinicalNotes,
                (v) => opd.updateField('clinicalNotes', v),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _textField(
                l10n.panchakarmaNotes,
                l10n.enterPanchakarmaNotes,
                opd.formData.panchakarmaNotes,
                (v) => opd.updateField('panchakarmaNotes', v),
                maxLines: 3,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Card 4: Attachments & Documents ──
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStep2SectionHeader(
                title: l10n.uploadDocumentsOptional,
                icon: Icons.attach_file_outlined,
                badgeText: _documentBytes != null ? (isMarathi ? 'संलग्न' : 'Attached') : null,
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => _showImageSourceSheet(context),
                child: _documentPath == null && _documentBytes == null
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                          border: Border.all(color: AppTheme.border, width: 1.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cloud_upload_outlined,
                                size: 30,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.tapToUploadDocuments,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isMarathi ? 'कॅमेरा किंवा गॅलरीमधून निवडा' : 'Camera or Gallery (Prescription / Reports)',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          border: Border.all(color: AppTheme.success, width: 1.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _showImagePreviewDialog(context),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: (kIsWeb || _documentBytes != null)
                                        ? Image.memory(
                                            _documentBytes!,
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            File(_documentPath!),
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(Icons.zoom_in, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _documentPath != null
                                        ? _documentPath!.split(Platform.pathSeparator).last
                                        : 'document_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle, size: 14, color: AppTheme.success),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.readyForSubmission,
                                        style: const TextStyle(
                                          color: AppTheme.success,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isMarathi ? 'पाहण्यासाठी टॅप करा' : 'Tap photo to preview',
                                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: AppTheme.primary, size: 22),
                              tooltip: isMarathi ? 'फोटो बदला' : 'Change Photo',
                              onPressed: () => _showImageSourceSheet(context),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: AppTheme.danger,
                                size: 22,
                              ),
                              tooltip: isMarathi ? 'काढून टाका' : 'Remove',
                              onPressed: () {
                                setState(() {
                                  _documentPath = null;
                                  _documentBytes = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Card 5: Visit Type & Follow-up ──
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStep2SectionHeader(
                title: isMarathi ? 'भेट प्रकार व पुढील तारीख' : 'Visit Type & Schedule',
                icon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 16),
              _label(l10n.opdType),
              const SizedBox(height: 8),
              ChipSelector(
                options: const ['Consultation', 'Follow-up'],
                selected: opd.visitType == 'follow_up'
                    ? 'Follow-up'
                    : 'Consultation',
                onSelected: (v) {
                  opd.visitType = v == 'Follow-up' ? 'follow_up' : 'consultation';
                },
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: opd.visitType == 'follow_up'
                    ? Column(
                        key: const ValueKey('follow_up_fields'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final initial = DateTime.tryParse(
                                opd.formData.previousVisitDate,
                              );
                              final picked = await showScrollableDatePicker(
                                context: context,
                                initialDate: initial,
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                opd.previousVisitDate = picked;
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Builder(
                                      builder: (context) {
                                        final date = DateTime.tryParse(
                                          opd.formData.previousVisitDate,
                                        );
                                        final display = date != null
                                            ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                                            : '';
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.previousVisitDate,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              opd.formData.previousVisitDate.isEmpty
                                                  ? l10n.tapToSelectDate
                                                  : display,
                                              style: AppTheme.body.copyWith(
                                                color:
                                                    opd
                                                        .formData
                                                        .previousVisitDate
                                                        .isEmpty
                                                    ? AppTheme.textHint
                                                    : AppTheme.textPrimary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_month_outlined,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _textField(
                            l10n.followUpReason,
                            l10n.enterFollowUpReason,
                            opd.followUpReason,
                            (v) => opd.followUpReason = v,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(key: ValueKey('no_follow_up')),
              ),
              const SizedBox(height: 18),
              _label(l10n.nextVisitDate),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final initial = DateTime.tryParse(opd.formData.nextVisit);
                  final picked = await showScrollableDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    final iso =
                        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    opd.updateField('nextVisit', iso);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_available_outlined, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final date = DateTime.tryParse(opd.formData.nextVisit);
                            final display = date != null
                                ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                                : '';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.nextVisitDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  opd.formData.nextVisit.isEmpty
                                      ? l10n.tapToSelectDate
                                      : display,
                                  style: AppTheme.body.copyWith(
                                    color: opd.formData.nextVisit.isEmpty
                                        ? AppTheme.textHint
                                        : AppTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Icon(
                        Icons.calendar_month_outlined,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3(OpdProvider opd) {
    final l10n = AppLocalizations.of(context)!;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.billingPayment,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Consultation Fee *
          _textField(
            l10n.consultationFees,
            '0',
            opd.formData.consultationFee,
            (v) => opd.updateField('consultationFee', v),
            keyboardType: TextInputType.number,
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return l10n.required;
              if (double.tryParse(value.trim()) == null) {
                return l10n.mustBeValidNumber;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Medicine Fee
          _textField(
            l10n.medicineFee,
            '0',
            opd.formData.medicineFee,
            (v) => opd.updateField('medicineFee', v),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Panchakarma Fee
          _textField(
            l10n.panchakarmaFee,
            '0',
            opd.formData.panchakarmaFee,
            (v) => opd.updateField('panchakarmaFee', v),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Discount Type Dropdown
          _label(l10n.discountType),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: opd.formData.discountType,
            decoration: InputDecoration(
              labelText: l10n.discountType,
              labelStyle: TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
            dropdownColor: AppTheme.surface,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            items: const [
              DropdownMenuItem(value: 'None', child: Text('None')),
              DropdownMenuItem(value: '₹', child: Text('₹ (Amount)')),
              DropdownMenuItem(value: '%', child: Text('% (Percentage)')),
            ],
            onChanged: (v) {
              if (v != null) opd.updateField('discountType', v);
            },
          ),
          const SizedBox(height: 16),

          // Discount Value (enabled only when discount type is not None)
          _textField(
            l10n.discountValue,
            '0',
            opd.formData.discount,
            (v) => opd.updateField('discount', v),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),

          // Total Fee (read-only, auto-calculated)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.subtotal,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '₹${opd.formData.subtotal.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (opd.formData.discountType != 'None' && (double.tryParse(opd.formData.discount) ?? 0) > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Discount (${opd.formData.discountType})',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '-₹${opd.formData.discountType == '%'
                            ? ((opd.formData.subtotal * (double.tryParse(opd.formData.discount) ?? 0) / 100).toStringAsFixed(0))
                            : opd.formData.discount}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.totalAmount,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '₹${opd.formData.totalFee.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Payment Mode
          _label(l10n.paymentMode),
          ChipSelector(
            options: AppConstants.paymentModes,
            selected: opd.formData.paymentMode,
            onSelected: (v) => opd.updateField('paymentMode', v),
          ),
          const SizedBox(height: 16),

          // Charge Type
          _label(l10n.chargeType),
          ChipSelector(
            options: AppConstants.chargeTypes,
            selected: opd.formData.chargeType,
            onSelected: (v) => opd.updateField('chargeType', v),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _textField(
    String label,
    String hint,
    String value,
    ValueChanged<String> onChanged, {
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    bool isRequired = false,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
  }) {
    return TextFormField(
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: textInputAction == TextInputAction.done
          ? (_) => FocusScope.of(context).unfocus()
          : null,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: TextStyle(
          color: isRequired && _hasTriedSubmit && value.isEmpty
              ? AppTheme.danger
              : AppTheme.textSecondary,
        ),
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.textTertiary),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: AppTheme.surface,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppTheme.primary, size: 20)
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.danger, width: 2),
        ),
      ),
    );
  }
}

// ─── STEP PROGRESS INDICATOR ─────────────────────────────────
class MediStepProgressIndicator extends StatefulWidget {
  final int currentStep;
  final List<String> stepLabels;

  const MediStepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.stepLabels,
  });

  @override
  State<MediStepProgressIndicator> createState() =>
      _MediStepProgressIndicatorState();
}

class _MediStepProgressIndicatorState extends State<MediStepProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _springController;
  late Animation<double> _labelAnim;
  String _displayedLabel = '';

  @override
  void initState() {
    super.initState();
    _displayedLabel = widget.stepLabels[widget.currentStep];
    _springController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _labelAnim = CurvedAnimation(
      parent: _springController,
      curve: Curves.elasticOut,
    );
    _springController.value = 1.0;
  }

  @override
  void didUpdateWidget(MediStepProgressIndicator old) {
    super.didUpdateWidget(old);
    if (widget.currentStep != old.currentStep) {
      setState(() {
        _displayedLabel = widget.stepLabels[widget.currentStep];
      });
      _springController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int totalSteps = widget.stepLabels.length;
    final int currentStep = widget.currentStep;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${currentStep + 1} of $totalSteps',
                style: AppTheme.label.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.primary,
                ),
              ),
              AnimatedBuilder(
                animation: _labelAnim,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.9 + (_labelAnim.value * 0.1),
                    child: child,
                  );
                },
                child: Text(
                  _displayedLabel,
                  style: AppTheme.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;

              return SizedBox(
                height: 34,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(1),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                          height: 2,
                          width:
                              (width - 28) *
                              (totalSteps > 1
                                  ? currentStep / (totalSteps - 1)
                                  : 1),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(totalSteps, (index) {
                        final bool isCompleted = index < currentStep;
                        final bool isActive = index == currentStep;
                        return AnimatedScale(
                          scale: isActive ? 1.0 : 0.85,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            width: isActive ? 34 : 28,
                            height: isActive ? 34 : 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? AppTheme.primary
                                  : isActive
                                  ? AppTheme.cardBg
                                  : AppTheme.surfaceVariant,
                              border: Border.all(
                                color: isCompleted || isActive
                                    ? AppTheme.primary
                                    : AppTheme.divider,
                                width: isActive ? 2.5 : 2,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(
                                          alpha: 0.25,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(scale: anim, child: child),
                                child: isCompleted
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                        key: ValueKey('check'),
                                      )
                                    : Text(
                                        '${index + 1}',
                                        key: ValueKey('num_$index'),
                                        style: TextStyle(
                                          fontSize: isActive ? 13 : 12,
                                          fontWeight: FontWeight.bold,
                                          color: isActive
                                              ? AppTheme.primary
                                              : AppTheme.textTertiary,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
