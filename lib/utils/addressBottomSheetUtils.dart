import 'package:eshop_plus/commons/blocs/userDetailsCubit.dart';
import 'package:eshop_plus/commons/widgets/customTextContainer.dart';
import 'package:eshop_plus/commons/widgets/customTextFieldContainer.dart';
import 'package:eshop_plus/commons/widgets/customTextButton.dart';
import 'package:eshop_plus/commons/widgets/filterContainerForBottomSheet.dart';
import 'package:eshop_plus/core/localization/labelKeys.dart';
import 'package:eshop_plus/core/routes/routes.dart';
import 'package:eshop_plus/core/theme/colors.dart';
import 'package:eshop_plus/ui/profile/address/blocs/getAddressCubit.dart';
import 'package:eshop_plus/ui/profile/address/models/address.dart';
import 'package:eshop_plus/utils/designConfig.dart';
import 'package:eshop_plus/utils/utils.dart';
import 'package:eshop_plus/utils/validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eshop_plus/commons/blocs/deliveryLocationCubit.dart';

class AddressBottomSheetUtils {
  static void showAddressBottomSheet(
    BuildContext context, {
    bool showManualPincodeEntry = true,
    required VoidCallback onAddressSelected,
  }) {
    Utils.openModalBottomSheet(
      context,
      staticContent: false,
      FilterContainerForBottomSheet(
        title: chooseDeliveryLocationKey,
        borderedButtonTitle: '',
        primaryButtonTitle: '',
        borderedButtonOnTap: () {},
        primaryButtonOnTap: () {},
        content: BlocBuilder<GetAddressCubit, GetAddressState>(
          builder: (context, state) {
            return _buildAddressList(
              context,
              state is GetAddressFetchSuccess ? state.addresses : [],
              onAddressSelected,
              showManualPincodeEntry,
            );
          },
        ),
      ),
    );
  }

  static Widget _buildAddressList(
    BuildContext context,
    List<Address> addresses,
    VoidCallback onAddressSelected,
    bool showManualPincodeEntry,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // Saved Addresses Section
          if (addresses.isNotEmpty) ...[
            CustomTextContainer(
              textKey: savedAddressesKey,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 16),
            ...addresses
                .map((address) =>
                    _buildAddressTile(context, address, onAddressSelected))
                .toList(),
          ],
          if(!context.read<UserDetailsCubit>().isGuestUser())
          _buildAddNewAddressTile(context),
          if (showManualPincodeEntry) ...[
            const SizedBox(height: 24),
            // Manual Pincode Entry
            _buildManualPincodeEntry(context, onAddressSelected),
          ]
        ],
      ),
    );
  }

  static Widget _buildAddressTile(
    BuildContext context,
    Address address,
    VoidCallback onAddressSelected,
  ) {
    return BlocBuilder<DeliveryLocationCubit, DeliveryLocationState>(
      builder: (context, state) {
        bool isSelected = false;
        if (state is DeliveryLocationLoaded && state.selectedAddress != null) {
          isSelected = state.selectedAddress!.id == address.id;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _selectAddress(context, address, onAddressSelected),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.08)
                    : Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3)
                      : Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.2),
                  width: isSelected ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                address.name ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (address.isDefault == 1) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: successStatusColor,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: CustomTextContainer(
                                  textKey: defaultKey,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: whiteColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 9,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${address.address ?? ''}, ${address.area ?? ''}, ${address.city ?? ''}, ${address.pincode ?? ''}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withValues(alpha: 0.7),
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildAddNewAddressTile(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: () => _addNewAddress(context),
        borderRadius: BorderRadius.circular(6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w500,
              size: 20,
            ),
            CustomTextContainer(
              textKey: addNewAddressKey,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildManualPincodeEntry(
    BuildContext context,
    VoidCallback onAddressSelected,
  ) {
    final TextEditingController zipcodeController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return BlocBuilder<DeliveryLocationCubit, DeliveryLocationState>(
      builder: (context, state) {
        // Only populate the text field if it's a pincode-only entry (not from address)
        if (state is DeliveryLocationLoaded &&
            state.isPincodeOnly &&
            state.zipcode != null &&
            zipcodeController.text.isEmpty) {
          zipcodeController.text = state.zipcode!;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextContainer(
              textKey: enterPincodeManuallyKey,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Row(
              children: [
                Expanded(
                  child: Form(
                    key: formKey,
                    child: CustomTextFieldContainer(
                      hintTextKey: typeDeliveryPincodeKey,
                      textEditingController: zipcodeController,
                      validator: (value) =>
                          Validator.emptyValueValidation(context, value),
                      prefixWidget: const Icon(Icons.location_on_outlined),
                      suffixWidget: IconButton(
                        onPressed: () {
                          zipcodeController.clear();
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ),
                  ),
                ),
                DesignConfig.smallWidthSizedBox,
                CustomTextButton(
                    buttonTextKey: applyKey,
                    textStyle: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(color: Theme.of(context).colorScheme.primary),
                    onTapButton: () {
                      _submitPincode(context, zipcodeController, formKey,
                          onAddressSelected);
                    })
              ],
            ),
          ],
        );
      },
    );
  }

  static void _selectAddress(
    BuildContext context,
    Address address,
    VoidCallback onAddressSelected,
  ) {
    if (address.pincode != null && address.pincode!.isNotEmpty) {
      context.read<DeliveryLocationCubit>().selectAddress(address);
      Navigator.pop(context);
      onAddressSelected();
    }
  }

  static void _addNewAddress(BuildContext context) {
    Navigator.pop(context);
    Utils.navigateToScreen(context, Routes.addNewAddressScreen, arguments: {
      'bloc': context.read<GetAddressCubit>(),
      'isEditScreen': false,
      'address': null,
    });
  }

  static void _submitPincode(
    BuildContext context,
    TextEditingController zipcodeController,
    GlobalKey<FormState> formKey,
    VoidCallback onAddressSelected,
  ) {
    if (formKey.currentState!.validate()) {
      final enteredPincode = zipcodeController.text.trim();
      context.read<DeliveryLocationCubit>().selectPincode(enteredPincode);
      Navigator.pop(context);
      onAddressSelected();
    } else {
      Utils.showSnackBar(
        message: emptyValueErrorMessageKey,
        context: context,
      );
    }
  }
}
