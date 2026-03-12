import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.accentColor,
    this.buttonLabel = 'Next',
  });

  final String title;
  final String subtitle;
  final IconData image;
  final Color accentColor;
  final String buttonLabel;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _controller;
  final ValueNotifier<int> _pageNotifier = ValueNotifier(0);

  static const pages = [
    OnboardingPageData(
      title: 'Track Your Assets Effortlessly',
      subtitle:
          'From offices to warehouses — track every asset in real time with accuracy and control.',
      image: Icons.group_work_rounded,
      accentColor: AppColors.primary,
    ),
    OnboardingPageData(
      title: 'Smart Insights for Smarter Businesses',
      subtitle:
          'Generate reports and understand your asset performance instantly.',
      image: Icons.analytics_outlined,
      accentColor: Color(0xFF4C6CF0),
    ),
    OnboardingPageData(
      title: 'Scan and Locate Instantly',
      subtitle:
          'Scan QR codes to access asset details, verify locations, and confirm ownership in seconds.',
      image: Icons.qr_code_scanner,
      accentColor: Color(0xFFFFC400),
      buttonLabel: 'Let\'s start',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageNotifier.dispose();
    super.dispose();
  }

  void _handleNext() {
    final current = _pageNotifier.value;
    if (current == pages.length - 1) {
      widget.onFinished?.call();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (index) => _pageNotifier.value = index,
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        Container(
                          height: 220,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Icon(
                            page.image,
                            size: 120,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: _pageNotifier,
                    builder: (context, index, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: i == index ? 28 : 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: i == index
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onPrimary.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  ValueListenableBuilder<int>(
                    valueListenable: _pageNotifier,
                    builder: (context, index, _) {
                      final page = pages[index];
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.onPrimary,
                            foregroundColor: theme.colorScheme.primary,
                            textStyle: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(page.buttonLabel),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
