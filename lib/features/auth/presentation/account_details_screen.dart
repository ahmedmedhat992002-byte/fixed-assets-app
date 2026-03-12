import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class Country {
  final String name;
  final String code;
  final List<Color> flagColors;

  const Country({
    required this.name,
    required this.code,
    required this.flagColors,
  });
}

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({super.key, this.onFinish});

  final VoidCallback? onFinish;

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  String _selectedJobTitle = 'Technician';
  final List<String> _jobTitles = [
    'Technician',
    'Manager',
    'Analyst',
    'Administrator',
  ];

  Country _selectedCountry = _countries[0];

  static const List<Country> _countries = [
    Country(
      name: 'United Kingdom',
      code: '+44',
      flagColors: [Colors.red, Colors.white, Colors.blue],
    ),
    Country(
      name: 'United States',
      code: '+1',
      flagColors: [Colors.red, Colors.white, Colors.blue],
    ),
    Country(name: 'Canada', code: '+1', flagColors: [Colors.red, Colors.white]),
    Country(
      name: 'Australia',
      code: '+61',
      flagColors: [Colors.blue, Colors.red, Colors.white],
    ),
    Country(
      name: 'Germany',
      code: '+49',
      flagColors: [Colors.black, Colors.red, Colors.yellow],
    ),
    Country(
      name: 'France',
      code: '+33',
      flagColors: [Colors.blue, Colors.white, Colors.red],
    ),
    Country(
      name: 'Italy',
      code: '+39',
      flagColors: [Colors.green, Colors.white, Colors.red],
    ),
    Country(
      name: 'Spain',
      code: '+34',
      flagColors: [Colors.red, Colors.yellow, Colors.red],
    ),
    Country(name: 'Japan', code: '+81', flagColors: [Colors.white, Colors.red]),
    Country(
      name: 'China',
      code: '+86',
      flagColors: [Colors.red, Colors.yellow],
    ),
    Country(
      name: 'India',
      code: '+91',
      flagColors: [Colors.orange, Colors.white, Colors.green],
    ),
    Country(
      name: 'Brazil',
      code: '+55',
      flagColors: [Colors.green, Colors.yellow, Colors.blue],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'WorldAssets',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Account details',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(height: 25),
                            TextField(
                              decoration: const InputDecoration(
                                hintText: 'First name',
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textPrimary,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),
                            TextField(
                              decoration: const InputDecoration(
                                hintText: 'Last name',
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textPrimary,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedJobTitle,
                              decoration: const InputDecoration(
                                hintText: 'Job title',
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textPrimary,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 20,
                                ),
                              ),
                              items: _jobTitles
                                  .map(
                                    (title) => DropdownMenuItem<String>(
                                      value: title,
                                      child: Text(title),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedJobTitle = value;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 25),
                            _PhoneNumberField(
                              selectedCountry: _selectedCountry,
                              countries: _countries,
                              onCountryChanged: (country) {
                                setState(() {
                                  _selectedCountry = country;
                                });
                              },
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: widget.onFinish,
                              child: Text(
                                'Finish',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PhoneNumberField extends StatelessWidget {
  const _PhoneNumberField({
    required this.selectedCountry,
    required this.countries,
    required this.onCountryChanged,
  });

  final Country selectedCountry;
  final List<Country> countries;
  final ValueChanged<Country> onCountryChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Country Selector
          InkWell(
            onTap: () => _showCountryPicker(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CountryFlag(flagColors: selectedCountry.flagColors),
                  const SizedBox(width: 8),
                  Text(
                    selectedCountry.code,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Separator
          Container(width: 1, height: 24, color: AppColors.border),
          // Phone Number Input
          Expanded(
            child: TextField(
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Phone number',
                hintStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Country',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...countries.map(
                (country) => ListTile(
                  leading: _CountryFlag(flagColors: country.flagColors),
                  title: Text(country.name),
                  trailing: Text(
                    country.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    onCountryChanged(country);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryFlag extends StatelessWidget {
  const _CountryFlag({required this.flagColors});

  final List<Color> flagColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: _buildFlag(),
      ),
    );
  }

  Widget _buildFlag() {
    if (flagColors.length == 1) {
      return Container(color: flagColors[0]);
    } else if (flagColors.length == 2) {
      return Row(
        children: [
          Expanded(child: Container(color: flagColors[0])),
          Expanded(child: Container(color: flagColors[1])),
        ],
      );
    } else {
      // For flags with 3 colors (like UK, US, etc.)
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(color: flagColors[0]),
          if (flagColors.length >= 2)
            Align(
              alignment: Alignment.center,
              child: Container(
                width: double.infinity,
                height: flagColors.length == 3 ? 8 : 24,
                color: flagColors[1],
              ),
            ),
          if (flagColors.length >= 3)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 12,
                height: double.infinity,
                color: flagColors[2],
              ),
            ),
        ],
      );
    }
  }
}
