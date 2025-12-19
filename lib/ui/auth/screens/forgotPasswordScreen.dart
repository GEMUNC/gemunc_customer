import 'package:eshop_plus/core/configs/appConfig.dart';
import 'package:eshop_plus/ui/auth/blocs/resetPasswordCubit.dart';
import 'package:eshop_plus/ui/auth/widgets/loginContainer.dart';
import 'package:eshop_plus/core/localization/labelKeys.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/routes/routes.dart';

import '../../../utils/utils.dart';
import '../../../utils/validator.dart';
import '../../../commons/widgets/customCircularProgressIndicator.dart';
import '../../../commons/widgets/customTextFieldContainer.dart';
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);
  static Widget getRouteInstance() => BlocProvider(
        create: (context) => ResetPasswordCubit(),
        child: const ForgotPasswordScreen(),
      );
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ResetPasswordCubit, ResetPasswordState>(
      listener: (context, state) {
        if (state is ResetPasswordSuccess) {
          Utils.showSnackBar(message: state.successMessage);
          Utils.navigateToScreen(context, Routes.loginScreen);
        } else if (state is ResetPasswordFailure) {
          Utils.showSnackBar(message: state.errorMessage);
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: LoginContainer(
            titleText: forgotPasswordTitleKey,
            descriptionText: weWillSendVerificationCodeToKey,
            buttonText: resetPasswordKey,
            buttonWidget: state is ResetPasswordInProgress
                ? const CustomCircularProgressIndicator()
                : null,
            onTapButton: state is ResetPasswordInProgress ? () {} : callApi,
            content: buildContent(),
          ),
        );
      },
    );
  }

  callApi() {
    FocusScope.of(context).unfocus();
    if (isDemoApp) {
      Utils.showSnackBar(message: demoModeOnKey);
      return;
    }
    if (_formkey.currentState!.validate()) {
      {
        context.read<ResetPasswordCubit>().resetPassword(params: {
          "email": _emailController.text.trim(),
        });
      }
    }
  }

  Widget buildContent() {
    return Form(
      key: _formkey,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(top: 25, bottom: 120),
        child: CustomTextFieldContainer(
          hintTextKey: emailKey,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.emailAddress,
          textEditingController: _emailController,
          labelKey: '',
          validator: (v) => Validator.validateEmail(context, v),
          onChanged: (p0) => setState(() {}),
          suffixWidget: _emailController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () => _emailController.clear(),
                )
              : null,
        ),
      ),
    );
  }
}
