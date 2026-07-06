import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/favorite_repository.dart';

abstract class FavoriteState extends Equatable {
  const FavoriteState();

  @override
  List<Object?> get props => [];
}

class FavoriteInitial extends FavoriteState {}

class FavoriteIdsLoaded extends FavoriteState {
  final Set<String> ids;

  const FavoriteIdsLoaded(this.ids);

  @override
  List<Object?> get props => [ids];
}

class FavoriteCubit extends Cubit<FavoriteState> {
  final FavoriteRepository _repository;

  FavoriteCubit({FavoriteRepository? repository})
      : _repository = repository ?? FavoriteRepository(),
        super(FavoriteInitial());

  Set<String> get _currentIds => state is FavoriteIdsLoaded ? (state as FavoriteIdsLoaded).ids : {};

  bool isFavorite(String productId) => _currentIds.contains(productId);

  Future<void> loadFavoriteIds() async {
    try {
      final ids = await _repository.getFavoriteIds();
      emit(FavoriteIdsLoaded(ids.toSet()));
    } catch (_) {
      // Silently keep whatever state we had; heart icons just won't reflect server truth yet.
    }
  }

  /// Optimistically flips the heart icon, then syncs with the server in the background.
  Future<void> toggleFavorite(String productId) async {
    final ids = Set<String>.from(_currentIds);
    final wasFavorite = ids.contains(productId);

    if (wasFavorite) {
      ids.remove(productId);
    } else {
      ids.add(productId);
    }
    emit(FavoriteIdsLoaded(ids));

    try {
      final isFavoriteNow = await _repository.toggleFavorite(productId);
      final confirmedIds = Set<String>.from(_currentIds);
      if (isFavoriteNow) {
        confirmedIds.add(productId);
      } else {
        confirmedIds.remove(productId);
      }
      emit(FavoriteIdsLoaded(confirmedIds));
    } catch (_) {
      // Revert the optimistic change on failure.
      final revertedIds = Set<String>.from(_currentIds);
      if (wasFavorite) {
        revertedIds.add(productId);
      } else {
        revertedIds.remove(productId);
      }
      emit(FavoriteIdsLoaded(revertedIds));
    }
  }

  void removeLocally(String productId) {
    final ids = Set<String>.from(_currentIds)..remove(productId);
    emit(FavoriteIdsLoaded(ids));
  }
}
