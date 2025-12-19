import 'package:eshop_plus/commons/widgets/customAppbar.dart';
import 'package:eshop_plus/commons/widgets/customCircularProgressIndicator.dart';
import 'package:eshop_plus/commons/widgets/customTextContainer.dart';
import 'package:eshop_plus/commons/widgets/safeAreaWithBottomPadding.dart';
import 'package:eshop_plus/core/constants/themeConstants.dart';
import 'package:eshop_plus/core/localization/labelKeys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';

import '../../utils/utils.dart';

class PolicyScreen extends StatelessWidget {
  final String title;
  final String content;
  final bool isRawText;

  static Widget getRouteInstance() {
    Map<String, dynamic> arguments = Get.arguments ?? {};
    return PolicyScreen(
      title: arguments['title'],
      content: arguments['content'],
      isRawText: arguments['isRawText'] ?? false,
    );
  }

  const PolicyScreen(
      {Key? key,
      required this.title,
      required this.content,
      this.isRawText = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeAreaWithBottomPadding(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        appBar: CustomAppbar(titleKey: title),
        body: content.isNotEmpty
            ? SingleChildScrollView(
                padding: const EdgeInsetsDirectional.all(
                    appContentHorizontalPadding),
                child: isRawText
                    ? Text(content)
                    : HtmlWidget(
                        content,
                        onErrorBuilder: (context, element, error) =>
                            Text('$element error: $error'),
                        onLoadingBuilder: (context, element, loadingProgress) =>
                            Center(
                                child: CustomCircularProgressIndicator(
                                    indicatorColor:
                                        Theme.of(context).colorScheme.primary)),
                        onTapUrl: (url) {
                          Utils.launchURL(url);
                          return true;
                        },
                      ),
              )
            : const Center(
                child: CustomTextContainer(textKey: dataNotAvailableKey)),
      ),
    );
  }
}
