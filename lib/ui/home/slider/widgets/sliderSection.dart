import 'dart:async';

import 'package:eshop_plus/core/constants/themeConstants.dart';
import 'package:eshop_plus/core/routes/routes.dart';
import 'package:eshop_plus/core/theme/colors.dart';
import 'package:eshop_plus/ui/home/slider/blocs/sliderCubit.dart';
import 'package:eshop_plus/ui/categoty/models/category.dart';
import 'package:eshop_plus/ui/home/slider/models/slider.dart';
import 'package:eshop_plus/ui/explore/screens/exploreScreen.dart';
import 'package:eshop_plus/ui/explore/productDetails/productDetailsScreen.dart';
import 'package:eshop_plus/commons/widgets/customImageWidget.dart';
import 'package:eshop_plus/commons/widgets/customTextContainer.dart';
import 'package:eshop_plus/utils/designConfig.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../utils/utils.dart';

class SliderSection extends StatefulWidget {
  const SliderSection({Key? key}) : super(key: key);

  @override
  _SliderSectionState createState() => _SliderSectionState();
}

class _SliderSectionState extends State<SliderSection>
    with AutomaticKeepAliveClientMixin {
  int _sliderIndex = 0;
  int _slidersLength = 0;
  Timer? _timer;
  late PageController _pageController;
  late Size size;
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: 0.9);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 8), (Timer timer) {
      if (_slidersLength == 0 || !_pageController.hasClients) return;

      if (_sliderIndex < _slidersLength - 1) {
        _sliderIndex++;
      } else {
        _sliderIndex = 0;
      }

      _pageController.animateToPage(
        _sliderIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    _pageController.dispose();
  }

  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    size = MediaQuery.of(context).size;
    return BlocConsumer<SliderCubit, SliderState>(
      listener: (context, state) {
        if (state is SliderFetchSuccess) {
          if (state.sliders.isNotEmpty) {
            final sliders = state.sliders;

            // If new data length changes or first item changes, reset the slider
            if (_slidersLength != sliders.length ||
                _sliderIndex >= sliders.length) {
              _sliderIndex = 0;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(0);
                }
              });
            }
            _slidersLength = sliders.length;
          }
        }
      },
      builder: (context, state) {
        if (state is SliderFetchSuccess) {
          return Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsetsDirectional.symmetric(
                vertical: appContentHorizontalPadding),
            margin: const EdgeInsetsDirectional.only(
                bottom: appContentHorizontalPadding / 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 180, // Fixed height - adjust this value as needed
                  child: PageView.builder(
                      controller: _pageController,
                      itemCount: state.sliders.length,
                      onPageChanged: (index) {
                        setState(() {
                          _sliderIndex = index;
                        });
                      },
                      itemBuilder: (context, index) => buildSlider(
                            state.sliders[index],
                          )),
                ),
                DesignConfig.smallHeightSizedBox,
                Pageindicator(index: _sliderIndex, length: state.sliders.length)
              ],
            ),
          );
        }

        return const Center(child: SizedBox.shrink());
      },
    );
  }

  buildSlider(Sliders slider) {
    return GestureDetector(
      onTap: () {
        if (slider.type == 'slider_url' && slider.link!.isNotEmpty) {
          Utils.launchURL(slider.link.toString());
        }
        if (slider.type == 'products') {
          Utils.navigateToScreen(context, Routes.productDetailsScreen,
              arguments: ProductDetailsScreen.buildArguments(
                product: slider.itemList![0],
              ));
        }
        if (slider.type == 'combo_products') {
          Utils.navigateToScreen(context, Routes.productDetailsScreen,
              arguments: ProductDetailsScreen.buildArguments(
                  product: slider.itemList![0], isComboProduct: true));
        }
        if (slider.type == 'categories') {
          Category category = slider.itemList![0];
          if (category.children!.isEmpty) {
            Utils.navigateToScreen(context, Routes.exploreScreen,
                arguments: ExploreScreen.buildArguments(category: category));
          } else {
            Utils.navigateToScreen(context, Routes.subCategoryScreen,
                arguments: {
                  'category': category,
                });
          }
        }
      },
      child: Container(
        width: size.width * 0.95,
        height: MediaQuery.of(context).size.height *
            0.22, // Fixed height matching the SizedBox above
        margin: const EdgeInsetsDirectional.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: transparentColor,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomImageWidget(
            url: slider.image.toString(),
            borderRadius: 0, // Set to 0 since ClipRRect handles the rounding
            boxFit: BoxFit.cover, // Try contain first to see full image
          ),
        ),
      ),
    );
  }
}

class Pageindicator extends StatelessWidget {
  final int length;
  final int index;
  const Pageindicator({Key? key, required this.index, required this.length})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
            margin: const EdgeInsetsDirectional.only(end: 8),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: index == 0
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.46),
                shape: BoxShape.circle)),
        AnimatedContainer(
          duration: const Duration(seconds: 2),
          padding:
              const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(100),
          ),
          child: CustomTextContainer(
            textKey: '${index + 1} / $length',
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
        Container(
            margin: const EdgeInsetsDirectional.only(start: 8),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: index == length - 1
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.46),
                shape: BoxShape.circle)),
      ],
    );
  }
}
