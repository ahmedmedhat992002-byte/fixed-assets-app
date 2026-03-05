import 'package:flutter/material.dart';
import 'package:assets_management/l10n/app_localizations.dart';

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Mock highly structured Knowledge Base articles
    final List<Map<String, String>> articles = [
      {
        'title': 'How to Reset Your Cloud Password',
        'category': 'Authentication',
        'content':
            'Navigate to the application login screen and press "Forgot Password". Provide your enterprise email and follow the localized instructions sent to your inbox to securely reset your credentials.',
      },
      {
        'title': 'Understanding Depreciation Formulas',
        'category': 'Financial Asset Engine',
        'content':
            'Straight Line depreciation distributes asset cost evenly over its useful life, whereas Declining Balance accelerates the expense heavily into the early years to simulate rapid technology obsolescence.',
      },
      {
        'title': 'SLA Breach Procedures',
        'category': 'Support Infrastructure',
        'content':
            'If an SLA countdown hits zero, it triggers a "Breach" state. This mathematically elevates the ticket visibility within the Support Dashboard and automatically sends formal notification emails to the governing administrators.',
      },
      {
        'title': 'Hardware Asset Onboarding',
        'category': 'Logistics',
        'content':
            'Use the scanner to parse the QR code on your new physical hardware. Make sure to define Capitalization categories rigorously so the tax engines calculate correctly.',
      },
    ];

    final filtered = articles
        .where(
          (a) =>
              a['title']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              a['content']!.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.supportKnowledgeBase,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: l.kbSearchPlaceholder,
                filled: true,
                fillColor: theme.colorScheme.surface,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? Center(child: Text(l.kbNoResults, style: theme.textTheme.bodyLarge))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: filtered.length,
              itemBuilder: (ctx, idx) {
                final a = filtered[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      a['title']!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      a['category']!,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.all(16.0),
                    children: [
                      Text(
                        a['content']!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
