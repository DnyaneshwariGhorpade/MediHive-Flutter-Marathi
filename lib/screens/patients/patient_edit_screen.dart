import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/patient_provider.dart';
import '../../repositories/patient_repository.dart';
import '../../repositories/sync_queue_repository.dart';
import '../../utils/helpers.dart';
import '../../utils/sync_id_generator.dart';
import '../../services/sync_manager.dart';
import '../../widgets/section_card.dart';
import '../../widgets/standard_header.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/medi_date_picker_field.dart';
class PatientEditScreen extends StatefulWidget {
  final String patientId;
  const PatientEditScreen({super.key, required this.patientId});

  @override
  State<PatientEditScreen> createState() => _PatientEditScreenState();
}

class _PatientEditScreenState extends State<PatientEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _mobileController;
  late TextEditingController _addressController;
  late TextEditingController _dobController;
  String _gender = 'Male';
  String _bloodGroup = 'O+';
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _patientRow;
  late TextEditingController _weightController;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  int _toSqliteId(String hiveId) {
    final match = RegExp(r'(\d+)').firstMatch(hiveId);
    if (match != null) return int.parse(match.group(1)!);
    return 0;
  }

  Future<void> _loadPatient() async {
    final repo = PatientRepository();
    var patient = await repo.getBySyncId(widget.patientId);
    if (patient == null) {
      final sqliteId = _toSqliteId(widget.patientId);
      if (sqliteId > 0) {
        patient = await repo.getById(sqliteId);
      }
    }
    if (!mounted) return;
    if (patient == null) {
      setState(() => _isLoading = false);
      return;
    }
    _patientRow = patient;
    _nameController = TextEditingController(text: patient['full_name'] as String? ?? '');
    _ageController = TextEditingController(text: patient['age']?.toString() ?? '');
    _mobileController = TextEditingController(text: patient['mobile_number'] as String? ?? '');
    _addressController = TextEditingController(text: patient['address'] as String? ?? '');
    _dobController = TextEditingController(text: patient['dob'] as String? ?? '');
    _gender = patient['gender'] as String? ?? 'Male';
    _bloodGroup = patient['blood_group'] as String? ?? 'O+';
    _weightController = TextEditingController(text: patient['weight']?.toString() ?? '');
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      if (_patientRow == null) {
        throw Exception('Patient data not loaded');
      }
      final sqliteId = _patientRow!['id'] as int;
      final patientSyncId = _patientRow!['sync_id'] as String? ?? '';
      print('PATIENT EDIT SAVE: patientSyncId=$patientSyncId sqliteId=$sqliteId');

      final repo = PatientRepository();
      final syncQueueRepo = SyncQueueRepository();

      final name = _nameController.text.trim();
      final age = int.tryParse(_ageController.text.trim()) ?? (_patientRow?['age'] as int? ?? 0);

      final weight = double.tryParse(_weightController.text.trim());

      final updateData = <String, dynamic>{
        'full_name': name,
        'age': age,
        'mobile_number': Helpers.normalizePhone(_mobileController.text.trim()),
        'address': _addressController.text.trim(),
        'dob': _dobController.text.trim(),
        'gender': _gender,
        'blood_group': _bloodGroup,
        'weight': weight,
      };
      print('PATIENT EDIT SAVE: updating with $updateData');
      final affected = await repo.update(sqliteId, updateData);
      print('PATIENT EDIT SAVE: affectedRows=$affected');

      final syncEntityId = patientSyncId.isNotEmpty ? patientSyncId : widget.patientId;
      await syncQueueRepo.insert({
        'id': SyncIdGenerator.nextId(),
        'entity_type': 'patient',
        'entity_id': syncEntityId,
        'status': 'pending',
        'retry_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('PATIENT EDIT SAVE: sync queue entry created for $syncEntityId');
      Future.microtask(() {
        print('FORCING IMMEDIATE SYNC');
        SyncManager().forceSyncNow();
      });

      if (mounted) {
        context.read<PatientProvider>().loadPatients();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Patient $name updated'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          StandardHeader(
            title: l10n.editPatient,
            showBack: true,
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_patientRow == null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off, size: 64, color: AppTheme.textSecondary),
                    const SizedBox(height: 16),
                    Text(l10n.patientNotFound, style: AppTheme.body),
                  ],
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.patientInformationLabel, style: AppTheme.subHeading),
                            const SizedBox(height: 20),
                            _buildField(l10n.fullName, _nameController, Icons.person_outline, validator: (v) =>
                                v == null || v.trim().isEmpty ? l10n.nameRequired : null),
                            const SizedBox(height: 16),
                            _buildField(
                              l10n.age,
                              _ageController,
                              Icons.cake_outlined,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                final ageText = val.trim();
                                if (ageText.isNotEmpty) {
                                  final age = int.tryParse(ageText);
                                  if (age != null && age >= 0 && age <= 120) {
                                    final calculatedYear = DateTime.now().year - age;
                                    final newDob = "$calculatedYear-01-01";
                                    if (_dobController.text != newDob) {
                                      setState(() {
                                        _dobController.text = newDob;
                                      });
                                    }
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildDropdown(l10n.gender, _gender, _genders, (v) => setState(() => _gender = v!)),
                            const SizedBox(height: 16),
                            _buildField(l10n.mobileNumber, _mobileController, Icons.phone_outlined, keyboardType: TextInputType.phone, validator: (v) {
                                if (v == null || v.trim().isEmpty) return l10n.mobileRequiredEdit;
                                final cleaned = v.replaceAll(RegExp(r'[^0-9]'), '');
                                if (cleaned.length < 10) return l10n.enterAtLeast10;
                                return null;
                              }),
                            const SizedBox(height: 16),
                            _buildField(l10n.address, _addressController, Icons.location_on_outlined, maxLines: 2),
                            const SizedBox(height: 16),
                            MediDatePickerField(
                              label: l10n.dateOfBirthLabel,
                              value: _dobController.text.trim(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                              onChanged: (isoDate) {
                                setState(() {
                                  _dobController.text = isoDate;
                                  final date = DateTime.tryParse(isoDate);
                                  if (date != null) {
                                    final now = DateTime.now();
                                    int age = now.year - date.year;
                                    if (now.month < date.month || (now.month == date.month && now.day < date.day)) {
                                      age--;
                                    }
                                    if (age >= 0) {
                                      _ageController.text = age.toString();
                                    }
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildDropdown(l10n.bloodGroup, _bloodGroup, _bloodGroups, (v) => setState(() => _bloodGroup = v!)),
                            const SizedBox(height: 16),
                            _buildField(l10n.weight, _weightController, Icons.monitor_weight_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) {
                                if (v != null && v.trim().isNotEmpty) {
                                  if (double.tryParse(v) == null) {
                                    return l10n.invalidWeight;
                                  }
                                }
                                return null;
                              }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  l10n.saveChanges,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      style: AppTheme.body,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
        filled: true,
        fillColor: AppTheme.inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      style: AppTheme.body,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.arrow_drop_down_circle_outlined, color: AppTheme.primary),
        filled: true,
        fillColor: AppTheme.inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
