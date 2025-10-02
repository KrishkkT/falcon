import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import '../theme/app_theme.dart';
import '../services/screenshot_protection_service.dart';
import '../widgets/screenshot_overlay.dart';

class FileViewerScreen extends StatefulWidget {
  final String fileName;
  final String fileType;
  final String? fileUrl;

  const FileViewerScreen({
    super.key,
    required this.fileName,
    required this.fileType,
    this.fileUrl,
  });

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  @override
  void initState() {
    super.initState();
    // Enable screenshot protection when viewing files
    _enableScreenshotProtection();
  }

  Future<void> _enableScreenshotProtection() async {
    try {
      final screenshotService =
          Provider.of<ScreenshotProtectionService>(context, listen: false);
      await screenshotService.enableScreenshotProtection();
    } catch (e) {
      debugPrint('Failed to enable screenshot protection: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenshotOverlay(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.fileName),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        body: Container(
          color: Colors.black,
          child: _buildFileContent(),
        ),
      ),
    );
  }

  Widget _buildFileContent() {
    // Check if it's an image file
    if (widget.fileType.toLowerCase().contains('image') ||
        widget.fileName.toLowerCase().endsWith('.jpg') ||
        widget.fileName.toLowerCase().endsWith('.jpeg') ||
        widget.fileName.toLowerCase().endsWith('.png') ||
        widget.fileName.toLowerCase().endsWith('.gif')) {
      return _buildImageViewer();
    } else {
      return _buildGenericFileViewer();
    }
  }

  Widget _buildImageViewer() {
    if (widget.fileUrl == null) {
      return _buildPlaceholderView('Image viewer requires a file URL');
    }

    return Stack(
      children: [
        PhotoView(
          imageProvider: NetworkImage(widget.fileUrl!),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (context, event) => const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
          ),
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderView(
            'Failed to load image: $error',
          ),
        ),
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black54,
            child: Text(
              widget.fileName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenericFileViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFileIcon(),
          const SizedBox(height: 20),
          Text(
            widget.fileName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'File Type: ${widget.fileType}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            '🔒 Secure File Viewer',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Screenshot protection is enabled',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              // In a real implementation, you would implement actual file viewing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'File viewing functionality would be implemented here'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('View File'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileIcon() {
    IconData iconData;
    Color iconColor;

    if (widget.fileType.toLowerCase().contains('image')) {
      iconData = Icons.image;
      iconColor = Colors.blue;
    } else if (widget.fileType.toLowerCase().contains('pdf')) {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (widget.fileType.toLowerCase().contains('doc')) {
      iconData = Icons.description;
      iconColor = Colors.blue;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: 80,
        color: iconColor,
      ),
    );
  }

  @override
  void dispose() {
    // Disable screenshot protection when leaving the file viewer
    _disableScreenshotProtection();
    super.dispose();
  }

  Future<void> _disableScreenshotProtection() async {
    try {
      final screenshotService =
          Provider.of<ScreenshotProtectionService>(context, listen: false);
      await screenshotService.disableScreenshotProtection();
    } catch (e) {
      debugPrint('Failed to disable screenshot protection: $e');
    }
  }
}
