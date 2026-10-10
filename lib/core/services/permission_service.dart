import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_colors.dart';

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

class PermissionService {
  /// Ensures both location service (GPS) is turned ON and location permission is granted.
  /// Triggers the native Android Google Play Services location accuracy system dialog when GPS is off.
  Future<bool> ensureLocationServiceAndPermission(BuildContext context) async {
    final locationPlugin = loc.Location();

    // 1. Check if GPS / Location Service is enabled on device
    bool serviceEnabled = await locationPlugin.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await locationPlugin.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }

    if (!context.mounted) return false;

    // 2. Check location permission
    return await requestLocationPermission(context);
  }

  /// Request Location Permission with custom dialog if permanently denied
  Future<bool> requestLocationPermission(BuildContext context) async {
    PermissionStatus status = await Permission.location.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.location.request();
      if (status.isGranted) return true;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      if (context.mounted) {
        _showPermissionDialog(
          context,
          title: 'Location Permission Required',
          description:
              'Ridonova requires your location to set pickup points and match you with nearby captains. Please enable location in App Settings.',
          onOpenSettings: () {
            openAppSettings();
          },
        );
      }
      return false;
    }

    return status.isGranted;
  }

  /// Request Notification Permission (Android 13+ & iOS)
  Future<bool> requestNotificationPermission(BuildContext context) async {
    PermissionStatus status = await Permission.notification.status;

    if (status.isGranted) {
      return true;
    }

    status = await Permission.notification.request();

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionDialog(
          context,
          title: 'Notification Permission',
          description: 'Enable notifications to receive real-time updates on captain arrival and ride status.',
          onOpenSettings: () {
            openAppSettings();
          },
        );
      }
    }

    return status.isGranted;
  }

  /// Request Camera Permission
  Future<bool> requestCameraPermission(BuildContext context) async {
    PermissionStatus status = await Permission.camera.request();
    if (status.isPermanentlyDenied && context.mounted) {
      _showPermissionDialog(
        context,
        title: 'Camera Permission',
        description: 'Camera access is required to capture profile photo or scan verification QR codes.',
        onOpenSettings: () {
          openAppSettings();
        },
      );
    }
    return status.isGranted;
  }

  /// Custom Permission Dialog
  void _showPermissionDialog(BuildContext context, {required String title, required String description, required VoidCallback onOpenSettings}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(description, style: const TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onOpenSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }
}
