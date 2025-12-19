import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:eshop_plus/core/constants/hiveConstants.dart';
import 'package:eshop_plus/ui/profile/address/models/address.dart';

// States
abstract class DeliveryLocationState {}

class DeliveryLocationInitial extends DeliveryLocationState {}

class DeliveryLocationLoaded extends DeliveryLocationState {
  final String? zipcode;
  final String? displayAddress;
  final Address? selectedAddress;
  final bool isPincodeOnly;

  DeliveryLocationLoaded({
    this.zipcode,
    this.displayAddress,
    this.selectedAddress,
    this.isPincodeOnly = false,
  });

  DeliveryLocationLoaded copyWith({
    String? zipcode,
    String? displayAddress,
    Address? selectedAddress,
    bool? isPincodeOnly,
  }) {
    return DeliveryLocationLoaded(
      zipcode: zipcode ?? this.zipcode,
      displayAddress: displayAddress ?? this.displayAddress,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      isPincodeOnly: isPincodeOnly ?? this.isPincodeOnly,
    );
  }
}

// Cubit
class DeliveryLocationCubit extends Cubit<DeliveryLocationState> {
  final Box deliveryBox = Hive.box(deliveryLocationBoxKey);

  DeliveryLocationCubit() : super(DeliveryLocationInitial()) {
    _loadStoredDeliveryLocation();
  }

  void _loadStoredDeliveryLocation() {
    // Check for stored address first (higher priority)
    final storedAddressData = deliveryBox.get(selectedAddressKey);
    if (storedAddressData != null) {
      final addressMap = Map<String, dynamic>.from(storedAddressData);
      final storedAddress = Address.fromJson(addressMap);
      if (storedAddress.pincode != null && storedAddress.pincode!.isNotEmpty) {
        emit(DeliveryLocationLoaded(
          zipcode: storedAddress.pincode,
          displayAddress:
              '${storedAddress.name}, ${storedAddress.city}, ${storedAddress.pincode}',
          selectedAddress: storedAddress,
          isPincodeOnly: false,
        ));
        return;
      }
    }

    // If no address, check for stored pincode
    final storedPincode = deliveryBox.get(selectedPincodeKey);
    if (storedPincode != null && storedPincode.toString().isNotEmpty) {
      emit(DeliveryLocationLoaded(
        zipcode: storedPincode.toString(),
        displayAddress: storedPincode.toString(),
        selectedAddress: null,
        isPincodeOnly: true,
      ));
    } else {
      emit(DeliveryLocationLoaded());
    }
  }

  void selectAddress(Address address) {
    if (address.pincode != null && address.pincode!.isNotEmpty) {
      // Clear any existing pincode data since we're storing address
      deliveryBox.delete(selectedPincodeKey);

      // Convert address to map for storage
      final addressMap = {
        'id': address.id,
        'name': address.name,
        'address': address.address,
        'area': address.area,
        'city': address.city,
        'pincode': address.pincode,
        'state': address.state,
        'country': address.country,
        'isDefault': address.isDefault,
        'mobile': address.mobile,
      };

      deliveryBox.put(selectedAddressKey, addressMap);

      emit(DeliveryLocationLoaded(
        zipcode: address.pincode,
        displayAddress: '${address.name}, ${address.city}, ${address.pincode}',
        selectedAddress: address,
        isPincodeOnly: false,
      ));
    }
  }

  void selectPincode(String pincode) {
    // Clear any existing address data since we're storing pincode only
    deliveryBox.delete(selectedAddressKey);

    // Store the pincode
    deliveryBox.put(selectedPincodeKey, pincode);

    emit(DeliveryLocationLoaded(
      zipcode: pincode,
      displayAddress: pincode,
      selectedAddress: null,
      isPincodeOnly: true,
    ));
  }

  void loadDefaultAddress(BuildContext context, List<Address> addresses) {
    final currentState = state;

    // Only load default if no current location is set
    if (currentState is! DeliveryLocationLoaded ||
        (currentState.zipcode == null && currentState.displayAddress == null)) {
      final defaultAddress = addresses.firstWhere(
        (address) => address.isDefault == 1,
        orElse: () => addresses.isNotEmpty ? addresses.first : Address(),
      );

      if (defaultAddress.pincode != null &&
          defaultAddress.pincode!.isNotEmpty) {
        selectAddress(defaultAddress);
      }
    }
  }

  void clearDeliveryLocation() {
    deliveryBox.delete(selectedAddressKey);
    deliveryBox.delete(selectedPincodeKey);
    emit(DeliveryLocationLoaded());
  }

  void resetToInitialState() {
    emit(DeliveryLocationInitial());
  }

  // Getters for easy access
  String? get currentZipcode {
    final currentState = state;
    if (currentState is DeliveryLocationLoaded) {
      return currentState.zipcode;
    }
    return null;
  }

  String? get currentDisplayAddress {
    final currentState = state;
    if (currentState is DeliveryLocationLoaded) {
      return currentState.displayAddress;
    }
    return null;
  }

  Address? get currentSelectedAddress {
    final currentState = state;
    if (currentState is DeliveryLocationLoaded) {
      return currentState.selectedAddress;
    }
    return null;
  }

  bool get isPincodeOnly {
    final currentState = state;
    if (currentState is DeliveryLocationLoaded) {
      return currentState.isPincodeOnly;
    }
    return false;
  }
}
