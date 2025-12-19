import 'package:eshop_plus/core/constants/themeConstants.dart';
import 'package:eshop_plus/core/routes/routes.dart';
import 'package:eshop_plus/ui/categoty/blocs/categoryCubit.dart';
import 'package:eshop_plus/commons/blocs/settingsAndLanguagesCubit.dart';
import 'package:eshop_plus/commons/blocs/storesCubit.dart';
import 'package:eshop_plus/ui/categoty/blocs/speechCubit.dart';
import 'package:eshop_plus/ui/categoty/models/category.dart';
import 'package:eshop_plus/ui/explore/screens/exploreScreen.dart';
import 'package:eshop_plus/commons/widgets/customAppbar.dart';
import 'package:eshop_plus/commons/widgets/customCircularProgressIndicator.dart';
import 'package:eshop_plus/commons/widgets/customDefaultContainer.dart';
import 'package:eshop_plus/commons/widgets/customImageWidget.dart';
import 'package:eshop_plus/commons/widgets/customTextButton.dart';
import 'package:eshop_plus/commons/widgets/customTextContainer.dart';

import 'package:eshop_plus/commons/widgets/error_screen.dart';
import 'package:eshop_plus/utils/designConfig.dart';
import 'package:eshop_plus/core/localization/labelKeys.dart';
import 'package:eshop_plus/utils/utils.dart';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class CategoryScreen extends StatefulWidget {
  final bool shouldPop;
  final int? categoryId;
  final int? storeId;

  const CategoryScreen({
    Key? key,
    this.shouldPop = false,
    this.categoryId,
    this.storeId,
  }) : super(key: key);

  static Widget getRouteInstance() => BlocProvider(
        create: (context) => SpeechCubit(),
        child: CategoryScreen(
          shouldPop: Get.arguments['shouldPop'] as bool? ?? false,
          categoryId: Get.arguments['categoryId'] as int?,
          storeId: Get.arguments['storeId'] as int?,
        ),
      );
  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  TextEditingController _searchController = TextEditingController();
  FocusNode _searchFocusNode = FocusNode();

  Category? _selectedCategory;
  bool _isSearchMode = false;
  late Size size;
  List<Category> categories = [];
  @override
  void initState() {
    if (widget.categoryId != null) {
      getCategories(search: '');
    }
    initializeCategories();

    super.initState();
  }

  getCategories({String? search}) {
    context.read<CategoryCubit>().fetchCategories(
          storeId: widget.storeId ??
              context.read<StoresCubit>().getDefaultStore().id!,
          search: search ?? _searchController.text.trim(),
          categoryId: widget.categoryId,
        );
  }

  void loadMoreCategories({String? search}) {
    context.read<CategoryCubit>().loadMore(
        storeId:
            widget.storeId ?? context.read<StoresCubit>().getDefaultStore().id!,
        search: _searchController.text.trim(),
        categoryId: widget.categoryId);
  }

  void initializeCategories() {
    Future.delayed(Duration.zero, () {
      if (context.read<CategoryCubit>().state is CategoryFetchSuccess) {
        final state =
            context.read<CategoryCubit>().state as CategoryFetchSuccess;
        categories = state.categories;
        _selectedCategory = state.categories.first;
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SpeechCubit, SpeechState>(
      listener: (context, speechState) {
        if (speechState is SpeechResult && speechState.text.isNotEmpty) {
          setState(() {
            _searchController.text = speechState.text;
         
          });
          getCategories(search: speechState.text);
          // Focus on search field after speech result
          Future.delayed(Duration(milliseconds: 100), () {
            FocusScope.of(context).requestFocus(_searchFocusNode);
          });
        }
        if (speechState is SpeechError) {
          String translatedMessage = context
              .read<SettingsAndLanguagesCubit>()
              .getTranslatedValue(labelKey: speechState.message);
          Utils.showSnackBar(message: translatedMessage, context: context);
        }
        if (speechState is SpeechStopped) {
         
          Future.delayed(Duration(milliseconds: 100), () {
            FocusScope.of(context).requestFocus(_searchFocusNode);
          });
        }
      },
      builder: (context, speechState) {
        final isListening = speechState is SpeechListening;
        return Scaffold(
          appBar: buildAppbar(isListening),
          body: buildCategoryList(),
        );
      },
    );
  }

  buildCategoryList() {
    return BlocConsumer<CategoryCubit, CategoryState>(
        listener: (context, state) {
      if (state is CategoryFetchSuccess) {
        categories = state.categories;
        _selectedCategory = state.categories.first;
      }
    }, builder: (context, state) {
      if (state is CategoryFetchSuccess) {
        return RefreshIndicator(
          onRefresh: () async {
            _searchController.clear();
            getCategories(search: '');
          },
          child: LayoutBuilder(builder: (context, boxConstraints) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  width: boxConstraints.maxWidth * 0.25,
                  child: NotificationListener<ScrollUpdateNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.pixels >=
                          notification.metrics.maxScrollExtent) {
                        if (context.read<CategoryCubit>().hasMore()) {
                          loadMoreCategories();
                        }
                      }
                      return true;
                    },
                    child: ListView.builder(
                      itemCount: state.categories.length,
                      itemBuilder: (context, index) {
                        Category category = state.categories[index];
                        if (context.read<CategoryCubit>().hasMore()) {
                          if (index == state.categories.length - 1) {
                            if (context
                                .read<CategoryCubit>()
                                .fetchMoreError()) {
                              return Center(
                                child: CustomTextButton(
                                    buttonTextKey: retryKey,
                                    onTapButton: () {
                                      loadMoreCategories();
                                    }),
                              );
                            }

                            return Center(
                              child: CustomCircularProgressIndicator(
                                  indicatorColor:
                                      Theme.of(context).colorScheme.primary),
                            );
                          }
                        }
                        return _buildCategoryContainer(category: category);
                      },
                    ),
                  ),
                ),
                if (_selectedCategory != null)
                  if (_selectedCategory!.children!.isEmpty)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsetsDirectional.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Category Icon/Image
                            CustomImageWidget(
                              url: _selectedCategory!.image,
                              width: 100,
                              height: 100,
                              borderRadius: 50,
                              isCircularImage: true,
                              boxFit: BoxFit.contain,
                            ),
                            DesignConfig.defaultHeightSizedBox,

                            // Positive Title
                            CustomTextContainer(
                              textKey: exploreProductsDirectlyKey,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            DesignConfig.smallHeightSizedBox,

                            // Encouraging Description
                            CustomTextContainer(
                              textKey: categoryHasProductsKey,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withValues(alpha: 0.8),
                                  ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                            ),
                            DesignConfig.defaultHeightSizedBox,

                            // Secondary Action
                            TextButton.icon(
                              onPressed: () {
                                Utils.navigateToScreen(
                                  context,
                                  Routes.exploreScreen,
                                  arguments: ExploreScreen.buildArguments(
                                    storeId: widget.storeId,
                                    category: _selectedCategory,
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.search_outlined,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              label: CustomTextContainer(
                                textKey: discoverProductsKey,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      width: boxConstraints.maxWidth * 0.75,
                      padding: const EdgeInsetsDirectional.all(
                          appContentHorizontalPadding),
                      child: ListView.separated(
                        separatorBuilder: (context, index) =>
                            DesignConfig.defaultHeightSizedBox,
                        itemCount: _selectedCategory!.children!.isNotEmpty
                            ? _selectedCategory!.children!.length
                            : 0,
                        itemBuilder: (context, index) {
                          return _buildSelectedCategoryView(
                            _selectedCategory!.children![index],
                          );
                        },
                      ),
                    ),
              ],
            );
          }),
        );
      }
      if (state is CategoryFetchFailure) {
        return ErrorScreen(text: state.errorMessage, onPressed: getCategories);
      }
      return CustomCircularProgressIndicator(
        indicatorColor: Theme.of(context).colorScheme.primary,
      );
    });
  }
void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
        });
      if (!_isSearchMode) {
        // Closing search mode
        setState(() {
            _searchController.clear();
        FocusScope.of(context).unfocus(); // Close keyboard
        getCategories(search: '');
        });
      
        context.read<SpeechCubit>().stopListening();
      } else {
        // Opening search mode - auto focus to open keyboard
        Future.delayed(const Duration(milliseconds: 100), () {
          _searchFocusNode.requestFocus();
        });
      }
  
  }
 

  buildAppbar(bool isListening) {

    return CustomAppbar(
      titleKey: categoriesKey,
      showBackButton: widget.shouldPop ? true : false,
      leadingWidget: _isSearchMode || isListening ? buildSearchField() : null,
      trailingWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_isSearchMode || isListening
                ? Icons.close
                : Icons.search_outlined),
            onPressed: _toggleSearchMode,
          ),
          IconButton(
            icon: Icon(
              isListening ? Icons.mic : Icons.mic_none,
              color: isListening
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () {
              if (isListening) {
                context.read<SpeechCubit>().stopListening();
              } else {
                // Enable search mode when starting speech
                if (!_isSearchMode) {
                  setState(() {
                    _isSearchMode = true;
                  });
                }
                context.read<SpeechCubit>().initSpeech();
                context.read<SpeechCubit>().startListening();
              }
            },
          )
        ],
      ),
    );
  }

  Widget _buildCategoryContainer({
    required Category category,
  }) {
    final isSelected = category == _selectedCategory;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
        if (category.children!.isEmpty) {
          Utils.navigateToScreen(context, Routes.exploreScreen,
              arguments: ExploreScreen.buildArguments(category: category));
        }
      },
      child: Stack(
        children: [
          isSelected
              ? Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Container(
                    width: 6.0,
                    height: 100,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: Theme.of(context).colorScheme.primary),
                  ),
                )
              : const SizedBox(),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 12, vertical: 8),
            child: Column(
              children: [
                CustomImageWidget(
                  url: category.image,
                  borderRadius: 50,
                  isCircularImage: true,
                  boxFit: BoxFit.fill,
                ),
                CustomTextContainer(
                    textKey: category.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buildSelectedCategoryView(Category category) {
    //we will navigate to product screen if there are no children

    return GestureDetector(
      onTap: () {
        if (category.children!.isEmpty) {
          Utils.navigateToScreen(context, Routes.exploreScreen,
              arguments: ExploreScreen.buildArguments(category: category));
        }
      },
      child: CustomDefaultContainer(
          borderRadius: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: CustomTextContainer(
                        textKey: category.name.capitalizeFirst!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                       ),
                  ),
                  if (category.children!.length > 6)
                    GestureDetector(
                      onTap: () => Utils.navigateToScreen(
                          context, Routes.subCategoryScreen,
                          arguments: {
                            'category': category,
                          },
                          preventDuplicates: false),
                      child: CustomTextContainer(
                        textKey: seeAllKey,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.67)),
                      ),
                    ),
                ],
              ),
              DesignConfig.defaultHeightSizedBox,
              if (category.children!.isNotEmpty) ...[
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.start,
                  direction: Axis.horizontal,
                  spacing: 12,
                  runSpacing: appContentHorizontalPadding,
                  children: List.generate(
                      category.children!.length > 6
                          ? 6
                          : category.children!.length,
                      (index) => buildCategory(category.children![index])),
                )
              ] else
                CustomImageWidget(
                  url: category.image,
                  width: 66,
                  height: 75,
                  borderRadius: borderRadius,
                ),
            ],
          )),
    );
  }

  buildCategory(Category category) {
    return SizedBox(
      width: 66,
      height: 125,
      child: GestureDetector(
        onTap: () {
          if (category.children!.isEmpty) {
            Utils.navigateToScreen(context, Routes.exploreScreen,
                arguments: ExploreScreen.buildArguments(category: category));
          } else {
            Utils.navigateToScreen(
              context,
              Routes.subCategoryScreen,
              arguments: {
                'category': category,
              },
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomImageWidget(
              url: category.image,
              width: 66,
              height: 75,
              borderRadius: borderRadius,
            ),
            DesignConfig.smallHeightSizedBox,
            CustomTextContainer(
              textKey: category.name,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }

  buildSearchField() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      height: 40,
      padding:
          const EdgeInsetsDirectional.only(start: appContentHorizontalPadding),
      child: TextFormField(
        controller: _searchController,
        autofocus: true,
        textAlignVertical: TextAlignVertical.center,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 15),
          hintText: context
              .read<SettingsAndLanguagesCubit>()
              .getTranslatedValue(labelKey: searchCategoryKey),
          hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withValues(alpha: 0.67)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        onChanged: (value) {
          getCategories(search: _searchController.text);
        },
        onFieldSubmitted: (value) {
          getCategories(search: value);
        },
      ),
    );
  }
}
