import 'dart:io';

import 'package:eshop_plus/core/configs/appConfig.dart';
import 'package:eshop_plus/core/constants/appAssets.dart';
import 'package:eshop_plus/core/routes/routes.dart';
import 'package:eshop_plus/ui/auth/blocs/authCubit.dart';
import 'package:eshop_plus/ui/auth/blocs/signUpCubit.dart';
import 'package:eshop_plus/commons/blocs/settingsAndLanguagesCubit.dart';

import 'package:eshop_plus/commons/blocs/userDetailsCubit.dart';
import 'package:eshop_plus/commons/widgets/customCircularProgressIndicator.dart';
import 'package:eshop_plus/commons/widgets/customRoundedButton.dart';

import 'package:eshop_plus/commons/widgets/customTextContainer.dart';
import 'package:eshop_plus/utils/designConfig.dart';

import 'package:eshop_plus/core/localization/labelKeys.dart';
import 'package:eshop_plus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SocialLoginWidget extends StatelessWidget {
  const SocialLoginWidget(
      {super.key, required bool isSignUpScreen, final String? fromScreen})
      : _isSignUpScreen = isSignUpScreen,
        fromScreen = fromScreen;

  final bool _isSignUpScreen;
  final String? fromScreen;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignUpCubit, SignUpState>(
        listener: (context, state) async {
      if (state is SignUpSuccess) {
        if (state.userDetails.active == '0') {
          Utils.showSnackBar(
              context: context, message: deactivatedErrorMessageKey);
          return;
        }
        context.read<AuthCubit>().authenticateUser(
            userDetails: state.userDetails, token: state.token);
        context
            .read<UserDetailsCubit>()
            .emitUserSuccessState(state.userDetails.toJson(), state.token);
        await Utils.syncFavoritesToUser(context);
        FocusScope.of(context).unfocus();
        if (fromScreen == Routes.cartScreen) {
          Utils.popNavigation(context);
        } else {
          Utils.navigateToScreen(context, Routes.mainScreen, replaceAll: true);
        }
      }
      if (state is SignUpFailure) {
        Utils.showSnackBar(context: context, message: state.errorMessage);
      }
    }, builder: (context, state) {
      return Platform.isAndroid
          ? buildSocialLoginButton(context, state, googleLoginType)
          : context
                          .read<SettingsAndLanguagesCubit>()
                          .getSettings()
                          .systemSettings!
                          .apple ==
                      1 &&
                  context
                          .read<SettingsAndLanguagesCubit>()
                          .getSettings()
                          .systemSettings!
                          .google !=
                      1
              ? buildSocialLoginButton(context, state, appleLoginType)
              : context
                              .read<SettingsAndLanguagesCubit>()
                              .getSettings()
                              .systemSettings!
                              .google ==
                          1 &&
                      context
                              .read<SettingsAndLanguagesCubit>()
                              .getSettings()
                              .systemSettings!
                              .apple !=
                          1
                  ? buildSocialLoginButton(context, state, googleLoginType)
                  : Row(
                      children: [
                        Flexible(
                            child: buildSocialLoginButton(
                                context, state, googleLoginType)),
                        DesignConfig.defaultWidthSizedBox,
                        Flexible(
                            child: buildSocialLoginButton(
                                context, state, appleLoginType)),
                      ],
                    );
    });
  }

  Widget buildSocialLoginButton(
      BuildContext context, SignUpState state, String loginType) {
    if ((loginType == googleLoginType &&
            context
                    .read<SettingsAndLanguagesCubit>()
                    .getSettings()
                    .systemSettings!
                    .google ==
                1) ||
        ((loginType == appleLoginType &&
            context
                    .read<SettingsAndLanguagesCubit>()
                    .getSettings()
                    .systemSettings!
                    .apple ==
                1))) {
      return CustomRoundedButton(
        widthPercentage: 1,
        buttonTitle: '',
        showBorder: true,
        borderColor: Theme.of(context).inputDecorationTheme.iconColor,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        onTap: state is SignUpProgress && state.loginType == loginType
            ? () {}
            : () {
                context.read<SignUpCubit>().signUpUser(loginType);
              },
        child: state is SignUpProgress && state.loginType == loginType
            ? CustomCircularProgressIndicator(
                indicatorColor: Theme.of(context).colorScheme.primary,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Utils.setSvgImage(loginType == googleLoginType
                      ? AppAssets.googleLogo
                      : AppAssets.appleLogo),
                  DesignConfig.defaultWidthSizedBox,
                  Flexible(
                    child: CustomTextContainer(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textKey: _isSignUpScreen
                          ? loginType == googleLoginType
                              ? signUpWithGoogleKey
                              : signUpWithAppleKey
                          : loginType == googleLoginType
                              ? signInWithGoogleKey
                              : signInWithAppleKey,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.67)),
                    ),
                  )
                ],
              ),
      );
    }
    return const SizedBox.shrink();
  }
}
