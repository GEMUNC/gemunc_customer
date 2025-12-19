import 'package:eshop_plus/commons/blocs/settingsAndLanguagesCubit.dart';
import 'package:eshop_plus/commons/widgets/customRoundedButton.dart';
import 'package:eshop_plus/commons/widgets/customTextContainer.dart';
import 'package:eshop_plus/core/constants/appAssets.dart';
import 'package:eshop_plus/utils/designConfig.dart';
import 'package:eshop_plus/core/localization/labelKeys.dart';
import 'package:eshop_plus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ErrorScreen extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget? child;
  final String? text;
  final String? image;
  final buttonText;
  const ErrorScreen(
      {Key? key,
      required this.onPressed,
      this.child,
      this.text,
      this.buttonText,
      this.image})
      : super(key: key);

  // Helper method to determine which image to show
  String _getImageAsset(BuildContext context) {
    // Priority 1: If custom image is provided, use it
    if (image != null) {
      return image!;
    }

    // Priority 2: Based on text/error type, show appropriate default image
    if (text == noInternetKey) {
      return AppAssets.noInternet;
    }

    // Check for various "no data" scenarios
    if (text == dataNotAvailableKey ||
        text == "data_not_found" ||
        text ==
            context
                .read<SettingsAndLanguagesCubit>()
                .getTranslatedValue(labelKey: "no_data_found") ||
        text == "Data Not Found" ||
        text == 'No data found' || text == rateLimitErrorMessageKey) {
      return AppAssets.noDataFound;
    }

    // Priority 3: Default fallback image
    return '';
  }

  @override
  Widget build(BuildContext context) {
    String image = _getImageAsset(context);
    return Container(
      padding: const EdgeInsetsDirectional.all(35),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
          // Simplified image logic
          if (image.isNotEmpty)
            Flexible(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: FittedBox(
                  child: Utils.setSvgImage(image, height: 400),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomTextContainer(
              textKey: text ?? defaultErrorMessageKey,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
          DesignConfig.defaultHeightSizedBox,
          child != null
              ? child!
              : [
                  noInternetKey,
                  defaultErrorMessageKey,
                  internalServerErrorMessageKey
                ].contains(text)
                  ? CustomRoundedButton(
                      widthPercentage: 0.35,
                      buttonTitle: buttonText ?? retryKey,
                      showBorder: false,
                      onTap: onPressed,
                    )
                  : SizedBox.shrink()
              ],
            ),
          ),
        ],
      ),
    );
  }
}
