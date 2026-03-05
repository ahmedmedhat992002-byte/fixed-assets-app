import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/maintenance/maintenance_service.dart';
import '../../../core/sync/models/maintenance_local.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({
    super.key,
    this.onOpenDrawer,
    this.isDrawerVisible = false,
  });

  final VoidCallback? onOpenDrawer;
  final bool isDrawerVisible;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  List<MaintenanceLocal> _getFilteredEvents(List<MaintenanceLocal> allEvents) {
    if (_selectedDay == null) return allEvents;
    return allEvents.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e.dateMs);
      return date.year == _selectedDay!.year &&
          date.month == _selectedDay!.month &&
          date.day == _selectedDay!.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final maintenanceService = Provider.of<MaintenanceService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // ... (existing AppBar code)
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu, color: AppColors.primary),
                onPressed: widget.onOpenDrawer,
              )
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        title: const Text('Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Search events coming soon')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight,
              child: const Icon(
                Icons.person_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<MaintenanceLocal>>(
        stream: maintenanceService.getMaintenanceStream(),
        builder: (context, snapshot) {
          final allEvents = snapshot.data ?? [];
          final selectedEvents = _getFilteredEvents(allEvents);

          return Column(
            children: [
              const Divider(
                color: AppColors.primary,
                thickness: 1.2,
                height: 1,
              ),
              // Calendar card
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [
                    // Month header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: () => setState(() {
                              _focusedMonth = DateTime(
                                _focusedMonth.year,
                                _focusedMonth.month - 1,
                              );
                            }),
                          ),
                          Column(
                            children: [
                              Text(
                                _monthName(_focusedMonth.month),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _focusedMonth.year.toString(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            onPressed: () => setState(() {
                              _focusedMonth = DateTime(
                                _focusedMonth.year,
                                _focusedMonth.month + 1,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    // Weekday labels
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children:
                            const [
                                  'Mon',
                                  'Tue',
                                  'Wed',
                                  'Thu',
                                  'Fri',
                                  'Sat',
                                  'Sun',
                                ]
                                .map(
                                  (d) => Expanded(
                                    child: Center(
                                      child: Text(
                                        d,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Day grid
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                      child: _MonthGrid(
                        focusedMonth: _focusedMonth,
                        selectedDay: _selectedDay,
                        events: allEvents,
                        onDayTap: (day) => setState(() => _selectedDay = day),
                      ),
                    ),
                  ],
                ),
              ),
              // Events list
              Expanded(
                child: selectedEvents.isEmpty
                    ? Center(
                        child: Text(
                          'No events on this day',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: selectedEvents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) =>
                            _EventTile(event: selectedEvents[i]),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_schedule_add_event',
        backgroundColor: AppColors.primary,
        onPressed: _showAddEventSheet,
        icon: Icon(Icons.add, color: theme.colorScheme.onPrimary),
        label: Text(
          'Add Event',
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showAddEventSheet() {
    final theme = Theme.of(context);
    final titleCtrl = TextEditingController();
    String selectedType = 'Inspection';
    final types = ['Inspection', 'Service', 'Audit', 'Meeting', 'Other'];
    DateTime? selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Add Event',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleCtrl,
                    decoration: _inputDeco('Event Title'),
                  ),
                  const SizedBox(height: 12),
                  // Type picker row
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: types.map((t) {
                        final sel = t == selectedType;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(t),
                            selected: sel,
                            onSelected: (_) =>
                                setModalState(() => selectedType = t),
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: sel ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Date picker
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: _selectedDay ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(
                      selectedDate == null
                          ? 'Pick Date'
                          : '${selectedDate?.day.toString().padLeft(2, '0')}-${selectedDate?.month.toString().padLeft(2, '0')}-${selectedDate?.year}',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: Builder(
                      builder: (bCtx) {
                        final maintenanceService =
                            Provider.of<MaintenanceService>(
                              bCtx,
                              listen: false,
                            );
                        return FilledButton(
                          onPressed: () async {
                            if (titleCtrl.text.isEmpty ||
                                selectedDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill in all fields'),
                                ),
                              );
                              return;
                            }

                            final record = MaintenanceLocal(
                              id: '',
                              assetId:
                                  'manual_event', // Placeholder for non-asset events
                              assetName: 'Event',
                              dateMs: selectedDate!.millisecondsSinceEpoch,
                              type: selectedType,
                              cost: 0.0,
                              notes: titleCtrl.text,
                              status: 'scheduled',
                              updatedAtMs:
                                  DateTime.now().millisecondsSinceEpoch,
                            );

                            final navigator = Navigator.of(ctx);
                            final messenger = ScaffoldMessenger.of(context);

                            final success = await maintenanceService
                                .addMaintenance(record);

                            if (success) {
                              if (context.mounted) navigator.pop();
                              setState(() {
                                _selectedDay = selectedDate;
                              });
                              if (context.mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Event "${titleCtrl.text}" added',
                                    ),
                                  ),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error adding event: ${maintenanceService.lastError}',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: maintenanceService.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: SizedBox.shrink(),
                                )
                              : Text(
                                  'Save Event',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                        );
                      },
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

  InputDecoration _inputDeco(String label) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.3,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month];
  }
}

// ── Calendar Month Grid ───────────────────────────────────────────────────────
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.focusedMonth,
    required this.selectedDay,
    required this.events,
    required this.onDayTap,
  });

  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final List<MaintenanceLocal> events;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    // Monday-based: Monday = 0
    int leadingBlanks = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
    ).day;
    final prevMonth = DateTime(focusedMonth.year, focusedMonth.month - 1, 0);
    final nextMonthStart = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      1,
    );

    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIdx) {
        return Row(
          children: List.generate(7, (colIdx) {
            final cellIdx = rowIdx * 7 + colIdx;
            final dayOffset = cellIdx - leadingBlanks;

            DateTime day;
            bool currentMonth;
            if (dayOffset < 0) {
              day = DateTime(
                prevMonth.year,
                prevMonth.month,
                prevMonth.day + 1 + dayOffset,
              );
              currentMonth = false;
            } else if (dayOffset >= daysInMonth) {
              day = DateTime(
                nextMonthStart.year,
                nextMonthStart.month,
                dayOffset - daysInMonth + 1,
              );
              currentMonth = false;
            } else {
              day = DateTime(
                focusedMonth.year,
                focusedMonth.month,
                dayOffset + 1,
              );
              currentMonth = true;
            }

            return Expanded(
              child: _DayCell(
                day: day,
                currentMonth: currentMonth,
                isSelected:
                    selectedDay != null && _sameDay(day, selectedDay ?? day),
                hasEvent: events.any((e) {
                  final eDate = DateTime.fromMillisecondsSinceEpoch(e.dateMs);
                  return _sameDay(eDate, day);
                }),
                onTap: () => onDayTap(day),
              ),
            );
          }),
        );
      }),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.currentMonth,
    required this.isSelected,
    required this.hasEvent,
    required this.onTap,
  });

  final DateTime day;
  final bool currentMonth;
  final bool isSelected;
  final bool hasEvent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color textColor = currentMonth
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
    BorderRadius radius = BorderRadius.circular(12);

    if (isSelected) {
      bgColor = AppColors.primary;
      textColor = Theme.of(context).colorScheme.onPrimary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(color: bgColor, borderRadius: radius),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.day.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
            if (hasEvent && !isSelected)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Event Tile ────────────────────────────────────────────────────────────────
class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final MaintenanceLocal event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.fromMillisecondsSinceEpoch(event.dateMs);

    // Assign colors based on type
    Color indicatorColor = AppColors.primary;
    if (event.type == 'Service') indicatorColor = AppColors.warning;
    if (event.type == 'Audit') indicatorColor = AppColors.secondary;
    if (event.type == 'Meeting') indicatorColor = AppColors.success;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 72,
            decoration: BoxDecoration(
              color: indicatorColor,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.notes ?? 'No Title',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${event.type} · ${event.assetName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_pad(date.day)}-${_pad(date.month)}-${date.year}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
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

  String _pad(int n) => n.toString().padLeft(2, '0');
}
