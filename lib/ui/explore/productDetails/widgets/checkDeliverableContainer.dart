import 'package:eshop_plus/core/constants/appConstants.dart';
import 'package:eshop_plus/core/theme/colors.dart';
import 'package:eshop_plus/ui/explore/blocs/checkProductDeliverabilityCubit.dart';
import 'package:eshop_plus/commons/product/models/product.dart';
import 'package:eshop_plus/commons/widgets/customCircularProgressIndicator.dart';
import 'package:eshop_plus/commons/widgets/customDefaultContainer.dart';
import 'package:eshop_plus/commons/widgets/customTextContainer.dart';

import 'package:eshop_plus/core/api/apiEndPoints.dart';
import 'package:eshop_plus/utils/designConfig.dart';
import 'package:eshop_plus/core/localization/labelKeys.dart';
import 'package:eshop_plus/core/localization/defaultLanguageTranslatedValues.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eshop_plus/utils/addressBottomSheetUtils.dart';
import 'package:eshop_plus/commons/blocs/deliveryLocationCubit.dart';

class CheckDeliverableContainer extends StatefulWidget {
  final Product product;
  const CheckDeliverableContainer({Key? key, required this.product})
      : super(key: key);

  @override
  _CheckDeliverableContainerState createState() =>
      _CheckDeliverableContainerState();
}

class _CheckDeliverableContainerState extends State<CheckDeliverableContainer> {
  bool _hasCheckedInitially = false;
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadStoredDeliveryLocation();
  }

  void _loadStoredDeliveryLocation() {
    final deliveryLocationCubit = context.read<DeliveryLocationCubit>();
    final currentState = deliveryLocationCubit.state;

    if (currentState is DeliveryLocationLoaded &&
        currentState.zipcode != null) {
      _checkDeliverabilityAutomatically();
    }
  }

  void _checkDeliverabilityAutomatically() {
    final deliveryLocationCubit = context.read<DeliveryLocationCubit>();
    final currentZipcode = deliveryLocationCubit.currentZipcode;

    if (currentZipcode != null && !_hasCheckedInitially) {
      _hasCheckedInitially = true;
      Future.delayed(Duration(milliseconds: 500), () {
        _performDeliverabilityCheck();
      });
    }
  }

  void _performDeliverabilityCheck() {
    final deliveryLocationCubit = context.read<DeliveryLocationCubit>();
    final currentZipcode = deliveryLocationCubit.currentZipcode;

    if (currentZipcode == null) return;

    final productDeliverabilityCubit =
        context.read<CheckProductDeliverabilityCubit>();
    // final isZipcodeCheck = context
    //         .read<StoresCubit>()
    //         .getDefaultStore()
    //         .productDeliverabilityType !=
    //     'city_wise_deliverability';

    // if (isZipcodeCheck) {
    productDeliverabilityCubit.checkProductDeliverability(
      productParams: {
        ApiURL.storeIdApiKey: widget.product.storeId,
        ApiURL.productIdApiKey: widget.product.id,
        ApiURL.productTypeApiKey:
            widget.product.type == comboProductType ? comboType : regularType,
        ApiURL.zipCodeApiKey: currentZipcode,
      },
      sellerParams: {
        ApiURL.storeIdApiKey: widget.product.storeId,
        ApiURL.sellerIdApiKey: widget.product.sellerId,
        ApiURL.zipCodeApiKey: currentZipcode,
      },
    );
    // } else {
    //   productDeliverabilityCubit.checkProductDeliverability(
    //     productParams: {
    //       ApiURL.storeIdApiKey: widget.product.storeId,
    //       ApiURL.productIdApiKey: widget.product.id,
    //       ApiURL.productTypeApiKey:
    //           widget.product.type == comboProductType ? comboType : regularType,
    //       ApiURL.cityApiKey: currentAddress,
    //     },
    //     sellerParams: {
    //       ApiURL.storeIdApiKey: widget.product.storeId,
    //       ApiURL.sellerIdApiKey: widget.product.sellerId,
    //       ApiURL.cityApiKey: currentAddress,
    //     },
    //   );
    // }
  }

  void _changeLocation() {
    AddressBottomSheetUtils.showAddressBottomSheet(
      context,
      onAddressSelected: () {
        _performDeliverabilityCheck();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckProductDeliverabilityCubit,
        CheckProductDeliverabilityState>(
      listener: (context, state) {
        // Don't show snackbar messages as we'll show them in the UI
      },
      builder: (context, state) {
        return CustomDefaultContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomTextContainer(
                    textKey: checkProductDeliverabilityKey,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (state is CheckProductDeliverabilityFetchInProgress)
                    CustomCircularProgressIndicator(
                      indicatorColor: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
              DesignConfig.defaultHeightSizedBox,
              BlocBuilder<DeliveryLocationCubit, DeliveryLocationState>(
                builder: (context, deliveryState) {
                  if (deliveryState is DeliveryLocationLoaded &&
                      deliveryState.displayAddress != null) {
                    return Column(
                        children: _buildDeliveryStatusSection(
                            context, state, deliveryState.displayAddress!));
                  } else {
                    return Column(
                      children: _buildNoLocationSection(context),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildDeliveryStatusSection(BuildContext context,
      CheckProductDeliverabilityState state, String displayAddress) {
    return [
      // Delivery status message
      if (state is CheckProductDeliverabilityFetchSuccess)
        ..._buildSuccessMessage(context, state.successMessage, displayAddress),
      if (state is CheckProductDeliverabilityFetchFailure)
        ..._buildErrorMessage(context, state.errorMessage, displayAddress),
    ];
  }

  List<Widget> _buildSuccessMessage(
      BuildContext context, String message, String displayAddress) {
    return [
      GestureDetector(
        onTap: _changeLocation,
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: successStatusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: successStatusColor,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.get(context, deliverableAtKey,
                      placeholders: {'address': displayAddress}),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: successStatusColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildErrorMessage(
      BuildContext context, String message, String displayAddress) {
    return [
      GestureDetector(
        onTap: _changeLocation,
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: errorColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error,
                color: errorColor,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.get(context, notDeliverableAtKey,
                      placeholders: {'address': displayAddress}),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: errorColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildNoLocationSection(BuildContext context) {
    return [
      GestureDetector(
        onTap: _changeLocation,
        child: Container(
          padding: EdgeInsets.all(2),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_off,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              SizedBox(width: 8),
              Text(
                AppLocalizations.get(
                  context,
                  pleaseSetDeliveryLocationFirstKey,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ];
  }
}
