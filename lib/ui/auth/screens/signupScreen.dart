import 'package:eshop_plus/commons/widgets/safeAreaWithBottomPadding.dart';
import 'package:eshop_plus/commons/widgets/countryCodePicker.dart';
import 'package:eshop_plus/core/constants/themeConstants.dart';
import 'package:eshop_plus/ui/auth/blocs/signUpCubit.dart';
import 'package:eshop_plus/ui/auth/blocs/verifyCredentialsCubit.dart';
import 'package:eshop_plus/commons/blocs/settingsAndLanguagesCubit.dart';
import 'package:eshop_plus/commons/blocs/userDetailsCubit.dart';

import 'package:eshop_plus/ui/auth/widgets/aggrementTextContainer.dart';
import 'package:eshop_plus/ui/auth/widgets/socialLoginWidget.dart';
import 'package:eshop_plus/commons/widgets/customCircularProgressIndicator.dart';

import 'package:eshop_plus/commons/widgets/customTextContainer.dart';

import 'package:eshop_plus/core/api/apiEndPoints.dart';
import 'package:eshop_plus/core/localization/labelKeys.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../core/routes/routes.dart';

import '../../../utils/utils.dart';
import '../../../utils/validator.dart';
import '../../../commons/widgets/customTextFieldContainer.dart';
import '../widgets/loginContainer.dart';

