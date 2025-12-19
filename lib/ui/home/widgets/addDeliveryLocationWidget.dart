import 'package:eshop_plus/commons/blocs/deliveryLocationCubit.dart';
import 'package:eshop_plus/commons/blocs/settingsAndLanguagesCubit.dart';
import 'package:eshop_plus/core/constants/themeConstants.dart';
import 'package:eshop_plus/core/theme/colors.dart';
import 'package:eshop_plus/ui/auth/blocs/authCubit.dart';
import 'package:flutter/material.dart';

import 'package:eshop_plus/commons/widgets/customTextContainer.dart';
import 'package:eshop_plus/core/localization/labelKeys.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eshop_plus/ui/profile/address/blocs/getAddressCubit.dart';
import 'package:eshop_plus/utils/addressBottomSheetUtils.dart';

class AddDeliveryLocationWidget extends StatefulWidget {
  const AddDeliveryLocationWidget({Key? key}) : super(key: key);

  @override
  _AddDeliveryLocationWidgetState createState() =>
      _AddDeliveryLocationWidgetState();
}

class _AddDeliveryLocationWidgetState extends State<AddDeliveryLocationWidget> {
  @override
  void initState() {
    super.initState();
    // Load default address on app start
    Future.delayed(Duration.zero, () {
      _loadDefaultAddress();
    });
  }

  void _loadDefaultAddress({bool refreshProducts = true}) {
    final deliveryLocationCubit = context.read<DeliveryLocationCubit>();
    final currentState = deliveryLocationCubit.state;

    // Only load default if no current location is set
    if (currentState is! DeliveryLocationLoaded ||
        (currentState.zipcode == null && currentState.displayAddress == null)) {
      final addressCubit = context.read<GetAddressCubit>();
      if (addressCubit.state is GetAddressFetchSuccess) {
        final addresses =
            (addressCubit.state as GetAddressFetchSuccess).addresses;
        deliveryLocationCubit.loadDefaultAddress(context, addresses);
      } else  {
        // Fetch addresses if not already loaded
        addressCubit.getAddress();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GetAddressCubit, GetAddressState>(
          listener: (context, state) {
            if (state is GetAddressFetchSuccess) {
              // Update zipcode when addresses are loaded or changed
              _loadDefaultAddress();
            }
          },
        ),
        BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              // When user logs in, fetch their addresses
              Future.delayed(Duration.zero, () {
                context.read<GetAddressCubit>().getAddress();
              });
            }
          },
        ),
        BlocListener<DeliveryLocationCubit, DeliveryLocationState>(
          listener: (context, state) {
            if (state is DeliveryLocationInitial) {
              // When delivery location is reset, reload addresses if user is authenticated
              final authState = context.read<AuthCubit>().state;
              if (authState is Authenticated) {
                Future.delayed(Duration.zero, () {
                  context.read<GetAddressCubit>().getAddress();
                });
              }
            }
          },
        ),
      ],
      child: BlocConsumer<DeliveryLocationCubit, DeliveryLocationState>(
        listener: (context, state) {},
        builder: (context, deliveryState) {
          String displayText = addDeliveryLocKey;

          if (deliveryState is DeliveryLocationLoaded &&
              deliveryState.displayAddress != null) {
            displayText =
                '${context.read<SettingsAndLanguagesCubit>().getTranslatedValue(labelKey: deliverToKey)} ${deliveryState.displayAddress}';
          }

          return GestureDetector(
            onTap: () => _showAddressBottomSheet(context),
            child: Container(
              padding:
                  const EdgeInsetsDirectional.all(appContentHorizontalPadding),
              decoration: BoxDecoration(
                border: Border.all(color: transparentColor),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.location_on_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomTextContainer(
                      textKey: displayText,
                      style: Theme.of(context).textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_double_arrow_right)
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddressBottomSheet(BuildContext context) {
    _loadDefaultAddress(refreshProducts: true);
    AddressBottomSheetUtils.showAddressBottomSheet(
      context,
      onAddressSelected: () {
        // No need to manually reload - cubit will handle state updates
      },
    );
  }

  // updateProducts() {
  //   mainScreenKey?.currentState!.refreshProducts(onlyExplore: true);
  //   context.read<FeaturedSectionCubit>().getSections(
  //       storeId: context.read<StoresCubit>().getDefaultStore().id!,
  //       zipcode: _zipcodeController.text.trim());
  //   context.read<MostSellingProductsCubit>().getMostSellingProducts(
  //       storeId: context.read<StoresCubit>().getDefaultStore().id!,
  //       userId: context.read<UserDetailsCubit>().getUserId(),
  //       zipcode: _zipcodeController.text.trim());
  // }
}
