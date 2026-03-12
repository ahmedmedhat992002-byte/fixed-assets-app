import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:assets_management/app/routes/app_routes.dart';

import '../../../core/assets/asset_service.dart';
import '../../../core/sync/models/asset_local.dart';
import '../../../core/theme/app_colors.dart';

class AddAssetScreen extends StatefulWidget {
  const AddAssetScreen({
    super.key,
    required this.category,
    this.assetName,
    this.barcode,
    this.asset,
  });

  final String category;
  final String? assetName;
  final String? barcode;
  final AssetLocal? asset;

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _isFetchingLocation = false;
  late final TextEditingController _assetNameController;
  late final TextEditingController _barcodeController;
  final _valueController = TextEditingController();
  final _stakeholderNameController = TextEditingController();
  final _stakeholderTitleController = TextEditingController();
  final _stakeholderPhoneController = TextEditingController();
  final _stakeholderEmailController = TextEditingController();
  final _departmentController = TextEditingController();
  final _vendorController = TextEditingController();
  late TabController _tabController;

  final _phoneCodes = ['+254', '+1', '+44', '+49', '+61', '+20'];
  final _currencyOptions = ['KES', 'USD', 'EUR', 'GBP', 'EGP'];
  final _categoryOptions = [
    'Machinery',
    'Vehicles',
    'Furniture',
    'Computer Hardware',
    'Computer Software',
    'Fixed Assets',
    'Intangible',
  ];
  final _industryOptions = ['Energy', 'Finance', 'Technology', 'Retail'];

  String _selectedPhoneCode = '+254';
  String _selectedCurrency = 'Currency';
  String? _selectedCategory;
  String? _selectedIndustry;
  String? _selectedDepreciation;

  final _locationController = TextEditingController();
  final _durationController = TextEditingController();
  final _usefulLifeController = TextEditingController();
  final _salvageValueController = TextEditingController();

  final _paymentAmountController = TextEditingController();
  final _paymentRemainingController = TextEditingController();

  DateTime? _datePurchased;
  DateTime? _warrantyExpiry;
  DateTime? _malfunctionDate;
  bool _isMalfunctionNA = true;

  String _selectedPaymentPlan = 'Monthly';
  final _paymentPlanOptions = ['Monthly', 'Yearly', 'One-time'];

  final _depreciationOptions = [
    'Straight-line',
    'Declining balance',
    'Units of production',
  ];

  final List<String> _uploads = [
    'insurance documents pdf.',
    'user manual docx.',
  ];

  final List<Map<String, String>> _stakeholders = [];

  @override
  void initState() {
    super.initState();
    final asset = widget.asset;
    _assetNameController = TextEditingController(
      text: asset?.name ?? widget.assetName,
    );
    _barcodeController = TextEditingController(
      text: asset?.barcode ?? widget.barcode,
    );
    if (asset != null) {
      _valueController.text = asset.purchasePrice.toStringAsFixed(
        asset.purchasePrice % 1 == 0 ? 0 : 2,
      );
      _stakeholderNameController.text = asset.assignedTo ?? '';
      _locationController.text = asset.location ?? '';
      _usefulLifeController.text = asset.usefulLife?.toString() ?? '';
      _salvageValueController.text = asset.salvageValue?.toString() ?? '';
      _datePurchased = asset.purchaseDateMs != null
          ? DateTime.fromMillisecondsSinceEpoch(asset.purchaseDateMs!)
          : null;
      _warrantyExpiry = asset.warrantyExpiryMs != null
          ? DateTime.fromMillisecondsSinceEpoch(asset.warrantyExpiryMs!)
          : null;
      _departmentController.text = asset.department ?? '';
      _vendorController.text = asset.vendor ?? '';
    }

    // Robust category selection: normalize incoming string to match options
    final incoming = (asset?.category ?? widget.category).toLowerCase();
    _selectedCategory = _categoryOptions.firstWhere((opt) {
      final optLower = opt.toLowerCase();
      return optLower == incoming ||
          optLower.contains(incoming) ||
          incoming.contains(optLower);
    }, orElse: () => _categoryOptions.first);

    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Update the content when tab switches
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _assetNameController.dispose();
    _barcodeController.dispose();
    _valueController.dispose();
    _stakeholderNameController.dispose();
    _stakeholderTitleController.dispose();
    _stakeholderPhoneController.dispose();
    _stakeholderEmailController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _usefulLifeController.dispose();
    _salvageValueController.dispose();
    _paymentAmountController.dispose();
    _paymentRemainingController.dispose();
    _departmentController.dispose();
    _vendorController.dispose();
    super.dispose();
  }

