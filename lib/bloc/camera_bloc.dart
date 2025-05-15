import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:session7_mobile_sensor/ui/camera_page_bloc.dart';
import 'package:session7_mobile_sensor/storage_helper_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'camera_event.dart';
import 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  late final List<CameraDescription> _cameras;

  CameraBloc() : super(CameraInitial()) {
    on<InitializeCamera>(_onInit);
    on<SwitchCamera>(_onSwitchCamera);
    on<ToggleFlash>(_onToggleFlash);
    on<TakePicture>(_onTakePicture);
    on<TapToFocus>(_onTapFocus);
    on<PickImageFromGallery>(_onPickGallery);
    on<OpenCameraAndCapture>(_onOpenCamera);
    on<DeleteImage>(_onDeleteImage);
    on<ClearSnackbar>(_onClearSnackBar);
    on<RequestPermissions>(_onRequestPermissions);
  }

  Future<void> _onInit(
    InitializeCamera event,
    Emitter<CameraState> emit,
  ) async {
    _cameras = await availableCameras();
  }

  Future<void> _onSwitchCamera(
    SwitchCamera event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final s = state as CameraReady;
    final next = (s.selectedIndex + 1) % _cameras.length;
    await _setupController(emit, next, previous: s);
  }

  Future<void> _onToggleFlash(
    ToggleFlash event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final s = state as CameraReady;
    final next =
        s.flashMode == FlashMode.auto
            ? FlashMode.always
            : s.flashMode == FlashMode.always
            ? FlashMode.off
            : FlashMode.auto;
    await s.controller.setFlashMode(next);
    emit(s.copyWith(flashMode: next));
  }

  Future<void> _onTakePicture(
    TakePicture event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final s = state as CameraReady;
    final file = await s.controller.takePicture();
    emit(s.copyWith(imageFile: File(file.path)));
  }

  Future<void> _onTapFocus(TapToFocus event, Emitter<CameraState> emit) async {
    if (state is! CameraReady) return;
    final s = state as CameraReady;
    final relative = Offset(
      event.position.dx / event.previewSize.width,
      event.position.dy / event.previewSize.height,
    );
    await s.controller.setFocusPoint(relative);
    await s.controller.setExposurePoint(relative);
  }

  Future<void> _onPickGallery(
    PickImageFromGallery event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      emit(
        (state as CameraReady).copyWith(
          imageFile: File(file.path),
          snackbarMessage: 'Berhasil memilih dari galeri',
        ),
      );
    }
  }

  Future<void> _onOpenCamera(
    OpenCameraAndCapture event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) {
      print('[CameraBloc] state is not ready, abort!');
      return;
    }

    final file = await Navigator.push<File?>(
      event.context,
      MaterialPageRoute(
        builder:
            (_) => BlocProvider.value(value: this, child: const CameraPage()),
      ),
    );

    if (file != null) {
      final saved = await StorageHelper.saveImage(file, 'camera');
      emit(
        (state as CameraReady).copyWith(
          imageFile: saved,
          snackbarMessage: 'Disimpan: ${saved.path}',
        ),
      );
    }
  }

  Future<void> _onDeleteImage(
    DeleteImage event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final s = state as CameraReady;
    await s.imageFile?.delete();
    emit(
      s.copyWith(
        controller: s.controller,
        selectedIndex: s.selectedIndex,
        flashMode: s.flashMode,
        imageFile: null,
        snackbarMessage: 'Gambar dihapus',
      ),
    );
  }

  Future<void> _onClearSnackBar(
    ClearSnackbar event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    emit((state as CameraReady).copyWith(snackbarMessage: null));
  }

  Future<void> _setupController(
    Emitter<CameraState> emit,
    int index, {
    CameraReady? previous,
  }) async {
    await previous?.controller.dispose();
    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.max,
      enableAudio: false,
    );
    await controller.initialize();
    await controller.setFlashMode(previous?.flashMode ?? FlashMode.off);

    emit(
      CameraReady(
        controller: controller,
        selectedIndex: index,
        flashMode: previous?.flashMode ?? FlashMode.off,
        imageFile: previous?.imageFile,
        snackbarMessage: null,
      ),
    );
  }

  @override
  Future<void> close() async {
    if (state is CameraReady) {
      await (state as CameraReady).controller.dispose();
    }
    return super.close();
  }

  Future<void> _onRequestPermissions(
    RequestPermissions event,
    Emitter<CameraState> emit,
  ) async {
    final statuses =
        await [
          Permission.camera,
          Permission.storage,
          Permission.manageExternalStorage,
        ].request();

    final denied = statuses.entries.where((e) => !e.value.isGranted).toList();

    if (denied.isNotEmpty) {
      if (state is CameraReady) {
        emit(
          (state as CameraReady).copyWith(
            snackbarMessage: 'Izin kamera atau penyimpanan ditolak',
          ),
        );
      }
    }
  }
}
