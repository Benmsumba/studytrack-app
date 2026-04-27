import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:image_gallery_saver/image_gallery_saver.dart';
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
      final imagePath = '${directory.path}/studytrack_card_${DateTime.now().millisecondsSinceEpoch}.png';

      final file = await _saveImage(image, imagePath);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out my StudyTrack progress! 📚',
        subject: 'My StudyTrack Weekly Report',
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

      final result = await ImageGallerySaver.saveImage(
        image,
        quality: 100,
        name: 'studytrack_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['isSuccess'] == true) {
        _lastError = null;
      } else {
        _lastError = 'Failed to save to gallery';
      }

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
      final RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing widget: $e');
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
