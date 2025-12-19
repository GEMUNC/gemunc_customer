import 'package:eshop_plus/commons/models/store.dart';
import 'package:eshop_plus/core/constants/themeConstants.dart';
import 'package:eshop_plus/core/routes/routes.dart';
import 'package:eshop_plus/commons/blocs/storesCubit.dart';
import 'package:eshop_plus/ui/explore/screens/exploreScreen.dart';
import 'package:eshop_plus/ui/home/widgets/buildHeader.dart';
import 'package:eshop_plus/commons/widgets/customImageWidget.dart';
import 'package:eshop_plus/commons/widgets/customTextContainer.dart';
import 'package:eshop_plus/commons/widgets/error_screen.dart';
import 'package:eshop_plus/utils/cardStyles.dart';
import 'package:eshop_plus/utils/designConfig.dart';
import 'package:eshop_plus/core/localization/labelKeys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../categoty/blocs/categoryCubit.dart';
import '../../categoty/models/category.dart';
import '../../../utils/utils.dart';

class CategorySection extends StatelessWidget {
  CategorySection({Key? key}) : super(key: key);
  double extraWidthAndHeight = 0;
  StoreSettings? storeSettings;
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    storeSettings=context
                            .read<StoresCubit>()
                            .getDefaultStore()
                            .storeSettings!;
    extraWidthAndHeight = context
                .read<StoresCubit>()
                .getDefaultStore()
                .storeSettings!
                .categoryStyle!.toCategoryStyle() == CategoryStyle.style1
        ? 0
        : 10;
    return BlocConsumer<CategoryCubit, CategoryState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is CategoryFetchSuccess) {
          return Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsetsDirectional.symmetric(
                vertical: appContentHorizontalPadding),
            margin: const EdgeInsetsDirectional.only(
                bottom: appContentHorizontalPadding / 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BuildHeader(
                    title: storeSettings!
                            .categorySectionTitle ??
                        shopByCategoryKey,
                    showSeeAllButton:
                        state.categories.length > maxLimitOfWidgetsInHome
                            ? true
                            : false,
                    onTap: () => Utils.navigateToScreen(
                        context, Routes.categoryScreen,
                        arguments: {'shouldPop': true})),
                DesignConfig.defaultHeightSizedBox,
                SizedBox(
                  height: (context
                .read<StoresCubit>()
                .getDefaultStore()
                .storeSettings!
                .categoryStyle!.toCategoryStyle() == CategoryStyle.style1)
                      ? 150 + extraWidthAndHeight
                      : 100 + extraWidthAndHeight,
                  child: ListView.separated(
                      separatorBuilder: (context, index) =>
                          DesignConfig.defaultWidthSizedBox,
                      padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: appContentHorizontalPadding),
                      clipBehavior: Clip.none,
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount:
                          state.categories.length > maxLimitOfWidgetsInHome
                              ? maxLimitOfWidgetsInHome
                              : state.categories.length,
                      itemBuilder: (context, index) => buildCategory(
                          state.categories[index], size, context)),
                ),
              ],
            ),
          );
        }
        if (state is CategoryFetchFailure) {
          return ErrorScreen(
              text: state.errorMessage,
              onPressed: () => context.read<CategoryCubit>().fetchCategories(
                  storeId: context.read<StoresCubit>().getDefaultStore().id!));
        }
        return const Center(child: SizedBox.shrink());
      },
    );
  }

//here category_card_style set in every store. 'style_1' is for rectangle and 'style_2' is for square. 'style_3' is for circle
//category_style is whether to display category name or not
  buildCategory(Category category, Size size, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (category.children!.isEmpty) {
          Utils.navigateToScreen(context, Routes.exploreScreen,
              arguments: ExploreScreen.buildArguments(category: category));
        } else {
          Utils.navigateToScreen(context, Routes.subCategoryScreen, arguments: {
            'category': category,
          });
        }
      },
      child: SizedBox(
        width: 75 + extraWidthAndHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            storeSettings!
                        .categoryCardStyle
                        ?.toCategoryCardStyle() ==
                    CategoryCardStyle.style3
                ? CustomImageWidget(
                    url: category.image,
                    borderRadius: 50,
                    isCircularImage: true,
                  )
                : CustomImageWidget(
                    url: category.image,
                    height:  storeSettings!
                                .categoryCardStyle
                                ?.toCategoryCardStyle() ==
                            CategoryCardStyle.style1
                        ? 100 + extraWidthAndHeight
                        : 75 + extraWidthAndHeight,
                    width: 75 + extraWidthAndHeight,
                    borderRadius: 4,
                  ),
            if (storeSettings!
                .categoryStyle!.toCategoryStyle() == CategoryStyle.style1) ...[
              const SizedBox(
                height: 8,
              ),
              Expanded(
                child: CustomTextContainer(
                  textKey: category.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              )
            ],
          ],
        ),
      ),
    );
  }
}
