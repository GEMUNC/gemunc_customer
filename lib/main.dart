import 'dart:async';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:eshop_plus/commons/blocs/deliveryLocationCubit.dart';
import 'package:eshop_plus/core/constants/hiveConstants.dart';
import 'package:eshop_plus/core/routes/routes.dart';
import 'package:eshop_plus/core/theme/appTheme.dart';
import 'package:eshop_plus/core/theme/colors.dart';
import 'package:eshop_plus/ui/profile/address/blocs/addNewAddressCubit.dart';
import 'package:eshop_plus/ui/profile/address/blocs/getAddressCubit.dart';
import 'package:eshop_plus/ui/auth/blocs/authCubit.dart';
import 'package:eshop_plus/ui/cart/blocs/getUserCart.dart';
import 'package:eshop_plus/ui/cart/blocs/manageCartCubit.dart';
import 'package:eshop_plus/ui/favorites/blocs/addFavoriteCubit.dart';
import 'package:eshop_plus/ui/favorites/blocs/getFavoriteCubit.dart';
import 'package:eshop_plus/ui/favorites/blocs/removeFavoriteCubit.dart';
import 'package:eshop_plus/ui/profile/orders/blocs/orderCubit.dart';
import 'package:eshop_plus/ui/profile/orders/blocs/updateOrderCubit.dart';
import 'package:eshop_plus/commons/blocs/storesCubit.dart';
import 'package:eshop_plus/commons/blocs/settingsAndLanguagesCubit.dart';
import 'package:eshop_plus/ui/profile/transaction/blocs/getPaymentMethodCubit.dart';
import 'package:eshop_plus/ui/profile/transaction/blocs/transactionCubit.dart';
import 'package:eshop_plus/ui/cart/models/cartItem.dart';

import 'package:eshop_plus/ui/auth/repositories/authRepository.dart';
import 'package:eshop_plus/commons/repositories/storeRepository.dart';
import 'package:eshop_plus/firebase_options.dart';
import 'package:eshop_plus/ui/profile/customerSupport/widgets/chatController.dart';
import 'package:eshop_plus/core/services/deepLinkManager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:hive_flutter/adapters.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ui/categoty/blocs/categoryCubit.dart';
import 'commons/blocs/userDetailsCubit.dart';

//////
// Version 1.0.10
/////

void main() async {
  await initializeApp();
}

late PackageInfo packageInfo;
final RouteController routeController = Get.put(RouteController());
final ChatController chatController = Get.put(ChatController());
String currentChatUserId = '';
String? lastSnackbarMessage = ''; // this is used to show snackbar only once
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late SharedPreferences sharedPreferences;

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  packageInfo = await PackageInfo.fromPlatform();

  //Register the licence of font
  //If using google-fonts
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: transparentColor,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: transparentColor));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Future.delayed(Duration.zero, () async {
    sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.reload();
  });
  await Hive.initFlutter();
  await Hive.openBox(authBoxKey);
  await Hive.openBox(settingsBoxKey);
  // Register the cart adapter
  Hive.registerAdapter(CartItemAdapter());
  await Hive.openBox<CartItem>(cartBoxKey);

  await Hive.openBox(productsBoxKey);

  await Hive.openBox(favoritesBoxKey);

  await Hive.openBox(promocodeBoxKey);

  await Hive.openBox(searchBoxKey);

  await Hive.openBox(affiliateReferencesBoxKey);

  await Hive.openBox(deliveryLocationBoxKey);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    if (mounted) {
      // Initialize deep link manager early
      DeepLinkManager().initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => StoresCubit(StoreRepository())),
        BlocProvider<AuthCubit>(create: (_) => AuthCubit(AuthRepository())),
        BlocProvider<UserDetailsCubit>(create: (_) => UserDetailsCubit()),
        BlocProvider<SettingsAndLanguagesCubit>(
            create: (_) => SettingsAndLanguagesCubit()),
        BlocProvider<GetUserCartCubit>(create: (_) => GetUserCartCubit()),
        BlocProvider(
          create: (context) => ManageCartCubit(),
        ),
        BlocProvider<RemoveFavoriteCubit>(
            create: (context) => RemoveFavoriteCubit()),
        BlocProvider(
          create: (context) => AddFavoriteCubit(),
        ),
        BlocProvider<CategoryCubit>(create: (context) => CategoryCubit()),
        BlocProvider(
          create: (context) => FavoritesCubit(),
        ),
        BlocProvider(
          create: (context) => GetAddressCubit(),
        ),
        BlocProvider(
          create: (context) => TransactionCubit(),
        ),
        // we have taken this cubit as global so that we can update order status from notification
        BlocProvider(
          create: (context) => OrdersCubit(),
        ),
        BlocProvider(
          create: (context) => UpdateOrderCubit(),
        ),
        BlocProvider<AddNewAddressCubit>(
            create: (context) => AddNewAddressCubit()),
        BlocProvider<DeliveryLocationCubit>(
            create: (context) => DeliveryLocationCubit()),
        BlocProvider(
          create: (context) => PaymentMethodCubit(),
        ),
      ],
      child: BlocBuilder<SettingsAndLanguagesCubit, SettingsAndLanguagesState>(
        builder: (context, state) {
          return BlocBuilder<StoresCubit, StoresState>(
            builder: (context, state) {
              final defaultStore =
                  context.read<StoresCubit>().getDefaultStore();

              return GetMaterialApp(

                navigatorKey: navigatorKey,
                textDirection: context
                        .read<SettingsAndLanguagesCubit>()
                        .getCurrentAppLanguage()
                        .isThisRTL()
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                theme: AppTheme.getThemeData(context, defaultStore),
                debugShowCheckedModeBanner: false,
                getPages: Routes.getPages,
                initialRoute: Routes.splashScreen,
                supportedLocales: [
                  const Locale('en'),  ],
                localizationsDelegates: [
                  CountryLocalizations.delegate,
                ],
                routingCallback: (routing) {
                  if (routing != null) {
                    routeController.updateCurrentRoute(
                        context, routing.current);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class RouteController extends GetxController {
  var currentRoute = ''.obs;

  @override
  void onInit() {
    ever(currentRoute, (route) {});
    super.onInit();
  }

  void updateCurrentRoute(BuildContext context, String route) {
    currentRoute.value = route;
  }
}
