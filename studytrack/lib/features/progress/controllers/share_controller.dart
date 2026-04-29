import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ShareController extends ChangeNotifier {
  bool _isCapturing = false;
  String? _lastError;

  bool get isCapturing => _isCapturing;
  String? get lastError => _lastError;

  /// Captures card as image and shares it via Share Plus
  Future<void> captureAndShare(GlobalKey key) async {
    try {
      _isCapturing = true;
      notifyListeners();

      final image = await _captureWidget(key);
      if (image == null) {
        _lastError = 'Failed to capture widget';
        notifyListeners();
        return;
      }

      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/studytrack_card_${DateTime.now().millisecondsSinceEpoch}.png';

      final file = await _saveImage(image, imagePath);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Check out my StudyTrack progress! 📚',
          subject: 'My StudyTrack Weekly Report',
        ),
      );

      _isCapturing = false;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      _isCapturing = false;
      notifyListeners();
    }
  }

  /// Captures card as image and saves to device gallery
  Future<void> captureAndSave(GlobalKey key) async {
    try {
      _isCapturing = true;
      notifyListeners();

      final image = await _captureWidget(key);
      if (image == null) {
        _lastError = 'Failed to capture widget';
        notifyListeners();
        return;
      }

      await Gal.putImageBytes(
        image,
        name: 'studytrack_${DateTime.now().millisecondsSinceEpoch}',
      );
      _lastError = null;

      _isCapturing = false;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      _isCapturing = false;
      notifyListeners();
    }
  }

  /// Internal method to capture widget as image
  Future<Uint8List?> _captureWidget(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 1);
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing widget: $e');
      _lastError = 'Error capturing widget: $e';
      return null;
    }
  }

  /// Save image bytes to file
  Future<File> _saveImage(Uint8List imageBytes, String path) async {
    final file = File(path);
    await file.writeAsBytes(imageBytes);
    return file;
  }

  /// Clear error message
  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}
