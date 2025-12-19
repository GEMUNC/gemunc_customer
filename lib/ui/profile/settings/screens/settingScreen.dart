import 'dart:math' as math;
import 'package:eshop_plus/core/configs/appConfig.dart';
import 'package:eshop_plus/ui/auth/blocs/resetPasswordCubit.dart';
import 'package:eshop_plus/commons/blocs/updateUserCubit.dart';
import 'package:eshop_plus/commons/blocs/userDetailsCubit.dart';
import 'package:eshop_plus/commons/widgets/customAppbar.dart';
import 'package:eshop_plus/commons/widgets/customCircularProgressIndicator.dart';
import 'package:eshop_plus/commons/widgets/customCuperinoSwitch.dart';
import 'package:eshop_plus/commons/widgets/customTextContainer.dart';
import 'package:eshop_plus/commons/widgets/customTextFieldContainer.dart';
import 'package:eshop_plus/commons/widgets/filterContainerForBottomSheet.dart';

import 'package:eshop_plus/core/api/apiEndPoints.dart';
import 'package:eshop_plus/core/constants/themeConstants.dart';
import 'package:eshop_plus/utils/designConfig.dart';
import 'package:eshop_plus/core/localization/labelKeys.dart';
import 'package:eshop_plus/utils/validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/routes.dart';
import '../../../../utils/utils.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);
  static Widget getRouteInstance() => BlocProvider(
        create: (context) => UpdateUserCubit(),
        child: const SettingScreen(),
      );
  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen>
    with SingleTickerProviderStateMixin {
  bool _isExpand = false;
  late AnimationController _expandController;
  late Animation<double> _animation, _roatationAnimation;
  late Color fontColor;
  final TextEditingController _mobileController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final List<String> settingItems = [
    (pushNotificationsKey),
    (promotionalEmailsKey),
    (promotionalSMSKey),
  ];

  bool value = false;
  @override
  void initState() {
    super.initState();
    prepareAnimations();
    setRotation(45);
  }

  ///Setting up the animation
  void prepareAnimations() {
    _expandController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _animation = CurvedAnimation(
      parent: _expandController,
      curve: const Interval(
        0.0,
        0.4,
        curve: Curves.fastOutSlowIn,
      ),
    );
  }

  setRotation(int degrees) {
    final angle = degrees * math.pi / 90;
    _roatationAnimation = Tween(begin: 0.0, end: angle).animate(CurvedAnimation(
        parent: _expandController,
        curve: const Interval(
          0,
          0.5,
          curve: Curves.fastOutSlowIn,
        )));
  }

  @override
  void dispose() {
    _expandController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    fontColor = Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8);
    return Scaffold(
      appBar: const CustomAppbar(
        titleKey: settingsKey,
        showBackButton: true,
      ),
      body: buildContent(),
    );
  }

  SingleChildScrollView buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(appContentHorizontalPadding),
      child: Column(
        children: <Widget>[
          if (context.read<UserDetailsCubit>().getUserType() == phoneLoginType)
            buildListTile(
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildTitle(changePasswordKey),
                    buildIcon(),
                  ],
                ),
                () => openDialog(context)),
          buildListTile(
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      buildTitle(notificationPrefKey),
                      AnimatedBuilder(
                          animation: _roatationAnimation,
                          child: buildIcon(),
                          builder: (context, child) {
                            return Transform.rotate(
                                angle: _roatationAnimation.value, child: child);
                          }),
                    ],
                  ),
                  buildNotificationPrefList()
                ],
              ), () {
            _isExpand = !_isExpand;

            if (_isExpand) {
              _expandController.forward();
            } else {
              _expandController.reverse();
            }

            setState(() {});
          }),
          buildListTile(
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildTitle(deleteAccountKey),
                  buildIcon(),
                ],
              ),
              () =>
                  Utils.navigateToScreen(context, Routes.deleteAccountScreen)),
        ],
      ),
    );
  }

  Widget buildListTile(Widget child, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          width: double.infinity,
          margin: const EdgeInsetsDirectional.only(bottom: 8),
          padding: const EdgeInsetsDirectional.all(appContentHorizontalPadding),
          decoration: ShapeDecoration(
            color: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius)),
          ),
          child: child),
    );
  }

  buildTitle(String title) {
    return CustomTextContainer(
      textKey: title,
      style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: fontColor,
          ),
    );
  }

  buildIcon() {
    return Icon(
      Icons.arrow_forward_ios,
      color: fontColor,
    );
  }

  buildNotificationPrefList() {
    return BlocBuilder<UserDetailsCubit, UserDetailsState>(
      builder: (context, state) {
        return SizeTransition(
          axisAlignment: 1.0,
          sizeFactor: _animation,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
            child: Column(
              children: <Widget>[
                _buildSettingItem(
                  0,
                  context.read<UserDetailsCubit>().isNotificationOn(),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingItem(int index, bool value) {
    return BlocConsumer<UpdateUserCubit, UpdateUserState>(
      listener: (context, state) {
        if (state is UpdateUserFetchSuccess) {
          context.read<UserDetailsCubit>().emitUserSuccessState(
              state.userDetails.toJson(),
              (context.read<UserDetailsCubit>().state
                      as UserDetailsFetchSuccess)
                  .token);

          Utils.showSnackBar(message: state.successMessage, context: context);
        }
        if (state is UpdateUserFetchFailure) {
          Utils.showSnackBar(message: state.errorMessage, context: context);
        }
      },
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            CustomTextContainer(
              textKey: settingItems[index],
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: fontColor),
            ),
            CustomCuperinoSwitch(
              value: value,
              onChanged: (value) {
                //see this values in settingItems list
                switch (index) {
                  case 0:
                    if (!value) {
                      Utils.openAlertDialog(context, onTapYes: () {
                        Navigator.of(context).pop();
                        context.read<UpdateUserCubit>().updateUser(
                            params: {ApiURL.isNotificationOnApiKey: 0});
                      }, message: offNotificationWarningKey);
                    } else {
                      context.read<UpdateUserCubit>().updateUser(
                          params: {ApiURL.isNotificationOnApiKey: 1});
                    }
                    break;
                }

                setState(() {});
              },
            )
          ],
        );
      },
    );
  }

  openDialog(BuildContext context) {
    if (Utils.isDemoUser(context)) {
      return Utils.showSnackBar(message: demoModeOnKey, context: context);
    }
    final TextEditingController _emailController = TextEditingController(text: context.read<UserDetailsCubit>().getUserEmail());

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    Utils.openModalBottomSheet(context,
            StatefulBuilder(builder: (context, StateSetter setState) {
      return BlocProvider(
        create: (context) => ResetPasswordCubit(),
        child: BlocConsumer<ResetPasswordCubit, ResetPasswordState>(
          listener: (context, state) async {
            if (state is ResetPasswordSuccess) {
              Navigator.of(context).pop();
              Utils.showSnackBar(
                  message: state.successMessage, context: context);
            } else if (state is ResetPasswordFailure) {
              Navigator.of(context).pop();
              Utils.showSnackBar(message: state.errorMessage, context: context);
            }
          },
          builder: (context, state) {
            return FilterContainerForBottomSheet(
                title: resetPasswordKey,
                borderedButtonTitle: cancelKey,
                primaryButtonTitle: sendKey,
                borderedButtonOnTap: () => Navigator.of(context).pop(),
                primaryChild: state is ResetPasswordInProgress
                    ? const CustomCircularProgressIndicator()
                    : null,
                primaryButtonOnTap: () {
                  if (state is ResetPasswordInProgress) {
                    return;
                  }
                  if (formKey.currentState!.validate()) {
                    {
                      context.read<ResetPasswordCubit>().resetPassword(params: {
                        "email": _emailController.text.trim(),
                      });
                    }
                  }
                },
                content: Form(
                  key: formKey,
                  child: Padding(
                    padding:
                        const EdgeInsetsDirectional.only(top: 16, bottom: 16),
                    child: Column(
                      children: [
                        const CustomTextContainer(
                            textKey: weWillSendVerificationCodeToKey),
                        DesignConfig.defaultHeightSizedBox,
                        CustomTextFieldContainer(
                          hintTextKey: emailKey,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.emailAddress,
                          textEditingController: _emailController,
                          labelKey: '',
                          validator: (v) => Validator.validateEmail(context, v),
                          readOnly: true,
                          suffixWidget: IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            onPressed: () => _emailController.clear(),
                          ),
                        ),
                      ],
                    ),  
                  ),
                ));
          },
        ),
      );
    }), staticContent: true)
        .then((value) {});
  }
}
