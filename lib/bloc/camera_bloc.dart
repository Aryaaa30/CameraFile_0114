import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'camera_event.dart';
part 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  late final List<CameraDescription> _cameras;

  CameraBloc() : super(const CameraInitial()) {
    on<InitializeCamera>(_onInit);
    on<SwitchCamera>(_onSwitchCamera);
    on<ToggleFlash>(_onToggleFlash);
    on<TakePicture>(_onTakePicture);
    on<OnTapFocus>(_onTapFocus);
    on<PickGallery>(_onPickGallery);
    on<OpenCameraAndCapture>(_onOpenCamera);
    on<DeleteImage>(_onDeleteImage);
    on<ClearSnackBar>(_onClearSnackBar);
    on<RequestPermissions>(_onRequestPermissions);
  }
}
