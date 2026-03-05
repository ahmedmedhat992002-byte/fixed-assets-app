import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import 'package:open_file/open_file.dart';
import '../../../../core/files/files_service.dart';
import 'package:intl/intl.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  String _selectedCategory = 'All';

  // The static dummy _folders list is removed.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<FileItem>>(
        stream: context.read<FilesService>().getFilesStream(category: 'All'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }

          final allFiles = snapshot.data ?? [];
          final displayedFiles = _selectedCategory == 'All'
              ? allFiles
              : allFiles.where((f) => f.category == _selectedCategory).toList();

          // Calculate counts and dates for standard + dynamic categories
          final categories = <String>{'Receipts', 'Contracts', 'Asset Docs'};
          for (var f in allFiles) {
            if (f.category != 'All') categories.add(f.category);
          }

          final dynamicFolders = categories.map((cat) {
            final catFiles = allFiles.where((f) => f.category == cat).toList();
            DateTime? latestDate;
            if (catFiles.isNotEmpty) {
              latestDate = catFiles
                  .map((f) => f.createdAt)
                  .reduce((a, b) => a.isAfter(b) ? a : b);
            }
            return _FolderData(
              name: cat,
              date: latestDate != null
                  ? DateFormat('MMM dd, yyyy, hh:mm a').format(latestDate)
                  : 'No files',
              files: catFiles.length,
              users: null,
            );
          }).toList()..sort((a, b) => b.files.compareTo(a.files));

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Files',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _handleFileUpload(context),
                    icon: const Icon(
                      Icons.upload_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    label: const Text(
                      'Upload',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Folders',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 16),

              SizedBox(
                height: 165,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: dynamicFolders.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return _FolderCard(
                        folder: _FolderData(
                          name: 'All',
                          date: 'All categories',
                          files: allFiles.length,
                        ),
                        isSelected: _selectedCategory == 'All',
                        onTap: () => setState(() => _selectedCategory = 'All'),
                      );
                    }
                    final folder = dynamicFolders[i - 1];
                    return _FolderCard(
                      folder: folder,
                      isSelected: _selectedCategory == folder.name,
                      onTap: () =>
                          setState(() => _selectedCategory = folder.name),
                    );
                  },
                ),
              ),

              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedCategory == 'All'
                        ? 'Recent files'
                        : '$_selectedCategory files',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_selectedCategory != 'All')
                    TextButton(
                      onPressed: () =>
                          setState(() => _selectedCategory = 'All'),
                      child: const Text('Clear Filter'),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 8),

              if (displayedFiles.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_open_rounded,
                          size: 64,
                          color: AppColors.textMuted.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedCategory == 'All'
                              ? 'No files yet'
                              : 'No files in $_selectedCategory',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap Upload to add a new file',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: displayedFiles
                      .map(
                        (file) => _RecentFileRow(
                          file: file,
                          onDelete: () => _handleFileDelete(context, file),
                        ),
                      )
                      .toList(),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleFileUpload(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not access selected file.')),
          );
        }
        return;
      }

      final file = File(filePath);
      if (!file.existsSync()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected file no longer exists.')),
          );
        }
        return;
      }

      final fileName = result.files.single.name;
      final category = _selectedCategory == 'All'
          ? 'Others'
          : _selectedCategory;

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Processing file: $fileName...')));

      final filesService = context.read<FilesService>();
      await filesService.uploadFile(file, fileName, category: category);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File saved successfully!')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving file: $e')));
      debugPrint('Error in _handleFileUpload: $e');
    }
  }

  Future<void> _handleFileDelete(BuildContext context, FileItem file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete ${file.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Deleting ${file.name}...')));

    try {
      await context.read<FilesService>().deleteFile(file.id, file.storagePath);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File deleted')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

// ── Folder Card ──────────────────────────────────────────────────────────────
class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folder,
    required this.onTap,
    required this.isSelected,
  });
  final _FolderData folder;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 195,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.folder_rounded,
                    color: isSelected ? Colors.white : AppColors.secondary,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.more_vert,
                  size: 20,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              folder.date,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                _Badge(
                  label: '${folder.files}',
                  suffix: 'Files',
                  inverse: isSelected,
                ),
                if (folder.users != null) ...[
                  const SizedBox(width: 6),
                  _Badge(
                    label: '+${folder.users}',
                    suffix: 'Users',
                    inverse: isSelected,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.suffix,
    this.inverse = false,
  });
  final String label;
  final String suffix;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: inverse
                ? Colors.white.withValues(alpha: 0.2)
                : AppColors.secondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: inverse ? Colors.white : AppColors.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          suffix,
          style: TextStyle(
            color: inverse
                ? Colors.white.withValues(alpha: 0.7)
                : AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── Recent File Row ──────────────────────────────────────────────────────────
class _RecentFileRow extends StatelessWidget {
  const _RecentFileRow({required this.file, required this.onDelete});
  final FileItem file;
  final VoidCallback onDelete;

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () async {
            try {
              final result = await OpenFile.open(file.localPath);
              if (result.type != ResultType.done) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not open file: ${result.message}'),
                    ),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error opening file: $e')),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForType(file.type),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Uploaded: ${file.createdAt.day}/${file.createdAt.month}/${file.createdAt.year}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  file.size,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  color: Colors.white,
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: AppColors.danger),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────
class _FolderData {
  const _FolderData({
    required this.name,
    required this.date,
    required this.files,
    this.users,
  });
  final String name;
  final String date;
  final int files;
  final int? users;
}
