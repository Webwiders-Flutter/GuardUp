import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Thrown when the user picks a video that is only available in the cloud
/// (e.g. a Google Photos video that hasn't been downloaded to the device yet).
class VideoNotLocalException implements Exception {
  const VideoNotLocalException();
}

class MediaPickerService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage({
    required ImageSource source,
    bool cropImage = true,
    required BuildContext context,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        if (cropImage) {
          CroppedFile? croppedFile = await ImageCropper().cropImage(
            sourcePath: pickedFile.path,
            aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: context.l10n.cropImage,
                toolbarColor: AppColors.primary,
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.square,
                lockAspectRatio: true,
              ),
              IOSUiSettings(
                title: context.l10n.cropImage,
                aspectRatioLockEnabled: true,
              ),
            ],
          );
          if (croppedFile != null) {
            return File(croppedFile.path);
          }
          // User cancelled the crop — return null gracefully.
          return null;
        } else {
          return File(pickedFile.path);
        }
      }
    } on PlatformException catch (e) {
      // Handles cases like permission denied, activity destroyed, etc.
      debugPrint(
        'MediaPickerService PlatformException (pickImage): ${e.code} — ${e.message}',
      );
    } catch (e) {
      debugPrint('MediaPickerService error (pickImage): $e');
    }
    return null;
  }

  Future<List<File>?> pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        return pickedFiles.map((x) => File(x.path)).toList();
      }
    } catch (e) {
      debugPrint("MediaPickerService error: $e");
    }
    return null;
  }

  Future<List<File>?> pickFiles({bool allowMultiple = true}) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'webp'],
        // allowMultiple: allowMultiple,
      );

      if (result.isNotEmpty) {
        return result
            .where((f) => f.path != null)
            .map((f) => File(f.path!))
            .toList();
      }
    } catch (e) {
      debugPrint("MediaPickerService error: $e");
    }
    return null;
  }

  Future<File?> pickDocument({
    List<String> allowedExtensions = const [
      'pdf',
      'doc',
      'docx',
      'jpg',
      'jpeg',
      'png',
      'webp',
    ],
  }) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        // allowMultiple: false,
      );

      if (result.isNotEmpty && result.first.path != null) {
        return File(result.first.path!);
      }
    } catch (e) {
      debugPrint("MediaPickerService error: $e");
    }
    return null;
  }

  Future<File?> pickVideo({
    required ImageSource source,
    Duration? maxDuration,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: maxDuration,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } on PlatformException catch (e) {
      if (e.code == 'no_valid_video_uri') {
        // This happens when the user selects a video from Google Photos (or similar
        // cloud-backed gallery) that hasn't been fully downloaded to the device yet.
        // The OS returns a content URI but it can't be resolved to a local file path.
        throw const VideoNotLocalException();
      }
      debugPrint("MediaPickerService error: $e");
    } catch (e) {
      debugPrint("MediaPickerService error: $e");
    }
    return null;
  }
}
