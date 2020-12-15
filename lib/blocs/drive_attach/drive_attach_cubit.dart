import 'package:ardrive/blocs/blocs.dart';
import 'package:ardrive/l11n/validation_messages.dart';
import 'package:ardrive/misc/misc.dart';
import 'package:ardrive/models/models.dart';
import 'package:ardrive/services/services.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';
import 'package:reactive_forms/reactive_forms.dart';

part 'drive_attach_state.dart';

/// [DriveAttachCubit] includes logic for attaching drives to the user's profile.
class DriveAttachCubit extends Cubit<DriveAttachState> {
  FormGroup form;

  final ArweaveService _arweave;
  final DrivesDao _drivesDao;
  final SyncCubit _syncBloc;
  final DrivesCubit _drivesBloc;

  DriveAttachCubit({
    @required ArweaveService arweave,
    @required DrivesDao drivesDao,
    @required SyncCubit syncBloc,
    @required DrivesCubit drivesBloc,
  })  : _arweave = arweave,
        _drivesDao = drivesDao,
        _syncBloc = syncBloc,
        _drivesBloc = drivesBloc,
        super(DriveAttachInitial()) {
    form = FormGroup(
      {
        'driveId': FormControl<String>(
          validators: [Validators.required],
          asyncValidators: [_driveNameLoader],
          // Debounce drive name loading by 500ms.
          asyncValidatorsDebounceTime: 500,
        ),
        'name': FormControl<String>(
          validators: [
            Validators.required,
            Validators.pattern(kDriveNameRegex),
          ],
        ),
      },
    );
  }

  void submit() async {
    form.markAllAsTouched();

    if (form.invalid) {
      return;
    }

    emit(DriveAttachInProgress());

    try {
      final String driveId = form.control('driveId').value;
      final String driveName = form.control('name').value;

      final driveEntity = await _arweave.getLatestDriveEntityWithId(driveId);

      if (driveEntity == null) {
        form
            .control('driveId')
            .setErrors({AppValidationMessage.driveNotFound: true});
        emit(DriveAttachFailure());
        return;
      }

      await _drivesDao.insertDriveEntity(name: driveName, entity: driveEntity);

      _drivesBloc.selectDrive(driveId);
      unawaited(_syncBloc.startSync());
    } catch (err) {
      addError(err);
    }

    emit(DriveAttachSuccess());
  }

  Future<Map<String, dynamic>> _driveNameLoader(
      AbstractControl<dynamic> driveIdControl) async {
    if ((driveIdControl as AbstractControl<String>).isNullOrEmpty) {
      return null;
    }

    final String driveId = driveIdControl.value;
    final drive = await _arweave.getLatestDriveEntityWithId(driveId);

    if (drive == null) {
      return null;
    }

    form.control('name').updateValue(drive.name);

    return null;
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    emit(DriveAttachFailure());
    super.onError(error, stackTrace);
  }
}
