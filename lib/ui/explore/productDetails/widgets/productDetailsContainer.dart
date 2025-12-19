import 'package:eshop_plus/commons/blocs/settingsAndLanguagesCubit.dart';
import 'package:eshop_plus/commons/product/models/product.dart';
import 'package:eshop_plus/commons/widgets/customCircularProgressIndicator.dart';
import 'package:eshop_plus/commons/widgets/customDefaultContainer.dart';
import 'package:eshop_plus/commons/widgets/customTextContainer.dart';
import 'package:eshop_plus/utils/designConfig.dart';
import 'package:eshop_plus/core/localization/labelKeys.dart';
import 'package:eshop_plus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailsContainer extends StatefulWidget {
  final Product product;
  const ProductDetailsContainer({Key? key, required this.product})
      : super(key: key);

  @override
  _ProductDetailsContainerState createState() =>
      _ProductDetailsContainerState();
}

class _ProductDetailsContainerState extends State<ProductDetailsContainer>
    with SingleTickerProviderStateMixin {
  bool _isExpand = false;
  late AnimationController _expandController;
  late Animation<double> _animation;
  late TextStyle textStyle;
  late Product product;
  void _toggleExpanded() {
    _isExpand = !_isExpand;

    if (_isExpand) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    product = widget.product;

    _expandController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _animation = CurvedAnimation(
      parent: _expandController,
      curve: const Interval(
        0.0,
        0.4,
        curve: Curves.fastOutSlowIn,
      ),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    textStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
        overflow: TextOverflow.visible);
    return CustomDefaultContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with expand/collapse
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTitle(Icons.info_outline, productsDetailsKey),
              GestureDetector(
                onTap: _toggleExpanded,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextContainer(
                        textKey: _isExpand ? lessKey : moreKey,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpand
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          DesignConfig.defaultHeightSizedBox,
          // Essential Info Section (Always Visible)
          _buildEssentialInfoSection(),
          _buildDivider(),
          // Short Description
          if (product.shortDescription != null &&
              product.shortDescription!.isNotEmpty)
            _buildDescriptionCard(product.shortDescription!, false),

          // Expandable Detailed Section
          SizeTransition(
            axisAlignment: 1.0,
            sizeFactor: _animation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildDivider(),
                // Full Description
                if (product.description != null &&
                    product.description!.isNotEmpty) ...[
                  _buildDescriptionCard(product.description!, true),
                  _buildDivider(),
                ],

                // Product Specifications
                _buildSpecificationsSection(),

                // Custom Fields
                if (product.customFields != null &&
                    product.customFields!.isNotEmpty) ...[
                  _buildDivider(),
                  _buildCustomFieldsSection(),
                ],

                // Additional Info
                _buildAdditionalInfoSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Row _buildTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
        ),
        const SizedBox(width: 8),
        CustomTextContainer(
            textKey: title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
      ],
    );
  }

  _buildDivider() {
    return Divider(
      color: Theme.of(context).inputDecorationTheme.iconColor!,
      height: 40,
      thickness: 0.5,
    );
  }

  // Essential Information Section (Always Visible)
  Widget _buildEssentialInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Name
        CustomTextContainer(
          textKey: product.name ?? '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
        ),

        // Brand and Category Row
        if ((product.brandName != null && product.brandName!.isNotEmpty) ||
            (product.categoryName != null && product.categoryName!.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                // Brand
                if (product.brandName != null && product.brandName!.isNotEmpty)
                  Expanded(
                    child: _buildChip(
                      icon: Icons.business_outlined,
                      label: brandKey,
                      value: product.brandName!,
                    ),
                  ),

                if ((product.brandName != null &&
                        product.brandName!.isNotEmpty) &&
                    (product.categoryName != null &&
                        product.categoryName!.isNotEmpty))
                  const SizedBox(width: 12),

                // Category
                if (product.categoryName != null &&
                    product.categoryName!.isNotEmpty)
                  Expanded(
                    child: _buildChip(
                      icon: Icons.category_outlined,
                      label: categoryKey,
                      value: product.categoryName!,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // Enhanced Description Card
  Widget _buildDescriptionCard(String description, bool isFullDescription) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(
            isFullDescription
                ? Icons.description_outlined
                : Icons.short_text_outlined,
            isFullDescription ? fullDescriptionKey : overviewKey),
        DesignConfig.smallHeightSizedBox,
        buildDescritpion(description, textStyle),
      ],
    );
  }

  // Product Specifications Section
  Widget _buildSpecificationsSection() {
    List<Widget> specifications = [];

    // Variable product attributes
    if (product.productType == variableProductType &&
        product.attributes != null &&
        product.attributes!.isNotEmpty) {
      specifications.addAll(
        product.attributes!
            .map((variant) => _buildSpecItem(
                  variant.attrName ?? '',
                  variant.value ?? '',
                  Icons.tune_outlined,
                ))
            .toList(),
      );
    }

    // Basic specifications
    specifications.addAll([
      _buildSpecItem(
        countryOfOriginKey,
        product.madeIn == null || product.madeIn!.isEmpty
            ? '-'
            : product.madeIn!,
        Icons.public_outlined,
      ),
      _buildSpecItem(
        returnableKey,
        product.isReturnable == 1
            ? '${context.read<SettingsAndLanguagesCubit>().getSettings().systemSettings!.maxDaysToReturnItem} ${context.read<SettingsAndLanguagesCubit>().getTranslatedValue(labelKey: daysReturnKey)}'
            : noKey,
        Icons.keyboard_return_outlined,
      ),
      _buildSpecItem(
        product.isCancelable == 1 ? cancellableTillKey : cancellableKey,
        product.isCancelable == 1 ? (product.cancelableTill ?? noKey) : noKey,
        Icons.cancel_outlined,
      ),
    ]);

    if (specifications.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(Icons.settings_outlined, specificationsKey),
        const SizedBox(height: 12),
        ...specifications,
      ],
    );
  }

  // Custom Fields Section
  Widget _buildCustomFieldsSection() {
    List<Widget> customFieldWidgets = [];

    for (var field in product.customFields!) {
      String name = field['name']?.toString() ?? '';
      String type = field['type']?.toString() ?? '';
      var value = field['value'];

      if (type == 'color' && value != null) {
        customFieldWidgets.add(_buildColorField(name, value));
      } else if (type == 'file' && value is String && value.isNotEmpty) {
        customFieldWidgets.add(_buildFileField(name, value));
      } else {
        String displayValue = '';
        if (value == null) {
          displayValue = '-';
        } else if (type == 'checkbox' && value is List) {
          displayValue = value.join(', ');
        } else {
          displayValue = value.toString();
        }
        customFieldWidgets.add(_buildSpecItem(name, displayValue, null));
      }
    }

    if (customFieldWidgets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(Icons.extension_outlined, additionalFeaturesKey),
        const SizedBox(height: 12),
        ...customFieldWidgets,
      ],
    );
  }

  // Additional Info Section
  Widget _buildAdditionalInfoSection() {
    if (product.isAttachmentRequired == 1)
      return Column(
        children: [
          _buildDivider(),
          _buildTitle(Icons.attachment_outlined, isAttachmentRequiredNoteKey),
        ],
      );
    return SizedBox.shrink();
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    Color color = Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context
                      .read<SettingsAndLanguagesCubit>()
                      .getTranslatedValue(labelKey: label),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String title, String value, IconData? icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            DesignConfig.smallWidthSizedBox,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextContainer(
                  textKey: title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                CustomTextContainer(
                  textKey: value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorField(String name, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.palette_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Text(
            context
                .read<SettingsAndLanguagesCubit>()
                .getTranslatedValue(labelKey: name),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Utils.getColorFromHexValue(value),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileField(String name, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.file_download_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context
                      .read<SettingsAndLanguagesCubit>()
                      .getTranslatedValue(labelKey: name),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => Utils.launchURL(value),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            value.substring(value.lastIndexOf('/') + 1),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  buildDescritpion(String description, TextStyle textStyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: HtmlWidget(
          description,
          textStyle: textStyle,
          onTapUrl: (String? url) async {
            if (await canLaunchUrl(Uri.parse(url!))) {
              await launchUrl(Uri.parse(url));
              return true;
            } else {
              throw 'Could not launch $url';
            }
          },
          onErrorBuilder: (context, element, error) =>
              Text('$element error: $error'),
          onLoadingBuilder: (context, element, loadingProgress) =>
              CustomCircularProgressIndicator(
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
          renderMode: RenderMode.column,
        ),
      ),
    );
  }
}
