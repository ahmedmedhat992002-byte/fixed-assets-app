// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AddVehicleSheet extends StatefulWidget {
  const AddVehicleSheet({super.key});

  @override
  State<AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends State<AddVehicleSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _assetNameController = TextEditingController();
  final _valueController = TextEditingController();
  final _locationController = TextEditingController();
  final _durationController = TextEditingController();

  final _categoryOptions = ['Vehicle', 'Equipment', 'Electronics', 'Furniture'];
  final _industryOptions = ['Logistics', 'Finance', 'Technology', 'Retail'];
  final _currencyOptions = ['KES', 'USD', 'EUR', 'GBP'];

  String _selectedCurrency = 'Currency';
  String? _selectedCategory;
  String? _selectedIndustry;

  DateTime? _datePurchased;
  DateTime? _insuranceExpiry;
  DateTime? _malfunctionDate;
  bool _isMalfunctionNA = true;
  String _paymentStatus = 'Fully paid';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _assetNameController.dispose();
    _valueController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? initialDate,
    required ValueChanged<DateTime?> onSelected,
  }) async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Add asset',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Asset details'),
              Tab(text: 'Stakeholder details'),
              Tab(text: 'More'),
            ],
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAssetDetailsTab(context),
                const Center(child: Text('Stakeholder details (Optional)')),
                const Center(child: Text('More (Optional)')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetDetailsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RoundedInputField(
            controller: _assetNameController,
            hintText: 'Asset name',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DropdownField(
                  hintText: 'Category',
                  value: _selectedCategory,
                  items: _categoryOptions,
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DropdownField(
                  hintText: 'Industry',
                  value: _selectedIndustry,
                  items: _industryOptions,
                  onChanged: (value) =>
                      setState(() => _selectedIndustry = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DropdownField(
                  hintText: 'Currency',
                  value: _selectedCurrency == 'Currency'
                      ? null
                      : _selectedCurrency,
                  items: _currencyOptions,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCurrency = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RoundedInputField(
                  controller: _valueController,
                  hintText: 'Value',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  label: 'Date purchased',
                  date: _datePurchased,
                  onTap: () => _pickDate(
                    initialDate: _datePurchased,
                    onSelected: (value) =>
                        setState(() => _datePurchased = value),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RoundedInputField(
                  controller: _locationController,
                  hintText: 'Location',
                  suffixIcon: Icons.location_on_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payment status section
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Payment status',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<String>(
                    value: 'Fully paid',
                    groupValue: _paymentStatus,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _paymentStatus = v!),
                  ),
                  const Text(
                    'Fully paid',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Radio<String>(
                    value: 'On loan',
                    groupValue: _paymentStatus,
                    activeColor: Colors.amber,
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.amber;
                      }
                      return AppColors.border;
                    }),
                    onChanged: (v) => setState(() => _paymentStatus = v!),
                  ),
                  const Text(
                    'On loan',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 7,
                child: _DatePickerField(
                  label: 'Insurance expiry date',
                  date: _insuranceExpiry,
                  onTap: () => _pickDate(
                    initialDate: _insuranceExpiry,
                    onSelected: (value) =>
                        setState(() => _insuranceExpiry = value),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: _RoundedInputField(
                  controller: _durationController,
                  hintText: 'Duration',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 7,
                child: _DatePickerField(
                  label: 'Malfunction date',
                  date: _malfunctionDate,
                  enabled: !_isMalfunctionNA,
                  onTap: () {
                    if (_isMalfunctionNA) return;
                    _pickDate(
                      initialDate: _malfunctionDate,
                      onSelected: (value) =>
                          setState(() => _malfunctionDate = value),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'N/A',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: _isMalfunctionNA,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                      onChanged: (value) {
                        setState(() {
                          _isMalfunctionNA = value;
                          if (value) {
                            _malfunctionDate = null;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Add asset',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundedInputField extends StatelessWidget {
  const _RoundedInputField({
    required this.hintText,
    this.controller,
    this.keyboardType,
    this.suffixIcon,
  });

  final String hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final IconData? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon, color: AppColors.textSecondary, size: 20)
              : null,
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String hintText;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hintText,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          iconEnabledColor: AppColors.textSecondary,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                date == null
                    ? label
                    : '${date!.day.toString().padLeft(2, '0')}-${date!.month.toString().padLeft(2, '0')}-${date!.year}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: date == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: enabled ? AppColors.textSecondary : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
