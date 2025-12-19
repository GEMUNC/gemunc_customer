import 'package:eshop_plus/commons/blocs/deliveryLocationCubit.dart';
import 'package:eshop_plus/commons/product/models/product.dart';
import 'package:eshop_plus/core/constants/appAssets.dart';
import 'package:eshop_plus/core/constants/themeConstants.dart';
import 'package:eshop_plus/core/routes/routes.dart';
import 'package:eshop_plus/core/theme/colors.dart';
import 'package:eshop_plus/ui/cart/widgets/deliveryAddressWidget.dart';
import 'package:eshop_plus/ui/cart/blocs/checkCartProductDelCubit.dart';
import 'package:eshop_plus/ui/cart/blocs/getUserCart.dart';
import 'package:eshop_plus/ui/cart/blocs/manageCartCubit.dart';
import 'package:eshop_plus/ui/cart/blocs/removeProductFromCartCubit.dart';
import 'package:eshop_plus/ui/profile/promoCode/blocs/validatePromoCodeCubit.dart';
import 'package:eshop_plus/commons/blocs/settingsAndLanguagesCubit.dart';
import 'package:eshop_plus/commons/blocs/storesCubit.dart';
import 'package:eshop_plus/commons/blocs/userDetailsCubit.dart';
import 'package:eshop_plus/ui/cart/models/cart.dart';
import 'package:eshop_plus/ui/profile/promoCode/models/promoCode.dart';
import 'package:eshop_plus/ui/cart/widgets/cartProductList.dart';
import 'package:eshop_plus/ui/cart/widgets/priceDetailContainer.dart';

import 'package:eshop_plus/commons/widgets/customAppbar.dart';
import 'package:eshop_plus/commons/widgets/customCircularProgressIndicator.dart';
import 'package:eshop_plus/commons/widgets/customDefaultContainer.dart';
import 'package:eshop_plus/commons/widgets/customRoundedButton.dart';
import 'package:eshop_plus/commons/widgets/customTextContainer.dart';
import 'package:eshop_plus/commons/widgets/error_screen.dart';

