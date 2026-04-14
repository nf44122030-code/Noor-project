import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionsHelper {
  /// Request camera and microphone permissions for video sessions
  static Future<bool> requestVideoCallPermissions(BuildContext context) async {
    // Check current permission status
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    final microphoneGranted = statuses[Permission.microphone]?.isGranted ?? false;

    if (!cameraGranted || !microphoneGranted) {
      // Show dialog explaining why permissions are needed
      if (context.mounted) {
        await _showPermissionDeniedDialog(
          context,
          !cameraGranted,
          !microphoneGranted,
        );
      }
      return false;
    }

    return true;
  }

  /// Check if video call permissions are already granted
  static Future<bool> hasVideoCallPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;

    return cameraStatus.isGranted && microphoneStatus.isGranted;
  }

  /// Show dialog when permissions are denied
  static Future<void> _showPermissionDeniedDialog(
    BuildContext context,
    bool cameraDenied,
    bool microphoneDenied,
  ) async {
    final List<String> deniedPermissions = [];
    if (cameraDenied) deniedPermissions.add('Camera');
    if (microphoneDenied) deniedPermissions.add('Microphone');

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To join video sessions, Intellix needs access to:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...deniedPermissions.map((permission) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        permission == 'Camera' ? Icons.videocam : Icons.mic,
                        size: 20,
                        color: const Color(0xFF5B9FF3),
                      ),
                      const SizedBox(width: 8),
                      Text(permission),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            const Text(
              'These permissions allow you to communicate with experts during sessions and enable AI note-taking.',
              style: TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B9FF3),
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Show permission rationale before requesting
  static Future<bool> showPermissionRationale(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B9FF3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.video_call,
                    color: Color(0xFF5B9FF3),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Video Session Setup'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'To start your video session, we need permission to access:',
                ),
                const SizedBox(height: 16),
                _buildPermissionItem(
                  Icons.videocam,
                  'Camera',
                  'For video communication with experts',
                ),
                const SizedBox(height: 12),
                _buildPermissionItem(
                  Icons.mic,
                  'Microphone',
                  'For audio communication and AI note-taking',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your privacy is important. Video and audio are only used during active sessions.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not Now'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B9FF3),
                ),
                child: const Text(
                  'Grant Permissions',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  static Widget _buildPermissionItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF5B9FF3).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF5B9FF3), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7F8C8D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
