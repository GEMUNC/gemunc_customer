import 'package:country_code_picker/country_code_picker.dart';
import 'package:eshop_plus/core/constants/themeConstants.dart';
import 'package:flutter/material.dart';

class CustomCountryCodePicker extends StatelessWidget {
  final String initialCountryCode;
  final Function(CountryCode) onChanged;
  final Function(CountryCode?)? onInit;

  const CustomCountryCodePicker({
    Key? key,
    required this.initialCountryCode,
    required this.onChanged,
    this.onInit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      margin: const EdgeInsetsDirectional.only(end: 5),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: BorderSide(
              width: 1,
              color: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: CountryCodePicker(
        onChanged: (v){
onChanged(v);
          FocusManager.instance.primaryFocus?.unfocus();
        },
        flagWidth: 25,
        textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Theme.of(context)
                .colorScheme
                .secondary
                ),
                
        padding: EdgeInsets.zero,
        // Initial selection and favorite can be one of code ('IT') OR dial_code('+39')
        initialSelection: initialCountryCode,
        showFlagDialog: true,
        comparator: (a, b) => b.name!.compareTo(a.name!),
        //Get the country information relevant to the initial selection
        onInit: onInit ?? (code) {},
        alignLeft: true,
      ),
    );
  }
}