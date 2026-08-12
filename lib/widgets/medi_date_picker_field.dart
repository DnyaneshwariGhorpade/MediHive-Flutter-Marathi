import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A tappable date field that opens a date picker.
///
/// DOB fields: pass firstDate: DateTime(1900), lastDate: DateTime.now()
///   → auto-detected as DOB, opens on year-selection mode, displays DD/MM/YYYY
/// Appointment/future fields: pass firstDate: DateTime.now()
///   → opens on day mode, displays DD/MM/YYYY
class MediDatePickerField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool isRequired;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;

  const MediDatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isRequired = false,
    this.prefixIcon = Icons.calendar_today,
    this.validator,
    this.firstDate,
    this.lastDate,
    this.initialDate,
  });

  @override
  State<MediDatePickerField> createState() => _MediDatePickerFieldState();
}

class _MediDatePickerFieldState extends State<MediDatePickerField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _displayValue(widget.value));
  }

  @override
  void didUpdateWidget(covariant MediDatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller.text = _displayValue(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Convert ISO date (YYYY-MM-DD) to Indian DD/MM/YYYY for display.
  String _displayValue(String isoValue) {
    if (isoValue.isEmpty) return '';
    final date = DateTime.tryParse(isoValue);
    if (date == null) return isoValue;
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();

    // Respect caller-provided firstDate/lastDate; fall back to sensible defaults.
    final DateTime first = widget.firstDate ?? now;
    final DateTime last =
        widget.lastDate ?? now.add(const Duration(days: 365));

    // Determine initial date for the picker
    DateTime initial;
    if (widget.initialDate != null) {
      initial = widget.initialDate!;
    } else if (widget.value.isNotEmpty &&
        DateTime.tryParse(widget.value) != null) {
      initial = DateTime.parse(widget.value);
    } else {
      // DOB field heuristic: firstDate is way in the past (before year 2000)
      if (first.year < 2000) {
        initial = DateTime(now.year - 25, now.month, now.day);
      } else {
        initial = now;
      }
    }

    // Clamp initial to valid range
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    // Auto-detect DOB: firstDate is far in the past (before year 2000)
    final bool isDob = first.year < 2000;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      initialDatePickerMode:
          isDob ? DatePickerMode.year : DatePickerMode.day,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark || AppTheme.isDarkMode;
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: AppTheme.primaryLighter,
                    onPrimary: Colors.white,
                    surface: AppTheme.darkCard,
                    onSurface: Colors.white,
                  ),
                  dialogTheme: DialogThemeData(backgroundColor: AppTheme.darkCard),
                )
              : ThemeData.light().copyWith(
                  colorScheme: ColorScheme.light(
                    primary: AppTheme.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppTheme.textPrimaryLight,
                  ),
                  dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
                ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Store ISO string internally — existing parsers rely on YYYY-MM-DD
      final iso =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      // Display in Indian format
      final display =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      _controller.text = display;
      widget.onChanged(iso);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      onTap: () => _selectDate(context),
      validator: widget.validator,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: widget.value.isEmpty ? 'Select date' : null,
        hintStyle: TextStyle(color: AppTheme.textTertiary),
        labelText: widget.isRequired ? '${widget.label} *' : widget.label,
        labelStyle: TextStyle(
          color:
              widget.isRequired ? AppTheme.danger : AppTheme.textSecondary,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: AppTheme.surface,
        prefixIcon:
            Icon(widget.prefixIcon, color: AppTheme.primary, size: 20),
        suffixIcon: Icon(Icons.calendar_month_outlined,
            color: AppTheme.primary, size: 20),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
