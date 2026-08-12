import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

Future<DateTime?> showScrollableDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => _ScrollableDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime.now(),
    ),
  );
}

class _ScrollableDatePickerDialog extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _ScrollableDatePickerDialog({
    this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_ScrollableDatePickerDialog> createState() => _ScrollableDatePickerDialogState();
}

class _ScrollableDatePickerDialogState extends State<_ScrollableDatePickerDialog> {
  DateTime? _pickedDate;

  @override
  void initState() {
    super.initState();
    _pickedDate = widget.initialDate ?? DateTime.now();
    if (_pickedDate!.isBefore(widget.firstDate)) _pickedDate = widget.firstDate;
    if (_pickedDate!.isAfter(widget.lastDate)) _pickedDate = widget.lastDate;
  }

  void _onDateSelected(DateTime date) {
    _pickedDate = date;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Select Date',
            style: AppTheme.subHeading.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.textHint.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScrollableDatePicker(
            initialDate: widget.initialDate,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            onDateSelected: _onDateSelected,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context, _pickedDate),
                child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScrollableDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateSelected;

  const ScrollableDatePicker({
    super.key,
    this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
  });

  @override
  State<ScrollableDatePicker> createState() => _ScrollableDatePickerState();
}

class _ScrollableDatePickerState extends State<ScrollableDatePicker> {
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  late int _selectedDay;
  late int _selectedMonth;
  late int _selectedYear;

  static const List<String> monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  int get _minMonth => (_selectedYear == widget.firstDate.year) ? widget.firstDate.month : 1;
  int get _maxMonth => (_selectedYear == widget.lastDate.year) ? widget.lastDate.month : 12;

  int get _daysInSelectedMonth => DateTime(_selectedYear, _selectedMonth + 1, 0).day;

  int get _minDay {
    if (_selectedYear == widget.firstDate.year && _selectedMonth == widget.firstDate.month) {
      return widget.firstDate.day;
    }
    return 1;
  }

  int get _maxDay {
    final monthDays = _daysInSelectedMonth;
    if (_selectedYear == widget.lastDate.year && _selectedMonth == widget.lastDate.month) {
      return widget.lastDate.day.clamp(1, monthDays);
    }
    return monthDays;
  }

  @override
  void initState() {
    super.initState();
    DateTime initial = widget.initialDate ?? DateTime.now();
    if (initial.isBefore(widget.firstDate)) initial = widget.firstDate;
    if (initial.isAfter(widget.lastDate)) initial = widget.lastDate;

    _selectedYear = initial.year;
    _selectedMonth = initial.month.clamp(_minMonth, _maxMonth);
    _selectedDay = initial.day.clamp(_minDay, _maxDay);

    _yearController = FixedExtentScrollController(
      initialItem: (_selectedYear - widget.firstDate.year).clamp(0, widget.lastDate.year - widget.firstDate.year),
    );
    _monthController = FixedExtentScrollController(
      initialItem: (_selectedMonth - _minMonth).clamp(0, _maxMonth - _minMonth),
    );
    _dayController = FixedExtentScrollController(
      initialItem: (_selectedDay - _minDay).clamp(0, _maxDay - _minDay),
    );

    widget.onDateSelected(DateTime(_selectedYear, _selectedMonth, _selectedDay));
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final yearCount = widget.lastDate.year - widget.firstDate.year + 1;
    final minMonth = _minMonth;
    final maxMonth = _maxMonth;
    final minDay = _minDay;
    final maxDay = _maxDay;

    final monthItems = List.generate(
      maxMonth - minMonth + 1,
      (i) => monthNames[minMonth - 1 + i],
    );
    final dayItems = List.generate(
      maxDay - minDay + 1,
      (i) => '${minDay + i}',
    );

    return Container(
      height: 220,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildColumn(
              controller: _dayController,
              items: dayItems,
              onChanged: (i) {
                final newDay = (minDay + i).clamp(minDay, maxDay);
                setState(() {
                  _selectedDay = newDay;
                });
                widget.onDateSelected(DateTime(_selectedYear, _selectedMonth, _selectedDay));
              },
            ),
          ),
          Expanded(
            child: _buildColumn(
              controller: _monthController,
              items: monthItems,
              onChanged: (i) {
                final newMonth = (minMonth + i).clamp(minMonth, maxMonth);
                setState(() {
                  _selectedMonth = newMonth;
                  // Re-clamp day for new month
                  if (_selectedDay < _minDay) _selectedDay = _minDay;
                  if (_selectedDay > _maxDay) _selectedDay = _maxDay;
                });
                final targetDayIndex = (_selectedDay - _minDay).clamp(0, _maxDay - _minDay);
                if (_dayController.hasClients) {
                  _dayController.jumpToItem(targetDayIndex);
                }
                widget.onDateSelected(DateTime(_selectedYear, _selectedMonth, _selectedDay));
              },
            ),
          ),
          Expanded(
            child: _buildColumn(
              controller: _yearController,
              items: List.generate(yearCount, (i) => '${widget.firstDate.year + i}'),
              onChanged: (i) {
                final newYear = widget.firstDate.year + i;
                setState(() {
                  _selectedYear = newYear;
                  // Re-clamp month
                  if (_selectedMonth < _minMonth) _selectedMonth = _minMonth;
                  if (_selectedMonth > _maxMonth) _selectedMonth = _maxMonth;
                  // Re-clamp day
                  if (_selectedDay < _minDay) _selectedDay = _minDay;
                  if (_selectedDay > _maxDay) _selectedDay = _maxDay;
                });
                final targetMonthIndex = (_selectedMonth - _minMonth).clamp(0, _maxMonth - _minMonth);
                if (_monthController.hasClients) {
                  _monthController.jumpToItem(targetMonthIndex);
                }
                final targetDayIndex = (_selectedDay - _minDay).clamp(0, _maxDay - _minDay);
                if (_dayController.hasClients) {
                  _dayController.jumpToItem(targetDayIndex);
                }
                widget.onDateSelected(DateTime(_selectedYear, _selectedMonth, _selectedDay));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn({
    required FixedExtentScrollController controller,
    required List<String> items,
    required ValueChanged<int> onChanged,
  }) {
    return Stack(
      children: [
        ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: 40,
          diameterRatio: 1.5,
          useMagnifier: true,
          magnification: 1.1,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: onChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              if (index < 0 || index >= items.length) return null;
              return Center(
                child: Text(
                  items[index],
                  style: AppTheme.body.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              );
            },
            childCount: items.length,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 90,
          child: IgnorePointer(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3), width: 1),
                  bottom: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3), width: 1),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
