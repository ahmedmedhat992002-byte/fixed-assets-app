import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionService {
  /// Entry point to ask for the permission. Shows a rationale dialog first.
  static Future<bool> requestStoragePermission(BuildContext context) async {
    // 1. Show the rationale dialog first
    final bool? shouldRequest = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Storage Permission'),
          content: const Text(
            'This app needs storage access to save the report. Allow permission?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow'),
            ),
          ],
        );
      },
    );

    if (shouldRequest != true) {
      return false;
    }

    // 2. We actually request the OS permission if they clicked Allow.
    if (!context.mounted) return false;
    return await handleStoragePermissionRequest(context);
  }

  /// Internal handler for the OS permissions
  static Future<bool> handleStoragePermissionRequest(
    BuildContext context,
  ) async {
    if (Platform.isIOS) {
      // iOS app documents directory does not need external permission.
      return true;
    }

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        // Android 13+
        // On Android 13+ downloading or creating files in common folders usually doesn't require runtime request
        // since storage is scoped. However, if using legacy methods without MediaStore, READ_MEDIA_* or MANAGE_EXTERNAL_STORAGE might be needed to read it back.
        // We will just return true as we only write.
        return true;
      } else {
        // Android 10 - 12 (API 29 - 32), and older
        // We need to request the `storage` permission.
        final status = await Permission.storage.request();

        if (status.isPermanentlyDenied) {
          if (context.mounted) {
            _showSettingsDialog(context);
          }
          return false;
        }
        return status.isGranted;
      }
    }

    return true;
  }

  static void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Denied'),
          content: const Text(
            'Storage permission is permanently denied. Please enable it in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }
}
