import 'package:eshop_plus/core/constants/appAssets.dart';
import 'package:eshop_plus/core/routes/routes.dart';
import 'package:eshop_plus/core/theme/colors.dart';
import 'package:eshop_plus/ui/auth/blocs/authCubit.dart';

import 'package:eshop_plus/commons/blocs/storesCubit.dart';
import 'package:eshop_plus/commons/blocs/settingsAndLanguagesCubit.dart';
import 'package:eshop_plus/commons/models/settings.dart';
import 'package:eshop_plus/commons/repositories/settingsRepository.dart';
import 'package:eshop_plus/commons/widgets/customCircularProgressIndicator.dart';
import 'package:eshop_plus/commons/widgets/error_screen.dart';
import 'package:eshop_plus/core/services/deepLinkManager.dart';

import 'package:eshop_plus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import '../commons/blocs/userDetailsCubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();

  static Widget getRouteInstance() => const SplashScreen();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    );
    _logoController.forward();

    // Ensure DeepLinkHandler is initialized early

    callApi();
  }

  @override
  void dispose() {
    _logoController.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: transparentColor,
      systemNavigationBarColor: transparentColor,
      systemNavigationBarDividerColor: transparentColor,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  void navigateToNextScreen() async {
    Settings settings = context.read<SettingsAndLanguagesCubit>().getSettings();

    // Initialize deep link manager early
    DeepLinkManager().initialize();

    // Don't mark app as ready here - wait for all steps to complete
    // DeepLinkManager().markAppAsReady(); // REMOVED - too early!

    // Check if there are pending deep links for cold start
    if (DeepLinkManager().hasInitialDeepLink) {
      // Navigate to main screen as guest user to process deep links
      context.read<AuthCubit>().unAuthenticateUser();
      Future.delayed(Duration.zero, () {
        Utils.navigateToScreen(context, Routes.mainScreen, replaceAll: true);
      });
      return;
    }

    if (context.read<AuthCubit>().state is Unauthenticated) {
      if (context.read<SettingsAndLanguagesCubit>().getshowOnBoardingScreen()) {
        ///[If there is no image or video added by admin then do not navigate to onborading screen]
        if ((settings.systemSettings?.showVideosInOnBoardingScreen() ??
            false)) {
          if ((settings.systemSettings?.onBoardingVideo?.isEmpty ?? false)) {
            navigateToLoginScreen(context);
          } else {
            Utils.navigateToScreen(context, Routes.onBoardingScreen,
                replaceAll: true);
          }
        } else {
          if ((settings.systemSettings?.onBoardingImage?.isEmpty ?? false)) {
            navigateToLoginScreen(context);
          } else {
            Utils.navigateToScreen(context, Routes.onBoardingScreen,
                replaceAll: true);
          }
        }
      } else {
        navigateToLoginScreen(context);
      }
    } else {
      Future.delayed(Duration(seconds: 2), () {
        Utils.navigateToScreen(context, Routes.mainScreen, replaceAll: true);
      });
    }
  }

  void _checkAndNavigate(
      SettingsAndLanguagesState settingsState, StoresState storeState) {
    if (!_hasNavigated &&
        settingsState is SettingsAndLanguagesFetchSuccess &&
        storeState is StoresFetchSuccess) {
      _hasNavigated = true;
      navigateToNextScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: primaryColor,
          systemNavigationBarColor: primaryColor,
          systemNavigationBarDividerColor: transparentColor,
        ),
        child: Scaffold(
            backgroundColor: primaryColor,
            body: BlocConsumer<StoresCubit, StoresState>(
                listener: (context, storestate) {
              final settingsState =
                  context.read<SettingsAndLanguagesCubit>().state;
              _checkAndNavigate(settingsState, storestate);
            }, builder: (context, storestate) {
              return BlocConsumer<SettingsAndLanguagesCubit,
                  SettingsAndLanguagesState>(listener: (context, state) {
                _checkAndNavigate(state, storestate);
              }, builder: (context, state) {
                if (state is SettingsAndLanguagesFetchFailure) {
                  return ErrorScreen(
                    text: state.errorMessage,
                    onPressed: () {
                      context
                          .read<SettingsAndLanguagesCubit>()
                          .fetchSettingsAndLanguages();
                      context.read<StoresCubit>().fetchStores();
                    },
                    child: state is SettingsAndLanguagesFetchInProgress
                        ? CustomCircularProgressIndicator(
                            indicatorColor:
                                Theme.of(context).colorScheme.onPrimary,
                          )
                        : null,
                  );
                }

                return Center(
                  child: AnimatedBuilder(
                    animation: _logoAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoAnimation.value,
                        child: Transform.scale(
                          scale: _logoAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: SvgPicture.asset(
                      AppAssets.appLogo,
                      width: 200,
                      height: 200,
                    ),
                  ),
                );
              });
            })));
  }

  void callApi() {
    Future.delayed(Duration.zero, () async {
      try {
        await context
            .read<SettingsAndLanguagesCubit>()
            .fetchSettingsAndLanguages();
        // Fetch stores
        await context.read<StoresCubit>().fetchStores();

        // Fetch settings

        // Check auth
        if (context.read<AuthCubit>().state is Authenticated) {
          context
              .read<UserDetailsCubit>()
              .fetchUserDetails(params: Utils.getParamsForVerifyUser(context));
        } else {
          context.read<UserDetailsCubit>().resetUserDetailsState();
        }

        // Mark app as ready after APIs are loaded
        DeepLinkManager().markAppAsReady();
      } catch (e) {
        // Even if there's an error, mark app as ready to avoid blocking
        DeepLinkManager().markAppAsReady();
      }
    });
  }

  static void navigateToLoginScreen(BuildContext context) {
    // DeepLinkHandler().init(context);
    //if guest user open app first time , it will redirect to login screen
    //if user is logged in and open app second time or further then it will redirect to main screen

    if (SettingsRepository().getFirstTimeUser()) {
      Utils.navigateToScreen(context, Routes.loginScreen, replaceAll: true);
    } else {
      context.read<AuthCubit>().unAuthenticateUser();
      Utils.navigateToScreen(context, Routes.mainScreen, replaceAll: true);
    }
  }
}
