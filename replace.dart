import 'dart:io';

void main() async {
  final file = File('lib/features/chat/presentation/chat_detail_screen.dart');
  String content = await file.readAsString();

  content = content.replaceAll(
    'Map<String, dynamic>? _replyingTo;',
    'final ValueNotifier<Map<String, dynamic>?> _replyingTo = ValueNotifier(null);'
  );
  content = content.replaceAll(
    'setState(() => _replyingTo = msg);',
    '_replyingTo.value = msg;'
  );
  content = content.replaceAll(
    'setState(() => _replyingTo = null);',
    '_replyingTo.value = null;'
  );
  content = content.replaceAll(
    'replyTo: _replyingTo,',
    'replyTo: _replyingTo.value,'
  );
  
  // Custom case in _showMessageOptions -> Reply action
  content = content.replaceAll(
    '_replyingTo = msg;',
    '_replyingTo.value = msg;'
  );

  // The UI block
  final uiBlock = '''if (_replyingTo != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border(
                                  left: BorderSide(color: theme.colorScheme.primary, width: 4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          \\'Replying to \${_replyingTo![\\'senderName\\']}\\',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _replyingTo![\\'type\\'] == \\'sticker\\' ? \\'Sticker\\' : _replyingTo![\\'text\\'],
                                          style: theme.textTheme.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_replyingTo![\\'type\\'] == \\'sticker\\')
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(_replyingTo![\\'fileUrl\\'], width: 40, height: 40, fit: BoxFit.cover),
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () => setState(() => _replyingTo = null),
                                  ),
                                ],
                              ),
                            ),''';

  final replacementUiBlock = '''ValueListenableBuilder<Map<String, dynamic>?>(
                            valueListenable: _replyingTo,
                            builder: (context, replyingTo, child) {
                              if (replyingTo == null) return const SizedBox.shrink();
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border(
                                    left: BorderSide(color: theme.colorScheme.primary, width: 4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            \\'Replying to \${replyingTo[\\'senderName\\']}\\',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            replyingTo[\\'type\\'] == \\'sticker\\' ? \\'Sticker\\' : replyingTo[\\'text\\'] ?? \\'\\',
                                            style: theme.textTheme.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (replyingTo[\\'type\\'] == \\'sticker\\')
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.network(replyingTo[\\'fileUrl\\'], width: 40, height: 40, fit: BoxFit.cover),
                                        ),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () => _replyingTo.value = null,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),''';

  content = content.replaceFirst(uiBlock, replacementUiBlock);
  await file.writeAsString(content);
}