  Future<void> _pickLocationOnMap() async {
    final LatLng? pickedLocation =
        await Navigator.pushNamed(context, AppRoutes.locationPicker) as LatLng?;

    if (pickedLocation != null) {
      setState(() => _isFetchingLocation = true);
      try {
        final placemarks = await placemarkFromCoordinates(
          pickedLocation.latitude,
          pickedLocation.longitude,
        );

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final address = [
            p.name,
            p.locality,
            p.country,
          ].where((s) => s != null && s.isNotEmpty).join(', ');
          _locationController.text = address;
        } else {
          _locationController.text =
              '${pickedLocation.latitude.toStringAsFixed(6)}, ${pickedLocation.longitude.toStringAsFixed(6)}';
        }
      } catch (e) {
        _locationController.text =
            '${pickedLocation.latitude.toStringAsFixed(6)}, ${pickedLocation.longitude.toStringAsFixed(6)}';
      } finally {
        if (mounted) {
          setState(() => _isFetchingLocation = false);
        }
      }
    }
  }

  Future<void> _submit() async {
    final assetName = _assetNameController.text.trim();
    if (assetName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Asset name is required.')));
      return;
    }

    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asset category is required.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final purchasePrice =
          double.tryParse(_valueController.text.trim()) ?? 0.0;
      final usefulLifeStr = _usefulLifeController.text.trim();
      final usefulLife = usefulLifeStr.isNotEmpty
          ? int.tryParse(usefulLifeStr)
          : null;
      final salvageStr = _salvageValueController.text.trim();
      final salvageValue = salvageStr.isNotEmpty
          ? double.tryParse(salvageStr)
          : null;

      final newAsset = AssetLocal(
        id: '', // Empty ID will trigger Uuid generation in service
        companyId: '', // Handled by AssetService
        name: assetName,
        barcode: _barcodeController.text.trim().isEmpty 
            ? null 
            : _barcodeController.text.trim(),
        category: _selectedCategory ?? widget.category,
        status: 'active', // Default to active upon creation
        purchasePrice: purchasePrice,
        currentValue: purchasePrice,
        depreciationMethod: _selectedDepreciation ?? 'None',
        version: 1,
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        assignedTo: _stakeholders.isNotEmpty
            ? _stakeholders.first['name']
            : (_stakeholderNameController.text.trim().isEmpty
                  ? null
                  : _stakeholderNameController.text.trim()),
        description: _selectedCategory, // Save original category choice here
        usefulLife: usefulLife,
        salvageValue: salvageValue,
        purchaseDateMs: _datePurchased?.millisecondsSinceEpoch,
        warrantyExpiryMs: _warrantyExpiry?.millisecondsSinceEpoch,
        department: _departmentController.text.trim().isEmpty
            ? null
            : _departmentController.text.trim(),
        vendor: _vendorController.text.trim().isEmpty
            ? null
            : _vendorController.text.trim(),
      );

      final assetService = context.read<AssetService>();
      final bool success;

      if (widget.asset != null) {
        newAsset.id = widget.asset!.id;
        newAsset.companyId = widget.asset!.companyId;
        newAsset.version = widget.asset!.version;
        success = await assetService.updateAsset(newAsset);
      } else {
        success = await assetService.addAsset(newAsset);
      }

      if (!mounted) return;

      if (success) {
        // Prevent Navigator.pop() from being called unless the Firestore write completes successfully
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(assetService.lastError ?? 'Failed to add asset'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addStakeholder() {
    final name = _stakeholderNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stakeholder name is required.')),
      );
      return;
    }

    setState(() {
      _stakeholders.add({
        'name': name,
        'title': _stakeholderTitleController.text.trim(),
        'phone':
            '$_selectedPhoneCode ${_stakeholderPhoneController.text.trim()}',
        'email': _stakeholderEmailController.text.trim(),
      });
      _stakeholderNameController.clear();
      _stakeholderTitleController.clear();
      _stakeholderPhoneController.clear();
      _stakeholderEmailController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.primary, size: 30),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color.fromARGB(255, 226, 228, 231),
              child: Icon(Icons.person, color: AppColors.secondary, size: 20),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(20),
          child: Divider(
            height: 1,
            color: AppColors.primary,
            endIndent: 20,
            indent: 20,
            thickness: 1.6,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Text(
                    _selectedCategory ?? 'Add asset',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      onTap: (index) {
                        setState(() {}); // Ensure content updates on tap
                      },
                      tabs: const [
                        Tab(text: 'Asset'),
                        Tab(text: 'User'),
                        Tab(text: 'More'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Content based on tab index
                _buildTabContent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    switch (_tabController.index) {
      case 0:
        return _buildAssetDetailsTab(context);
      case 1:
        return _buildStakeholderTab(context);
      case 2:
        return _buildMoreTab(context);
      default:
        return _buildAssetDetailsTab(context);
    }
  }

  Widget _buildAssetDetailsTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RoundedInputField(
            controller: _assetNameController,
            hintText: 'Asset name',
          ),
          const SizedBox(height: 16),
          _RoundedInputField(
            controller: _barcodeController,
            hintText: 'Code',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, fieldConstraints) {
              return Wrap(
                spacing: 10,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: fieldConstraints.maxWidth,
                    child: _DropdownField(
                      hintText: 'Industry',
                      value: _selectedIndustry,
                      items: _industryOptions,
                      onChanged: (value) =>
                          setState(() => _selectedIndustry = value),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, fieldConstraints) {
              return Row(
                children: [
                  Expanded(
                    child: _DropdownField(
                      hintText: 'Currency',
                      value: _selectedCurrency == 'Currency'
                          ? null
                          : _selectedCurrency,
                      items: _currencyOptions,
                      fontSize: 14,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCurrency = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RoundedInputField(
                      controller: _valueController,
                      hintText: 'Value',
                      keyboardType: TextInputType.number,
                      fontSize: 14,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, fieldConstraints) {
              return Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: 'Date purchased',
                      date: _datePurchased,
                      fontSize: 14,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                      onTap: () => _pickDate(
                        context,
                        initialDate: _datePurchased,
                        onSelected: (value) =>
                            setState(() => _datePurchased = value),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RoundedInputField(
                      controller: _locationController,
                      hintText: 'Location',
                      fontSize: 14,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                      suffixWidget: _isFetchingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: SizedBox.shrink(),
                            )
                          : const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                      onSuffixTap: _pickLocationOnMap,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, fieldConstraints) {
              return Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: _DatePickerField(
                      label: 'Warranty expiry date',
                      date: _warrantyExpiry,
                      onTap: () => _pickDate(
                        context,
                        initialDate: _warrantyExpiry,
                        onSelected: (value) =>
                            setState(() => _warrantyExpiry = value),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: _RoundedInputField(
                      controller: _durationController,
                      hintText: 'Duration',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, fieldConstraints) {
              return Row(
                children: [
                  Expanded(
                    child: _RoundedInputField(
                      controller: _departmentController,
                      hintText: 'Department',
                      suffixIcon: Icons.business_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _RoundedInputField(
                      controller: _vendorController,
                      hintText: 'Vendor',
                      suffixIcon: Icons.store_outlined,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, fieldConstraints) {
              return Column(
                children: [
                  _DatePickerField(
                    label: 'Malfunction date',
                    date: _malfunctionDate,
                    enabled: !_isMalfunctionNA,
                    onTap: () {
                      if (_isMalfunctionNA) return;
                      _pickDate(
                        context,
                        initialDate: _malfunctionDate,
                        onSelected: (value) =>
                            setState(() => _malfunctionDate = value),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'N/A',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _isMalfunctionNA,
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
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _RoundedInputField(
            controller: _usefulLifeController,
            hintText: 'Useful Life (years)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _RoundedInputField(
            controller: _salvageValueController,
            hintText: 'Salvage Value',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _DropdownField(
            hintText: 'Depreciation Method',
            value: _selectedDepreciation,
            items: _depreciationOptions,
            onChanged: (value) => setState(() => _selectedDepreciation = value),
          ),
          const SizedBox(height: 32),
          _isLoading
              ? const SizedBox.shrink()
              : _PrimaryButton(label: 'Add asset', onPressed: _submit),
        ],
      ),
    );
  }

  Widget _buildStakeholderTab(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RoundedInputField(
            controller: _stakeholderNameController,
            hintText: 'Asset name',
          ),
          const SizedBox(height: 16),
          _RoundedInputField(
            controller: _stakeholderTitleController,
            hintText: 'Title',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, phoneConstraints) {
              return Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: _DropdownField(
                      hintText: 'Code',
                      value: _selectedPhoneCode,
                      items: _phoneCodes,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedPhoneCode = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RoundedInputField(
                      controller: _stakeholderPhoneController,
                      hintText: 'Phone number',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _RoundedInputField(
            controller: _stakeholderEmailController,
            hintText: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _addStakeholder,
              child: const Text(
                'Add stakeholder +',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (_stakeholders.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Added Stakeholders',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_stakeholders.length, (index) {
              final s = _stakeholders[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        (s['name'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
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
                            s['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${s['title'] ?? ''} · ${s['email'] ?? ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      onPressed: () =>
                          setState(() => _stakeholders.removeAt(index)),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 48), // Push add asset button to bottom
          _isLoading
              ? const SizedBox.shrink()
              : _PrimaryButton(label: 'Add asset', onPressed: _submit),
        ],
      ),
    );
  }

  Widget _buildMoreTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Payment plan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, paymentConstraints) {
              return Column(
                children: [
                  _DropdownField(
                    hintText: 'Plan',
                    value: _selectedPaymentPlan,
                    items: _paymentPlanOptions,
                    fontSize: 13,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 14,
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedPaymentPlan = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _RoundedInputField(
                          controller: _paymentAmountController,
                          hintText: 'Amount',
                          keyboardType: TextInputType.number,
                          fontSize: 13,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RoundedInputField(
                          controller: _paymentRemainingController,
                          hintText: 'Remaining',
                          keyboardType: TextInputType.number,
                          fontSize: 13,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Uploads',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
                style: BorderStyle
                    .solid, // Should ideally be dashed, using solid as fallback
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_outlined, size: 28, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  'an image',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
                style: BorderStyle.solid, // Should ideally be dashed
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open_outlined,
                  size: 32,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.fontFamily,
                    ),
                    children: [
                      TextSpan(
                        text: 'Upload ',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: 'your files',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ..._uploads.map(
            (file) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      file,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() => _uploads.remove(file));
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
          _isLoading
              ? const SizedBox.shrink()
              : _PrimaryButton(
                  label: widget.asset != null ? 'Update asset' : 'Add asset',
                  onPressed: _submit,
                ),
        ],
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context, {
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
}

class _RoundedInputField extends StatelessWidget {
  const _RoundedInputField({
    required this.hintText,
    this.controller,
    this.keyboardType,
    this.suffixIcon,
    this.suffixWidget,
    this.onSuffixTap,
    this.contentPadding,
    this.fontSize,
  });

  final String hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final IconData? suffixIcon;
  final Widget? suffixWidget;
  final VoidCallback? onSuffixTap;
  final EdgeInsetsGeometry? contentPadding;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: fontSize ?? 15,
        fontWeight: FontWeight.w500,
      ),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: const Color(0xFFA4ADBA),
          fontSize: fontSize ?? 15,
          fontWeight: FontWeight.w400,
        ),
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFE4E9F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        suffixIcon: suffixWidget != null
            ? UnconstrainedBox(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: onSuffixTap != null
                      ? InkWell(onTap: onSuffixTap, child: suffixWidget)
                      : suffixWidget,
                ),
              )
            : suffixIcon != null
            ? InkWell(
                onTap: onSuffixTap,
                child: Icon(
                  suffixIcon,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.hintText,
    required this.items,
    this.value,
    this.onChanged,
    this.contentPadding,
    this.fontSize,
  });

  final String hintText;
  final List<String> items;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final EdgeInsetsGeometry? contentPadding;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      onChanged: onChanged,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: fontSize ?? 15,
        fontWeight: FontWeight.w500,
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: TextStyle(fontSize: fontSize ?? 15)),
            ),
          )
          .toList(),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: const Color(0xFFA4ADBA),
          fontSize: fontSize ?? 15,
          fontWeight: FontWeight.w400,
        ),
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFE4E9F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
    this.contentPadding,
    this.fontSize,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool enabled;
  final EdgeInsetsGeometry? contentPadding;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final hasValue = date != null;
    final displayText = hasValue ? _formatDate(date!) : '';
    final textColor = hasValue
        ? AppColors.textPrimary
        : AppColors.textSecondary;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: InputDecorator(
        isEmpty: !hasValue,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            color: const Color(0xFFA4ADBA),
            fontSize: fontSize ?? 15,
            fontWeight: FontWeight.w400,
          ),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
          contentPadding:
              contentPadding ??
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFFE4E9F2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          enabled: enabled,
        ),
        child: hasValue
            ? Text(
                displayText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: enabled ? textColor : AppColors.textSecondary,
                  fontSize: fontSize ?? 15,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}
