import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/complaint_model.dart';
import '../../data/repositories/complaint_repository.dart';

abstract class ComplaintState extends Equatable {
  const ComplaintState();

  @override
  List<Object?> get props => [];
}

class ComplaintInitial extends ComplaintState {}

class ComplaintLoading extends ComplaintState {}

class ComplaintLoaded extends ComplaintState {
  final List<ComplaintModel> complaints;
  final bool isSubmitting;

  const ComplaintLoaded({
    required this.complaints,
    this.isSubmitting = false,
  });

  ComplaintLoaded copyWith({
    List<ComplaintModel>? complaints,
    bool? isSubmitting,
  }) {
    return ComplaintLoaded(
      complaints: complaints ?? this.complaints,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [complaints, isSubmitting];
}

class ComplaintError extends ComplaintState {
  final String message;

  const ComplaintError(this.message);

  @override
  List<Object?> get props => [message];
}

class ComplaintCubit extends Cubit<ComplaintState> {
  final ComplaintRepository _repository;

  ComplaintCubit({ComplaintRepository? repository})
      : _repository = repository ?? ComplaintRepository(),
        super(ComplaintInitial());

  Future<void> loadComplaints() async {
    emit(ComplaintLoading());
    try {
      final complaints = await _repository.getMyComplaints();
      emit(ComplaintLoaded(complaints: complaints));
    } catch (e) {
      emit(ComplaintError(e.toString()));
    }
  }

  Future<ComplaintModel?> submitComplaint({
    required String subject,
    required String description,
    required String category,
  }) async {
    final current = state;
    if (current is ComplaintLoaded) {
      emit(current.copyWith(isSubmitting: true));
    } else {
      emit(const ComplaintLoaded(complaints: [], isSubmitting: true));
    }

    try {
      final created = await _repository.createComplaint(
        subject: subject,
        description: description,
        category: category,
      );
      final complaints = await _repository.getMyComplaints();
      emit(ComplaintLoaded(complaints: complaints));
      return created;
    } catch (e) {
      if (current is ComplaintLoaded) {
        emit(current.copyWith(isSubmitting: false));
      } else {
        emit(ComplaintError(e.toString()));
      }
      rethrow;
    }
  }

  void reset() {
    emit(ComplaintInitial());
  }

  ComplaintModel? findById(String id) {
    final current = state;
    if (current is! ComplaintLoaded) return null;
    for (final complaint in current.complaints) {
      if (complaint.id == id) return complaint;
    }
    return null;
  }
}
