import 'dart:io';

import 'package:eshop_plus/commons/widgets/checkInterconnectiviy.dart';
import 'package:eshop_plus/commons/widgets/error_screen.dart';
import 'package:eshop_plus/ui/home/categorySlider/blocs/categorySliderCubit.dart';

import 'package:eshop_plus/ui/home/offer/blocs/offerCubit.dart';
import 'package:eshop_plus/ui/home/mostSellingProduct/blocs/mostSellingProductCubit.dart';
import 'package:eshop_plus/commons/product/blocs/productsCubit.dart';
import 'package:eshop_plus/ui/home/featuredSection/blocs/featuredSectionCubit.dart';
import 'package:eshop_plus/ui/home/seller/blocs/bestSellerCubit.dart';
import 'package:eshop_plus/commons/blocs/settingsAndLanguagesCubit.dart';
import 'package:eshop_plus/ui/home/slider/blocs/sliderCubit.dart';
import 'package:eshop_plus/commons/blocs/userDetailsCubit.dart';
import 'package:eshop_plus/ui/home/seller/widgets/bestSellerSection.dart';
import 'package:eshop_plus/ui/home/brand/widgets/brandSection.dart';
import 'package:eshop_plus/ui/home/category/categorySection.dart';
import 'package:eshop_plus/ui/home/widgets/addDeliveryLocationWidget.dart';
import 'package:eshop_plus/ui/home/categorySlider/widgets/categorySliderSection.dart';
import 'package:eshop_plus/ui/home/featuredSection/widgets/featuredSectionContainer.dart';
import 'package:eshop_plus/ui/home/seller/widgets/featuredSellerSection.dart';
import 'package:eshop_plus/ui/home/mostSellingProduct/widgets/mostSellingProductSection.dart';
import 'package:eshop_plus/ui/home/offer/widgets/offerSection.dart';

import 'package:eshop_plus/core/localization/labelKeys.dart';
import 'package:eshop_plus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'brand/blocs/brandsCubit.dart';
import '../categoty/blocs/categoryCubit.dart';
import 'seller/blocs/featuredSellerCubit.dart';
import '../../commons/blocs/storesCubit.dart';
import 'widgets/homeAppBar.dart';
import 'slider/widgets/sliderSection.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _noInternet = false;
  @override
  void initState() {
    super.initState();

    checkForAppUpdate();
    getApiData();
  }

  checkForAppUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (context.read<SettingsAndLanguagesCubit>().state
          is SettingsAndLanguagesFetchSuccess) {
        if (context.read<SettingsAndLanguagesCubit>().isUpdateRequired()) {
          openUpdateDialog();
        }
      }
    });
  }

  getApiData() async {
    // First check if widget is still mounted before doing any work
    if (!mounted) return;

    _noInternet = await InternetConnectivity.isUserOffline();
    // Check again if widget is still mounted before proceeding with Future.delayed
    if (!mounted) return;

    Future.delayed(Duration.zero).then((value) async {
      // Check again if widget is still mounted before accessing context
      if (!mounted) return;

      int storeId = context.read<StoresCubit>().getDefaultStore().id!;
      // Check again if widget is still mounted before making API calls
      if (!mounted) return;

      context.read<CategoryCubit>().fetchCategories(storeId: storeId);
      context
          .read<CategorySliderCubit>()
          .getCategoriesSliders(storeId: storeId);
      context.read<OfferCubit>().getOfferSliders(storeId: storeId);
      context.read<SliderCubit>().getSliders(storeId: storeId);
      context
          .read<FeaturedSellerCubit>()
          .fetchFeaturedSellers(storeId: storeId);
      context.read<MostSellingProductsCubit>().getMostSellingProducts(
          storeId: storeId,
          userId: context.read<UserDetailsCubit>().getUserId());
      context.read<FeaturedSectionCubit>().getSections(storeId: storeId);
      context.read<BestSellersCubit>().getBestSellers(storeId: storeId);
      context.read<BrandsCubit>().getBrands(storeId: storeId);

      // Check if widget is still mounted before updating internet status and state
      if (!mounted) return;
      _noInternet = await InternetConnectivity.isUserOffline();

      // Final check before setState
      if (mounted) {
        setState(() {});
      }
    });
  }

  openUpdateDialog() {
    Utils.openAlertDialog(context, barrierDismissible: false, onTapNo: () {
      exit(0); // Forcefully close the app
    }, onTapYes: () {
      Utils.rateApp(context);
    },
        message: forceUpdateTitleKey,
        content: forceUpdateDescKey,
        noLabel: exitKey,
        yesLabel: updateKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HomeAppBar(setState: setState),
        body: _noInternet
            ? ErrorScreen(text: noInternetKey, onPressed: getApiData)
            : RefreshIndicator(
                triggerMode: RefreshIndicatorTriggerMode.anywhere,
                onRefresh: () async {
                  getApiData();
                },
                child: ListView(
                  children: <Widget>[
                    AddDeliveryLocationWidget(),
                    CategorySection(),
                    const SliderSection(),
                    const FeaturedSellerSection(),
                    BrandSection(),
                    const CategorySliderSection(),
                    const MostSellingProductSection(),
                    BlocProvider(
                      create: (context) => ProductsCubit(),
                      child: const OfferSection(),
                    ),
                    BlocProvider(
                      create: (context) => ProductsCubit(),
                      child: BestSellerSection(),
                    ),
                    const FeaturedSectionContainer(),
                  ],
                )));
  }
}