import 'package:eshop_plus/core/api/apiEndPoints.dart';
import 'package:eshop_plus/utils/designConfig.dart';
import 'package:eshop_plus/core/localization/labelKeys.dart';
import 'package:eshop_plus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class CartScreen extends StatefulWidget {
  final bool shoulPop;
  final int? storeId;
  const CartScreen({Key? key, this.shoulPop = false, this.storeId})
      : super(key: key);
  static Widget getRouteInstance() => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => RemoveFromCartCubit(),
            ),
            BlocProvider(
              create: (context) => CheckCartProductDeliverabilityCubit(),
            ),
          ],
          child: CartScreen(
              shoulPop:
                  Get.arguments != null && Get.arguments.containsKey('shoulPop')
                      ? Get.arguments['shoulPop'] ?? true
                      : true,
              storeId:
                  Get.arguments != null && Get.arguments.containsKey('storeId')
                      ? Get.arguments['storeId'] as int?
                      : null));
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  GlobalKey _cartListKey = GlobalKey(), _priceDetailKey = GlobalKey();
  double? lastValidatedTotal;
  String? lastValidatedPromo;
  late int storeId;
  @override
  void initState() {
    super.initState();
    storeId =
        widget.storeId ?? context.read<StoresCubit>().getDefaultStore().id!;
    Future.delayed(Duration.zero, () {
      if (!context.read<UserDetailsCubit>().isGuestUser()) {
        // Refresh cart data in background without showing loading state
        getUserCart(true);
      }
    });
  }

  getUserCart(bool? refreshCartInBackground) {
    context.read<GetUserCartCubit>().fetchUserCart(
        refreshCartInBackground: refreshCartInBackground ?? false,
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
                  : ''
        });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ManageCartCubit, ManageCartState>(
      builder: (context, mstate) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IgnorePointer(
              ignoring: mstate is ManageCartFetchInProgress,
              child: BlocProvider(
                create: (context) => ValidatePromoCodeCubit(),
                child: Scaffold(
                    appBar: CustomAppbar(
                      titleKey: cartKey,
                      showBackButton: widget.shoulPop ? true : false,
                    ),
                    body: context.read<UserDetailsCubit>().isGuestUser()
                        ? ErrorScreen(
                            onPressed: () => Utils.navigateToScreen(
                                context, Routes.loginScreen,
                                arguments: Routes.cartScreen),
                            text: loginToAddToCartKey,
                            buttonText: loginKey,
                            image: AppAssets.emptyCart)
                        : BlocListener<GetUserCartCubit, GetUserCartState>(
                            listener: (context, state) {
                              //we will set the default or first address as selected address
                              if (state is GetUserCartFetchSuccess) {
                                // Check if promo code or total has changed
                                if (state.cart.promoCode != null &&
                                    (state.cart.subTotal !=
                                            lastValidatedTotal ||
                                        state.cart.promoCode!.promoCode !=
                                            lastValidatedPromo)) {
                                  // Update tracking values
                                  setState(() {
                                    lastValidatedTotal = state.cart.subTotal;
                                    lastValidatedPromo =
                                        state.cart.promoCode!.promoCode;
                                  });

                                  // Validate promo code
                                  context
                                      .read<ValidatePromoCodeCubit>()
                                      .validatePromoCode(params: {
                                    ApiURL.finalTotalApiKey:
                                        state.cart.subTotal,
                                    ApiURL.promoCodeApiKey:
                                        state.cart.promoCode!.promoCode,
                                  });
                                }

                                if (state.cart.outOfStockProducts != null &&
                                    state.cart.outOfStockProducts!.isNotEmpty) {
                                  state.cart.outOfStockProducts!.forEach((pr) {
                                    int index = state.cart.cartProducts!
                                        .indexWhere(
                                            (element) => element.id == pr.id);
                                    if (index != -1) {
                                      state.cart.cartProducts![index]
                                              .errorMessage =
                                          productIsCurrentlyOutOfStockKey;
                                    }
                                  });
                                }
                              }
                            },
                            child:
                                BlocListener<ManageCartCubit, ManageCartState>(
                              listener: (context, manageState) {
                                if (manageState is ManageCartFetchSuccess) {
                                  // if we are reloading cart, we need to get the user cart otherwise we will get the cart from the managecartstate
                                  if (manageState.reloadCart) {
                                    getUserCart(false);
                                  } else {
                                    if (context.read<GetUserCartCubit>().state
                                        is GetUserCartFetchSuccess) {
                                      GetUserCartFetchSuccess state = context
                                          .read<GetUserCartCubit>()
                                          .state as GetUserCartFetchSuccess;
                                      manageState.cart.promoCode =
                                          state.cart.promoCode;
                                      manageState.cart.couponDiscount =
                                          state.cart.couponDiscount;

                                      manageState.cart.saveForLaterProducts =
                                          state.cart.saveForLaterProducts;

                                      manageState.cart.deliveryInstruction =
                                          state.cart.deliveryInstruction;
                                      manageState.cart.selectedPaymentMethod =
                                          state.cart.selectedPaymentMethod;
                                      manageState.cart.useWalletBalance =
                                          state.cart.useWalletBalance;
                                      manageState.cart.walletAmount =
                                          state.cart.walletAmount;
                                      manageState.cart.emailAddress =
                                          state.cart.emailAddress;
                                      manageState.cart.attachments =
                                          state.cart.attachments;
                                    }
                                    context
                                        .read<GetUserCartCubit>()
                                        .emitSuccessState(manageState.cart);
                                    if (manageState.cart.promoCode != null) {
                                      context
                                          .read<ValidatePromoCodeCubit>()
                                          .validatePromoCode(params: {
                                        ApiURL.finalTotalApiKey:
                                            manageState.cart.subTotal,
                                        ApiURL.promoCodeApiKey: manageState
                                            .cart.promoCode!.promoCode
                                      });
                                    }
                                  }
                                  refreshState();
                                }
                              },
                              child: BlocBuilder<GetUserCartCubit,
                                  GetUserCartState>(
                                builder: (context, state) {
                                  if (state is GetUserCartFetchSuccess) {
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        MultiBlocListener(
                                          listeners: [
                                            BlocListener<RemoveFromCartCubit,
                                                    RemoveFromCartState>(
                                                listener:
                                                    (context, remvovestate) {
                                              if (remvovestate
                                                  is RemoveFromCartFetchSuccess) {
                                                //here when we remove from cart we need to refresh the state so that change price will be reflected
                                                refreshState();
                                              }
                                            }),
                                            BlocListener<ValidatePromoCodeCubit,
                                                    ValidatePromoCodeState>(
                                                listener: (context, state) {
                                              if (context
                                                      .read<GetUserCartCubit>()
                                                      .state
                                                  is GetUserCartFetchSuccess) {
                                                Cart cart = (context
                                                            .read<
                                                                GetUserCartCubit>()
                                                            .state
                                                        as GetUserCartFetchSuccess)
                                                    .cart;
                                                if (state
                                                    is ValidatePromoCodeFetchSuccess) {
                                                  //when promo code is applied we need to update the cart
                                                  if (cart.deliveryCharge !=
                                                      0) {
                                                    cart.overallAmount = state
                                                            .promoCode
                                                            .finalTotal! +
                                                        cart.deliveryCharge!;
                                                  } else {
                                                    cart.overallAmount = state
                                                        .promoCode.finalTotal!;
                                                  }

                                                  cart.couponDiscount = state
                                                      .promoCode.finalDiscount!;
                                                  cart.promoCode =
                                                      state.promoCode;

                                                  context
                                                      .read<GetUserCartCubit>()
                                                      .emitSuccessState(cart);
                                                  if (cart.useWalletBalance ==
                                                      true) {
                                                    context
                                                        .read<
                                                            GetUserCartCubit>()
                                                        .useWalletBalance(
                                                            true,
                                                            context
                                                                    .read<
                                                                        UserDetailsCubit>()
                                                                    .getuserDetails()
                                                                    .balance ??
                                                                0);
                                                  }
                                                }
                                                if (state
                                                    is ValidatePromoCodeFetchFailure) {
                                                  Utils.showSnackBar(
                                                      context: context,
                                                      message:
                                                          state.errorMessage);
                                                  cart.overallAmount =
                                                      state.finalTotal;
                                                  cart.promoCode = null;
                                                  cart.couponDiscount = 0;
                                                  context
                                                      .read<GetUserCartCubit>()
                                                      .emitSuccessState(cart);
                                                }
                                              }
                                            })
                                          ],
                                          child: (state.cart.cartProducts ==
                                                          null ||
                                                      (state.cart.cartProducts !=
                                                              null &&
                                                          state
                                                              .cart
                                                              .cartProducts!
                                                              .isEmpty)) &&
                                                  (state.cart.saveForLaterProducts ==
                                                          null ||
                                                      (state.cart.saveForLaterProducts !=
                                                              null &&
                                                          state
                                                              .cart
                                                              .saveForLaterProducts!
                                                              .isEmpty))
                                              ? ErrorScreen(
                                                  text: emptyCartkey,
                                                  image: AppAssets.emptyCart,
                                                  onPressed: () {},
                                                  child: null)
                                              : buildBodyContent(
                                                  state, context),
                                        ),
                                        buildPlaceOrderButton(state),
                                       
                                      ],
                                    );
                                  }
                                  if (state is GetUserCartFetchFailure) {
                                    return ErrorScreen(
                                        onPressed: () => getUserCart(false),
                                        text: state.errorMessage,
                                        image:
                                            state.errorMessage == noInternetKey
                                                ? AppAssets.noInternet
                                                : AppAssets.emptyCart,
                                        child: state
                                                is GetUserCartFetchInProgress
                                            ? CustomCircularProgressIndicator(
                                                indicatorColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                              )
                                            : null);
                                  }
                                  return CustomCircularProgressIndicator(
                                      indicatorColor: Theme.of(context)
                                          .colorScheme
                                          .primary);
                                },
                              ),
                            ),
                          )),
              ),
            ),
            if (mstate is ManageCartFetchInProgress) overlayProgressIndicator()
          ],
        );
      },
    );
  }

  overlayProgressIndicator() {
    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      color: blackColor.withValues(alpha: 0.5),
      alignment: Alignment.center,
      child: CustomCircularProgressIndicator(
        indicatorColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  refreshState() {
    _cartListKey = GlobalKey();
    _priceDetailKey = GlobalKey();
  }

  Widget buildBodyContent(GetUserCartFetchSuccess state, BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
          top: 12, bottom: MediaQuery.of(context).padding.bottom + 58),
      children: [
        CartProductList(
          key: _cartListKey,
          cart: state.cart,
          removeFromCartCubit: context.read<RemoveFromCartCubit>(),
        ),
        DesignConfig.smallHeightSizedBox,
        if ((state.cart.cartProducts != null &&
                state.cart.cartProducts!.isNotEmpty &&
                state.cart.cartProducts![0].type != digitalProductType) &&
            context.read<DeliveryLocationCubit>().currentSelectedAddress !=
                null)
          DeliveryAddressWidget(
            storeId: storeId,
            isFinalCartScreen: false,
          ),
        if (state.cart.cartProducts != null &&
            state.cart.cartProducts!.isNotEmpty)
          offerContainer(state.cart.promoCode),
        if (state.cart.cartProducts != null &&
            state.cart.cartProducts!.isNotEmpty)
          PriceDetailContainer(
            key: _priceDetailKey,
            cart: state.cart,
          ),
      ],
    );
  }

  offerContainer(PromoCode? promoCode) {
    return GestureDetector(
      onTap: () => Utils.navigateToScreen(context, Routes.promoCodeScreen,
          arguments: {'fromCartScreen': true}),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: CustomDefaultContainer(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: CustomTextContainer(
              textKey:
                  promoCode != null ? promoCode.promoCode! : addCouponCodeKey,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
            if (promoCode != null)
              IconButton(
                  visualDensity:
                      const VisualDensity(vertical: -4, horizontal: -4),
                  onPressed: () {
                    context.read<GetUserCartCubit>().removePromoCode();
                  },
                  icon: const Icon(
                    Icons.close,
                    size: 24,
                  ))
            else
              const Icon(Icons.arrow_forward_ios, size: 24)
          ],
        )),
      ),
    );
  }

  buildPlaceOrderButton(GetUserCartState state) {
    if (state is GetUserCartFetchSuccess &&
        state.cart.cartProducts != null &&
        state.cart.cartProducts!.isNotEmpty) {
      return BlocListener<CheckCartProductDeliverabilityCubit,
          CheckCartProductDeliverabilityState>(
        listener: (context, state) {
          if (state is CheckCartProductDeliverabilitySuccess) {
            context.read<GetUserCartCubit>().resetErrorMessages();
            Utils.navigateToScreen(context, Routes.placeOrderScreen,
                    arguments: {
                  'showAddressSelection': false,
                  'storeId': storeId,
                })!
                .then((value) {});
          }
          if (state is CheckCartProductDeliverabilityFailure) {
            if (state.errorData != null) {
              for (var item in state.errorData!) {
                if (item['is_deliverable'] == false) {
                  int productId = item['product_id'];
                  int? variantId = item['variant_id'];
                  String errorMessage =
                      '${item['name']} ${context.read<SettingsAndLanguagesCubit>().getTranslatedValue(labelKey: notDelierableErrorMessageKey)}';

                  // Find the corresponding CartProduct and assign the error message

                  context
                      .read<GetUserCartCubit>()
                      .setErrorMessage(productId, errorMessage, variantId: variantId);
                }
              }
            }

            Utils.showSnackBar(
                context: context,
                duration: const Duration(seconds: 7),
                backgroundColor: Theme.of(context).colorScheme.error,
                message: state.errorMessage);
          }
        },
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
              margin: EdgeInsetsDirectional.only(
                  start: appContentHorizontalPadding,
                  end: appContentHorizontalPadding,
                  top: 8,
                  bottom: MediaQuery.of(context).padding.bottom + 8),
              child: CustomRoundedButton(
                widthPercentage: 1,
                buttonTitle: proceedToCheckoutKey,
                showBorder: false,
                onTap: () {
                  if (state.cart.cartProducts != null &&
                      state.cart.cartProducts!.isNotEmpty &&
                      state.cart.outOfStockProducts != null &&
                      state.cart.outOfStockProducts!.isNotEmpty) {
                    Utils.showSnackBar(
                        context: context,
                        duration: const Duration(seconds: 7),
                        message: removeOutOfStockProductErrorMessageKey);
                    return;
                  }
                  if (state.cart.subTotal != null &&
                      state.cart.subTotal! <
                          double.parse(context
                              .read<SettingsAndLanguagesCubit>()
                              .getSettings()
                              .systemSettings!
                              .minimumCartAmount!
                              .toString())) {
                    Utils.showSnackBar(
                        context: context,
                        duration: const Duration(seconds: 7),
                        message:
                            '${context.read<SettingsAndLanguagesCubit>().getTranslatedValue(labelKey: minOrderAmountWarning1Key)}${Utils.priceWithCurrencySymbol(context: context, price: double.parse(context.read<SettingsAndLanguagesCubit>().getSettings().systemSettings!.minimumCartAmount.toString()))}. ${context.read<SettingsAndLanguagesCubit>().getTranslatedValue(labelKey: minOrderAmountWarning2Key)}');
                    return;
                  }
                  if (state.cart.cartProducts![0].type != digitalProductType &&
                      context
                              .read<DeliveryLocationCubit>()
                              .currentSelectedAddress !=
                          null)
                    context
                        .read<CheckCartProductDeliverabilityCubit>()
                        .checkDeliverability(
                            storeId: storeId,
                            addressId: context
                                .read<DeliveryLocationCubit>()
                                .currentSelectedAddress!
                                .id!);
                  else
                    Utils.navigateToScreen(context, Routes.placeOrderScreen,
                        arguments: {
                          'showAddressSelection': true,
                          'storeId': storeId,
                        });
                },
              )),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
