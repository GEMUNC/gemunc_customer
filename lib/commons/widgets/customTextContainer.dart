import 'package:eshop_plus/commons/blocs/settingsAndLanguagesCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomTextContainer extends StatelessWidget {
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final String textKey;
  final TextOverflow? overflow;


  const CustomTextContainer(
      {super.key,
      required this.textKey,
      this.maxLines,
      this.style,
      this.textAlign,
      this.overflow});

  @override
  Widget build(BuildContext context) {
    // Use theme's bodyMedium as default with secondary color already set
    // If custom style is provided, merge it with theme style
    final effectiveStyle = style ?? Theme.of(context).textTheme.bodyMedium;

    return Text(
      context
          .read<SettingsAndLanguagesCubit>()
          .getTranslatedValue(labelKey: textKey),
      style: effectiveStyle,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      textDirection: Directionality.of(context),
      softWrap: true,
    );
  }
}
