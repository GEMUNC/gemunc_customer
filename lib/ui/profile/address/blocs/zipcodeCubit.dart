import 'package:eshop_plus/ui/profile/address/repositories/addressRepository.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/zipcode.dart';

abstract class ZipcodeState {}

class ZipcodeInitial extends ZipcodeState {}

class ZipcodeFetchInProgress extends ZipcodeState {}

class ZipcodeFetchSuccess extends ZipcodeState {
  final int total;
  final List<Zipcode> zipcodes;
  final bool fetchMoreError;
  final bool fetchMoreInProgress;

  ZipcodeFetchSuccess({
    required this.zipcodes,
    required this.fetchMoreError,
    required this.fetchMoreInProgress,
    required this.total,
  });

  ZipcodeFetchSuccess copyWith({
    bool? fetchMoreError,
    bool? fetchMoreInProgress,
    int? total,
    List<Zipcode>? zipcodes,
  }) {
    return ZipcodeFetchSuccess(
      zipcodes: zipcodes ?? this.zipcodes,
      fetchMoreError: fetchMoreError ?? this.fetchMoreError,
      fetchMoreInProgress: fetchMoreInProgress ?? this.fetchMoreInProgress,
      total: total ?? this.total,
    );
  }
}

class ZipcodeFetchFailure extends ZipcodeState {
  final String errorMessage;

  ZipcodeFetchFailure(this.errorMessage);
}

class ZipcodeCubit extends Cubit<ZipcodeState> {
  final AddressRepository _addressRepository = AddressRepository();

  int _offset = 0;
  String _search = '';
  int? _cityId;


  ZipcodeCubit() : super(ZipcodeInitial());

  void getZipcodes({int? cityId, String search = ''}) async {
    emit(ZipcodeFetchInProgress());
    _offset = 0;
    _search = search;
    _cityId = cityId;

    try {
      final result = await _addressRepository.getZipcodes(
        cityId: _cityId,
        search: _search,
        offset: _offset,
      );

      emit(ZipcodeFetchSuccess(
        zipcodes: result.zipcodes,
        fetchMoreError: false,
        fetchMoreInProgress: false,
        total: result.total,
      ));
    } catch (e) {
      emit(ZipcodeFetchFailure(e.toString()));
    }
  }

  Future<void> loadMore() async {
    if (state is ZipcodeFetchSuccess) {
      final currentState = state as ZipcodeFetchSuccess;

      if (currentState.fetchMoreInProgress ||
          currentState.zipcodes.length >= currentState.total) {
        return;
      }

      emit(currentState.copyWith(fetchMoreInProgress: true));

      try {
        _offset = currentState.zipcodes.length;

        final result = await _addressRepository.getZipcodes(
          cityId: _cityId,
          search: _search,
          offset: _offset,
        );

        emit(currentState.copyWith(
          zipcodes: [...currentState.zipcodes, ...result.zipcodes],
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

  List<Zipcode> getZipcodeList() {
    if (state is ZipcodeFetchSuccess) {
      return (state as ZipcodeFetchSuccess).zipcodes;
    }
    return [];
  }

  bool fetchMoreError() {
    if (state is ZipcodeFetchSuccess) {
      return (state as ZipcodeFetchSuccess).fetchMoreError;
    }
    return false;
  }

  bool hasMore() {
    if (state is ZipcodeFetchSuccess) {
      final s = state as ZipcodeFetchSuccess;
      return s.zipcodes.length < s.total;
    }
    return false;
  }
}
