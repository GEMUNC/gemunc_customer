import 'package:eshop_plus/commons/blocs/deliveryLocationCubit.dart';
import 'package:eshop_plus/commons/blocs/userDetailsCubit.dart';
import 'package:eshop_plus/core/api/apiEndPoints.dart';
import 'package:eshop_plus/core/constants/themeConstants.dart';
import 'package:eshop_plus/core/localization/labelKeys.dart';
import 'package:eshop_plus/ui/cart/blocs/getUserCart.dart';

import 'package:eshop_plus/ui/profile/address/models/address.dart';
import 'package:eshop_plus/commons/widgets/customTextButton.dart';
import 'package:eshop_plus/commons/widgets/customTextFieldContainer.dart';
import 'package:eshop_plus/commons/widgets/filterContainerForBottomSheet.dart';
import 'package:eshop_plus/utils/addressBottomSheetUtils.dart';
import 'package:eshop_plus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeliveryAddressWidget extends StatelessWidget {
  final int storeId;
  final bool isFinalCartScreen;
  const DeliveryAddressWidget(
      {Key? key, required this.storeId, required this.isFinalCartScreen})
      : super(key: key);
  //

  @override
  Widget build(BuildContext context) {
    Address address =
        context.read<DeliveryLocationCubit>().currentSelectedAddress ??
            Address();
    return Utils.commonContainer(
        context,
        deliveryAddressKey,
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
              horizontal: appContentHorizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Utils.getAddressWidget(context, address),
              if (isFinalCartScreen)
                Padding(
                  padding: EdgeInsetsDirectional.only(top: 16, bottom: 4),
                  child: CustomTextButton(
                      buttonTextKey: addDeliveryInstructionKey,
                      textStyle: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(
                              color: Theme.of(context).colorScheme.primary),
                      onTapButton: () {
                        TextEditingController instructionController =
                            TextEditingController(
                                text: context
                                    .read<GetUserCartCubit>()
                                    .getCartDetail()
                                    .deliveryInstruction);
                        Utils.openModalBottomSheet(
                            context,
                            FilterContainerForBottomSheet(
                              title: addDeliveryInstructionKey,
                              borderedButtonTitle: '',
                              primaryButtonTitle: submitKey,
                              borderedButtonOnTap: () {},
                              primaryButtonOnTap: () {
                                if (instructionController.text.isNotEmpty) {
                                  context
                                      .read<GetUserCartCubit>()
                                      .addDeliveryInstruction(
                                          instructionController.text);
                                  Navigator.of(context).pop();
                                }
                              },
                              content: CustomTextFieldContainer(
                                hintTextKey: typeKey,
                                textEditingController: instructionController,
                                maxLines: 5,
                              ),
                            ),
                            staticContent: true,
                            isScrollControlled: true);
                      }),
                )
            ],
          ),
        ),
        prefixIcon: const Icon(
          Icons.location_on_outlined,
        ),
        suffixIcon: CustomTextButton(
          onTapButton: () => onTapChangeAddress(context),
          buttonTextKey: changekey,
          textStyle: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(color: Theme.of(context).colorScheme.primary),
        ));
  }

  onTapChangeAddress(BuildContext context) {
    AddressBottomSheetUtils.showAddressBottomSheet(
      context,
      showManualPincodeEntry: false,
      onAddressSelected: () {
        context.read<GetUserCartCubit>().updateCart(
          context: context,
          oldCart: context.read<GetUserCartCubit>().getCartDetail(),
          checkDeliverability: isFinalCartScreen,
          params: {
            ApiURL.storeIdApiKey: storeId,
            ApiURL.onlyDeliveryChargeApiKey: 0,
            ApiURL.userIdApiKey: context.read<UserDetailsCubit>().getUserId(),
            ApiURL.addressIdApiKey:
                context.read<DeliveryLocationCubit>().currentSelectedAddress !=
                        null
                    ? context
                        .read<DeliveryLocationCubit>()
                        .currentSelectedAddress!
                        .id!
                    : '',
          },
        );
        context.read<GetUserCartCubit>().resetErrorMessages();
      },
    );
  }
}
