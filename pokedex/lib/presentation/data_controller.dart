import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:pokedex/domain/pokemon_entity.dart';
import 'package:pokedex/domain/repository_base.dart';

class UIState<T> implements EquatableMixin {
  UIState({
    required this.data,
    this.error,
    this.loading = true,
    this.empty = false,
  });

  final T data;
  final String? error;
  final bool loading;
  final bool empty;

  UIState<T> loadingState({required bool isLoading}) =>
      copyWith(loading: isLoading, empty: false);

  UIState<T> errorState(String error) =>
      copyWith(loading: false, error: error, empty: false);

  UIState<T> successState(T data, {bool? empty}) =>
      copyWith(loading: false, data: data, empty: empty ?? false);

  UIState<T> copyWith({
    T? data,
    String? error,
    bool? loading,
    bool? empty,
  }) {
    return UIState(
      data: data ?? this.data,
      error: error ?? this.error,
      loading: loading ?? this.loading,
      empty: empty ?? this.empty,
    );
  }

  @override
  List<Object?> get props => [data, error, loading, empty];

  @override
  bool? get stringify => true;
}

abstract class BaseDataController<T> extends ChangeNotifier {
  BaseDataController({required T data}) : _data = data;

  final T _data;

  late UIState<T> _state = UIState<T>(data: _data);

  set state(UIState<T> newState) {
    if (newState == _state) return;

    _state = newState;

    notifyListeners();
  }

  UIState<T> get state => _state;

  int _nextPage = 1;

  @visibleForTesting
  set nextPage(int nextPage) {
    _nextPage = nextPage;
  }

  @visibleForTesting
  int get nextPage => _nextPage;

  bool get fetchingNext => state.loading && _nextPage > 1;

  void fetch();
}

class PokemonDataController extends BaseDataController<PokemonList> {
  PokemonDataController({required RepositoryBase repository})
      : _repository = repository,
        super(data: []);

  final RepositoryBase _repository;

  @override
  void fetch() async {
    state = _state.loadingState(isLoading: true);

    final result =
        await _repository.fetchPokemons(offset: pageOffset, limit: _pageLimit);

    result.fold(
      (left) => state = _state.errorState(left),
      (right) {
        final newList = List<PokemonEntity>.from(state.data).toList()
          ..addAll(right);

        if (right.isNotEmpty) {
          nextPage++;
        }

        state = _state.successState(
          newList,
          empty: newList.isEmpty,
        );
      },
    );
  }

  @visibleForTesting
  int get pageOffset {
    return (nextPage + _pageLimit) - 1;
  }

  int get _pageLimit => 20;
}

class FavoritePokenDataController extends BaseDataController<PokemonList> {
  FavoritePokenDataController({required RepositoryBase repository})
      : _repository = repository,
        super(data: []);

  final RepositoryBase _repository;

  @override
  void fetch() async {
    state = _state.loadingState(isLoading: true);

    final result = await _repository.fetchFavouritePokemons();

    result.fold(
      (left) => state = _state.errorState(left),
      (right) => state = _state.successState(right, empty: right.isEmpty),
    );
  }
}
