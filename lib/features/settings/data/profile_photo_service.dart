import 'dart:io';

import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ProfilePhotoService {
  const ProfilePhotoService();

  Future<String?> pickAndStore({String currentPath = ''}) async {
    final selectedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 95,
      requestFullMetadata: false,
    );
    if (selectedImage == null) {
      return null;
    }

    final croppedImage = await ImageCropper().cropImage(
      sourcePath: selectedImage.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 92,
      maxWidth: 1024,
      maxHeight: 1024,
      uiSettings: <PlatformUiSettings>[
        AndroidUiSettings(
          toolbarTitle: 'Ajustar foto',
          cropStyle: CropStyle.circle,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          showCropGrid: false,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Ajustar foto',
          doneButtonTitle: 'Usar',
          cancelButtonTitle: 'Cancelar',
          cropStyle: CropStyle.circle,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    if (croppedImage == null) {
      return null;
    }

    final source = File(croppedImage.path);
    if (!await source.exists()) {
      throw FileSystemException(
        'A imagem selecionada não está mais disponível.',
      );
    }

    final supportDirectory = await getApplicationSupportDirectory();
    final profileDirectory = Directory(
      path.join(supportDirectory.path, 'profile'),
    );
    await profileDirectory.create(recursive: true);

    final destination = File(
      path.join(
        profileDirectory.path,
        'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );
    await source.copy(destination.path);

    if (currentPath.trim().isNotEmpty && currentPath != destination.path) {
      await _deleteManagedFile(currentPath);
    }

    return destination.path;
  }

  Future<void> remove(String storedPath) async {
    if (storedPath.trim().isEmpty) {
      return;
    }
    await _deleteManagedFile(storedPath);
  }

  Future<void> _deleteManagedFile(String storedPath) async {
    try {
      final supportDirectory = await getApplicationSupportDirectory();
      final profileRoot = path.normalize(
        path.join(supportDirectory.path, 'profile'),
      );
      final normalizedPath = path.normalize(storedPath);
      if (!path.isWithin(profileRoot, normalizedPath)) {
        return;
      }
      final file = File(normalizedPath);
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      // A remoção da imagem antiga não deve impedir a troca da foto.
    }
  }
}
