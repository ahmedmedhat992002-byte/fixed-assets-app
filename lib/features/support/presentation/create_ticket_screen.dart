import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:assets_management/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _entityCtrl = TextEditingController();

  String _category = 'Technical Issue';
  String _priority = 'Medium';

  bool _isSubmitting = false;

  Future<void> _submitTicket() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> tickets = [];

    final stored = prefs.getString('support_tickets_db');
    if (stored != null) {
      try {
        final List<dynamic> decoded = json.decode(stored);
        tickets = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {}
    }

    final newId =
        "TCK-${DateTime.now().year}-${(tickets.length + 1).toString().padLeft(4, '0')}";

    final newTicket = {
      'id': newId,
      'title': _titleCtrl.text.trim(),
      'category': _category,
      'priority': _priority,
      'description': _descCtrl.text.trim(),
      'relatedEntity': _entityCtrl.text.trim(),
      'status': 'Open',
      'createdAt': DateTime.now().toIso8601String(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    tickets.insert(0, newTicket);
    await prefs.setString('support_tickets_db', json.encode(tickets));

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network

    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.ticketSubmitSuccess),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _entityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    // Localize dropdowns dynamically
    final catMap = {
      'Technical Issue': l.ticketCategoryTech,
      'Asset Error': l.ticketCategoryAsset,
      'Contract Issue': l.ticketCategoryContract,
      'Billing': l.ticketCategoryBilling,
      'Security Concern': l.ticketCategorySecurity,
      'Feature Request': l.ticketCategoryFeature,
    };

    final prioMap = {
      'Low': l.ticketPriorityLow,
      'Medium': l.ticketPriorityMedium,
      'High': l.ticketPriorityHigh,
      'Critical': l.ticketPriorityCritical,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.supportCreateTicket,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: l.ticketTitleRequired,
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(
                labelText: l.ticketCategory,
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: catMap.keys
                  .map(
                    (k) => DropdownMenuItem(value: k, child: Text(catMap[k]!)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: InputDecoration(
                labelText: l.ticketPriority,
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: prioMap.keys
                  .map(
                    (k) => DropdownMenuItem(value: k, child: Text(prioMap[k]!)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _priority = v!),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: l.ticketDescription,
                alignLabelWithHint: true,
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _entityCtrl,
              decoration: InputDecoration(
                labelText: l.ticketRelatedEntity,
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.link_rounded),
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitTicket,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: const SizedBox.shrink(),
                      )
                    : Text(
                        l.ticketSubmit,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
