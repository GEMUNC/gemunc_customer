import 'package:eshop_plus/ui/profile/address/repositories/addressRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/city.dart';

abstract class CityState {}

class CityInitial extends CityState {}

class CityFetchInProgress extends CityState {}

class CityFetchSuccess extends CityState {
  final int total;
  final List<City> cities;
  final bool fetchMoreError;
  final bool fetchMoreInProgress;

  CityFetchSuccess({
    required this.cities,
    required this.fetchMoreError,
    required this.fetchMoreInProgress,
    required this.total,
  });

  CityFetchSuccess copyWith({
    bool? fetchMoreError,
    bool? fetchMoreInProgress,
    int? total,
    List<City>? cities,
  }) {
    return CityFetchSuccess(
      cities: cities ?? this.cities,
      fetchMoreError: fetchMoreError ?? this.fetchMoreError,
      fetchMoreInProgress: fetchMoreInProgress ?? this.fetchMoreInProgress,
      total: total ?? this.total,
    );
  }
}

class CityFetchFailure extends CityState {
  final String errorMessage;

  CityFetchFailure(this.errorMessage);
}

class CityCubit extends Cubit<CityState> {
  final AddressRepository _addressRepository = AddressRepository();

  int _offset = 0;
  String _search = '';


  CityCubit() : super(CityInitial());

  void getCities({String search = ''}) async {
    emit(CityFetchInProgress());
    _offset = 0;
    _search = search;

    try {
      final result = await _addressRepository.getCities(
        search: _search,
        offset: _offset,
      );

      emit(CityFetchSuccess(
        cities: result.citylist,
        fetchMoreError: false,
        fetchMoreInProgress: false,
        total: result.total,
      ));
    } catch (e) {
      emit(CityFetchFailure(e.toString()));
    }
  }

  Future<void> loadMore() async {
    if (state is CityFetchSuccess) {
      final currentState = state as CityFetchSuccess;

      // already loading or all loaded → skip
      if (currentState.fetchMoreInProgress ||
          currentState.cities.length >= currentState.total) {
        return;
      }

      emit(currentState.copyWith(fetchMoreInProgress: true));

      try {
        _offset = currentState.cities.length; // next batch offset
        final result = await _addressRepository.getCities(
          search: _search,
          offset: _offset,
        );

        emit(currentState.copyWith(
          cities: [...currentState.cities, ...result.citylist],
          fetchMoreInProgress: false,
          total: result.total,
        ));
      } catch (e) {
        emit(currentState.copyWith(
          fetchMoreInProgress: false,
          fetchMoreError: true,
        ));
      }
    }
  }

  List<City> getCityList() {
    if (state is CityFetchSuccess) {
      return (state as CityFetchSuccess).cities;
    }
    return [];
  }

  bool fetchMoreError() {
    if (state is CityFetchSuccess) {
      return (state as CityFetchSuccess).fetchMoreError;
    }
    return false;
  }

  bool hasMore() {
    if (state is CityFetchSuccess) {
      final s = state as CityFetchSuccess;
      return s.cities.length < s.total;
    }
    return false;
  }
}
