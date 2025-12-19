import 'package:eshop_plus/commons/widgets/safeAreaWithBottomPadding.dart';
import 'package:eshop_plus/commons/widgets/countryCodePicker.dart';
import 'package:eshop_plus/core/configs/appConfig.dart';
import 'package:eshop_plus/core/constants/themeConstants.dart';
import 'package:eshop_plus/core/routes/routes.dart';
import 'package:eshop_plus/core/theme/colors.dart';
import 'package:eshop_plus/ui/auth/blocs/authCubit.dart';
import 'package:eshop_plus/ui/auth/blocs/signInCubit.dart';
import 'package:eshop_plus/ui/auth/blocs/signUpCubit.dart';
import 'package:eshop_plus/ui/auth/repositories/authRepository.dart';
import 'package:eshop_plus/commons/repositories/settingsRepository.dart';

import 'package:eshop_plus/ui/auth/widgets/loginContainer.dart';
import 'package:eshop_plus/ui/auth/widgets/socialLoginWidget.dart';
import 'package:eshop_plus/commons/widgets/customTextButton.dart';
import 'package:eshop_plus/commons/widgets/customTextContainer.dart';
import 'package:eshop_plus/commons/widgets/customTextFieldContainer.dart';
import 'package:eshop_plus/commons/widgets/showHidePasswordButton.dart';
import 'package:eshop_plus/utils/validator.dart';
import 'package:eshop_plus/core/localization/labelKeys.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../commons/blocs/settingsAndLanguagesCubit.dart';
import '../../../commons/blocs/userDetailsCubit.dart';
import 'package:eshop_plus/core/api/apiEndPoints.dart';
import '../../../utils/utils.dart';
import '../../../commons/widgets/customCircularProgressIndicator.dart';
import '../widgets/aggrementTextContainer.dart';

class LoginScreen extends StatefulWidget {
  final String? fromScreen;
  const LoginScreen({Key? key, this.fromScreen = ''}) : super(key: key);

  static Widget getRouteInstance() => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => SignInCubit(),
          ),
          BlocProvider(
            create: (context) => SignUpCubit(),
          ),
        ],
        child: LoginScreen(
          fromScreen: Get.arguments ?? '',
        ),
      );
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController =
      TextEditingController(text: isDemoApp ? defaultPhoneNumber : null);
  final TextEditingController _passwordController =
      TextEditingController(text: isDemoApp ? defaultPassword : null);
  bool _hidePassword = true;
  String _countryCode = '';

  FocusNode? _passwordFocus = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  initState() {
    super.initState();
    
    Future.delayed(Duration.zero, () {
      SettingsRepository().setFirstTimeUser(false);
      setState(() {
        _countryCode =
            context.read<SettingsAndLanguagesCubit>().getCountryCode();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: transparentColor,
        systemNavigationBarColor: transparentColor,
        systemNavigationBarDividerColor: transparentColor,
      ),
      child: BlocConsumer<SignInCubit, SignInState>(
        listener: (context, state) async {
          if (state is SignInSuccess) {
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
            if (widget.fromScreen == Routes.cartScreen) {
              Utils.popNavigation(context);
            } else {
              Utils.navigateToScreen(context, Routes.mainScreen,
                  replaceAll: true);
            }
          }
          if (state is SignInFailure) {
            Utils.showSnackBar(context: context, message: state.errorMessage);
          }
        },
        builder: (context, state) {
          final isLoading = state is SignInProgress;
          return BlocBuilder<SignUpCubit, SignUpState>(
            builder: (context, signupstate) {
              return Stack(
                children: [
                  SafeAreaWithBottomPadding(
                    child: Scaffold(
                      body: LoginContainer(
                        titleText: welcomeBackKey,
                        descriptionText: pleaseEnterLoginDetailsKey,
                        buttonText: signInKey,
                        onTapButton: isLoading ? () {} : callSignInApi,
                        buttonWidget: isLoading
                            ? const CustomCircularProgressIndicator()
                            : null,
                        content: buildContentWidget(),
                        footerWidget: buildFooterWidget(),
                        showSkipButton: true,
                      ),
                      bottomNavigationBar: buildBottomBar(),
                    ),
                  ),
                  if (isLoading || signupstate is SignUpProgress) ...[
                    ModalBarrier(
                      dismissible: false,
                      color: blackColor.withValues(alpha: 0.3),
                    ),
                    CustomCircularProgressIndicator(
                      indicatorColor: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget buildBottomBar() {
    return Container(
      alignment: Alignment.center,
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).inputDecorationTheme.iconColor!,
          ),
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: context
                  .read<SettingsAndLanguagesCubit>()
                  .getTranslatedValue(labelKey: dontHaveAccountKey),
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: context
                  .read<SettingsAndLanguagesCubit>()
                  .getTranslatedValue(labelKey: signUpKey),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => Utils.navigateToScreen(
                    context, Routes.signupScreen,
                    arguments: widget.fromScreen),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget buildContentWidget() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(top: 25),
        child: Column(
          children: <Widget>[
            Row(
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
                    textEditingController: _mobileController,
                    labelKey: '',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // Allow only digits
                      LengthLimitingTextInputFormatter(15), // Limit to 15 digits
                    ],
                    validator: (v) => Validator.validatePhoneNumber(v, context),
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(_passwordFocus);
                    },
                  ),
                ),
              ],
            ),
            CustomTextFieldContainer(
              hintTextKey: passwordKey,
              textEditingController: _passwordController,
              labelKey: '',
              prefixWidget: const Icon(Icons.lock_outline),
              hideText: _hidePassword,
              keyboardType: TextInputType.text,
              focusNode: _passwordFocus,
              textInputAction: TextInputAction.done,
              maxLines: 1,
              validator: (v) => Validator.validatePassword(context, v),
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp('[ ]')),
              ],
              suffixWidget: ShowHidePasswordButton(
                hidePassword: _hidePassword,
                onTapButton: () {
                  setState(() {
                    _hidePassword = !_hidePassword;
                  });
                },
              ),
              onFieldSubmitted: (v) {
                _passwordFocus!.unfocus();
              },
            ),
            const SizedBox(
              height: 15,
            ),
            Align(
                alignment: Alignment.bottomRight,
                child: CustomTextButton(
                  buttonTextKey: forgotPasswordKey,
                  onTapButton: () {
                    Utils.navigateToScreen(
                        context, Routes.forgotPasswordScreen);
                  },
                  textStyle: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .copyWith(color: Theme.of(context).colorScheme.primary),
                ))
          ],
        ),
      ),
    );
  }

  void callSignInApi() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      {
        String fcm = await AuthRepository.getFcmToken();
        context.read<SignInCubit>().login(params: {
          ApiURL.mobileApiKey: _mobileController.text.trim(),
          ApiURL.passwordApiKey: _passwordController.text.trim(),
          ApiURL.fcmIdApiKey: fcm,
          ApiURL.countryCodeApiKey: _countryCode.replaceAll('+', ''),
        });
      }
    }
  }

  buildFooterWidget() {
    return Column(
      children: [
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
                  textKey: orLoginWithKey,
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
            isSignUpScreen: false,
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
}
