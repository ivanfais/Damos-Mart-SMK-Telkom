import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/cooperative_info_model.dart';
import '../../data/repositories/cooperative_repository.dart';

// States
abstract class CooperativeState extends Equatable {
  const CooperativeState();

  @override
  List<Object?> get props => [];
}

class CooperativeInitial extends CooperativeState {}

class CooperativeLoading extends CooperativeState {}

class CooperativeLoaded extends CooperativeState {
  final List<OperatingHourModel> operatingHours;
  final List<CrowdDataModel> crowdData;
  final List<CooperativeInfoModel> infoItems;
  final CooperativeStatusModel currentStatus;

  const CooperativeLoaded({
    required this.operatingHours,
    required this.crowdData,
    this.infoItems = const [],
    this.currentStatus = const CooperativeStatusModel(condition: 'NORMAL'),
  });

  CooperativeLoaded copyWith({
    List<OperatingHourModel>? operatingHours,
    List<CrowdDataModel>? crowdData,
    List<CooperativeInfoModel>? infoItems,
    CooperativeStatusModel? currentStatus,
  }) {
    return CooperativeLoaded(
      operatingHours: operatingHours ?? this.operatingHours,
      crowdData: crowdData ?? this.crowdData,
      infoItems: infoItems ?? this.infoItems,
      currentStatus: currentStatus ?? this.currentStatus,
    );
  }

  @override
  List<Object?> get props => [operatingHours, crowdData, infoItems, currentStatus];
}

class CooperativeError extends CooperativeState {
  final String message;

  const CooperativeError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class CooperativeCubit extends Cubit<CooperativeState> {
  final CooperativeRepository _repository;

  CooperativeCubit({CooperativeRepository? repository})
      : _repository = repository ?? CooperativeRepository(),
        super(CooperativeInitial());

  Future<void> loadCooperativeInfo() async {
    emit(CooperativeLoading());
    try {
      final hours = await _repository.getOperatingHours();
      final crowd = await _repository.getCrowdData();
      final info = await _repository.getCooperativeInfo();
      final status = await _repository.getCurrentStatus();
      emit(CooperativeLoaded(
        operatingHours: hours,
        crowdData: crowd,
        infoItems: info,
        currentStatus: status,
      ));
    } catch (e) {
      emit(CooperativeError(e.toString()));
    }
  }

  Future<void> loadCurrentStatus() async {
    try {
      final status = await _repository.getCurrentStatus();
      final current = state;
      if (current is CooperativeLoaded) {
        emit(current.copyWith(currentStatus: status));
      } else {
        emit(CooperativeLoaded(
          operatingHours: const [],
          crowdData: const [],
          currentStatus: status,
        ));
      }
    } catch (e) {
      if (state is! CooperativeLoaded) {
        emit(CooperativeError(e.toString()));
      }
    }
  }
}