class SignupScreen extends StatefulWidget {
  final String? fromScreen;
  const SignupScreen({super.key, this.fromScreen});
  static Widget getRouteInstance() => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => SignUpCubit()),
          BlocProvider(create: (context) => VerifyCredentialsCubit()),
        ],
        child: SignupScreen(
          fromScreen: Get.arguments ?? '',
        ),
      );
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _mobileController = TextEditingController();
  String _countryCode = '';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      setState(() {
      _countryCode = context.read<SettingsAndLanguagesCubit>().getCountryCode();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<UserDetailsCubit, UserDetailsState>(
          listener: (context, state) {
            if (state is UserDetailsFetchSuccess &&
                !context
                    .read<SettingsAndLanguagesCubit>()
                    .getIsFirebaseAuthentication()) {
              setState(() {
                _isLoading = false;
              });
              Utils.showSnackBar(context: context, message: otpSentMessageKey);
              Utils.navigateToScreen(context, Routes.otpVerificationScreen,
                  arguments: {
                    'mobileNumber': _mobileController.text.trim(),
                    'countryCode': _countryCode,
                    'verificationID': '',
                    'fromScreen': widget.fromScreen
                  });
            }
            if (state is UserDetailsFetchFailure) {
              setState(() {
                _isLoading = false;
              });
              Utils.showSnackBar(context: context, message: state.errorMessage);
            }
          },
        ),
        BlocListener<VerifyCredentialsCubit, VerifyCredentialsState>(
          listener: (context, state) {
            if (state is VerifyCredentialsSuccess) {
              if (state.hasError) {
                setState(() {
                  _isLoading = false;
                });
                Utils.showSnackBar(context: context, message: state.message);
              } else {
                // If credentials are valid, proceed with OTP
                if (context
                    .read<SettingsAndLanguagesCubit>()
                    .getIsFirebaseAuthentication()) {
                  signInWithPhoneNumber();
                } else {
                  context.read<UserDetailsCubit>().fetchUserDetails(params: {
                    ApiURL.mobileApiKey: _mobileController.text.trim(),
                    ApiURL.countryCodeApiKey: _countryCode.replaceAll("+", ''),
                  });
                }
              }
            }
            if (state is VerifyCredentialsFailure) {
              setState(() {
                _isLoading = false;
              });
              Utils.showSnackBar(context: context, message: state.errorMessage);
            }
          },
        ),
      ],
      child: BlocBuilder<UserDetailsCubit, UserDetailsState>(
        builder: (context, state) {
        return SafeAreaWithBottomPadding(
          child: Scaffold(
              body: LoginContainer(
            titleText: signUpKey,
            descriptionText: weWillSendVerificationCodeToNumberKey,
            buttonText: sendOTPKey,
            onTapButton: () => _isLoading || state is UserDetailsFetchInProgress
                ? () {}
                : onTapSendOTPButton(state),
            content: buildContent(),
            footerWidget: buildFooterWidget(context),
            showBackButton: false,
            buttonWidget: _isLoading || state is UserDetailsFetchInProgress
                ? const CustomCircularProgressIndicator()
                : null,
            showSkipButton: true,
          )),
        );
      },
    ));
  }

  Widget buildContent() {
    return Form(
      key: _formKey,
      child: IgnorePointer(
        ignoring: _isLoading,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(top: 25),
          child: Row(
            children: <Widget>[
              Expanded(
                  flex: 1,
                  child: CustomCountryCodePicker(
                    initialCountryCode: _countryCode,
                    onChanged: (countryCode) {
                      _countryCode = countryCode.toString();
                    },
                  )),
              Expanded(
                flex: 2,
                child: CustomTextFieldContainer(
                  hintTextKey: mobileNumberKey,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.phone,
                  textEditingController: _mobileController,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Allow only digits
                    LengthLimitingTextInputFormatter(15), // Limit to 15 digits
                  ],
                  validator: (v) => Validator.validatePhoneNumber(v, context),
                  labelKey: '',
                  suffixWidget: IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: () => _mobileController.clear(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  buildFooterWidget(BuildContext context) {
    return Column(
      children: <Widget>[
        if ((context
                    .read<SettingsAndLanguagesCubit>()
                    .getSettings()
                    .systemSettings!
                    .google ==
                1) ||
            ((context
                    .read<SettingsAndLanguagesCubit>()
                    .getSettings()
                    .systemSettings!
                    .apple ==
                1))) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Divider(
                  thickness: 1,
                  color: Theme.of(context).inputDecorationTheme.iconColor,
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: appContentHorizontalPadding),
                child: CustomTextContainer(
                  textKey: orSignupWithKey,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.67)),
                ),
              ),
              Expanded(
                child: Divider(
                  thickness: 1,
                  color: Theme.of(context).inputDecorationTheme.iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 25,
          ),
          SocialLoginWidget(
            isSignUpScreen: true,
            fromScreen: widget.fromScreen,
          ),
          const SizedBox(
            height: 25,
          ),
        ],
        AggrementTextContainer(),
        const SizedBox(
          height: 25,
        ),
      ],
    );
  }

  void signInWithPhoneNumber() async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        // timeout: const Duration(seconds: 60),
        phoneNumber: '$_countryCode${_mobileController.text.trim()}',
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          //if otp code does not verify

          if (e.code == 'invalid-phone-number') {
            Utils.showSnackBar(
                context: context, message: invalidMobileErrorMsgKey);
          } else if (e.code == 'network-request-failed') {
            Utils.showSnackBar(context: context, message: noInternetKey);
          } else {
            Utils.showSnackBar(
                context: context, message: verificationErrorMessageKey);
          }

          setState(() {
            _isLoading = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isLoading = false;
          });
          Utils.showSnackBar(message: otpSentMessageKey, context: context);
          Utils.navigateToScreen(context, Routes.otpVerificationScreen,
              arguments: {
                'mobileNumber': _mobileController.text.trim(),
                'countryCode': _countryCode,
                'verificationID': verificationId,
                'fromScreen': widget.fromScreen
              })!;
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } on Exception catch (_) {
      Utils.showSnackBar(
          context: context, message: verificationErrorMessageKey);
    }
  }

  void verifyCredentialsAndProceed() {
    setState(() {
      _isLoading = true;
    });

    context.read<VerifyCredentialsCubit>().verifyCredentials(params: {
      ApiURL.mobileApiKey: _mobileController.text.trim(),
      ApiURL.countryCodeApiKey: _countryCode.replaceAll("+", ''),
    });
  }

  onTapSendOTPButton(UserDetailsState state) {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      verifyCredentialsAndProceed();
    }
  }
}
