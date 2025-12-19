import 'dart:io';

import 'package:eshop_plus/commons/product/models/filterAttribute.dart';
import 'package:eshop_plus/core/constants/appAssets.dart';
import 'package:eshop_plus/core/constants/themeConstants.dart';
import 'package:eshop_plus/core/routes/routes.dart';
import 'package:eshop_plus/core/theme/colors.dart';
import 'package:eshop_plus/ui/categoty/repositories/categoryRepository.dart';
import 'package:eshop_plus/ui/home/brand/repositories/brandRepository.dart';
import 'package:eshop_plus/ui/explore/blocs/comboProductsCubit.dart';
import 'package:eshop_plus/commons/product/blocs/productsCubit.dart';
import 'package:eshop_plus/commons/seller/blocs/sellersCubit.dart';
import 'package:eshop_plus/ui/categoty/blocs/categoryCubit.dart';
import 'package:eshop_plus/ui/home/brand/blocs/brandsCubit.dart';
import 'package:eshop_plus/ui/categoty/models/category.dart';
import 'package:eshop_plus/ui/home/brand/models/brand.dart';
import 'package:eshop_plus/commons/blocs/settingsAndLanguagesCubit.dart';
import 'package:eshop_plus/commons/blocs/storesCubit.dart';
import 'package:eshop_plus/commons/product/models/productMinMaxPrice.dart';
import 'package:eshop_plus/ui/explore/productFilters/models/selectedFilterAttribute.dart';
import 'package:eshop_plus/ui/explore/widgets/gridProductsContainer.dart';
import 'package:eshop_plus/ui/explore/widgets/sellersContainer.dart';
import 'package:eshop_plus/ui/explore/widgets/sortProductBottomsheet.dart';
import 'package:eshop_plus/ui/mainScreen.dart';
import 'package:eshop_plus/ui/explore/productFilters/screens/productFiltersScreen.dart';
import 'package:eshop_plus/commons/widgets/customAppbar.dart';
import 'package:eshop_plus/commons/widgets/customBottomButtonContainer.dart';
import 'package:eshop_plus/commons/widgets/customCircularProgressIndicator.dart';
import 'package:eshop_plus/commons/widgets/customRoundedButton.dart';
import 'package:eshop_plus/commons/widgets/customSearchContainer.dart';
import 'package:eshop_plus/commons/widgets/customTabbar.dart';
import 'package:eshop_plus/commons/widgets/customTextContainer.dart';
import 'package:eshop_plus/commons/widgets/error_screen.dart';
import 'package:eshop_plus/core/localization/labelKeys.dart';
import 'package:eshop_plus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../../commons/widgets/safeAreaWithBottomPadding.dart';

class ExploreScreen extends StatefulWidget {
  final bool isExploreScreen;
  final Category? category;
  final String? brandId;
  final int? sellerId;
  final String? title;
  final List<int> productIds;
  final List<int> comboProductIds;
  final bool? isComboProduct;
  final bool forSellerDetailScreen;
  final bool fromSearchScreen;
  final bool sellerProductScreen;
  final int? storeId;

  const ExploreScreen({
    super.key,
    this.isExploreScreen = false,
    this.category,
    this.brandId,
    this.sellerId,
    this.title,
    this.productIds = const [],
    this.comboProductIds = const [],
    this.isComboProduct,
    this.forSellerDetailScreen = false,
    this.fromSearchScreen = false,
    this.sellerProductScreen = false,
    this.storeId,
  });

  static Widget getRouteInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ProductsCubit()),
        BlocProvider(create: (context) => ComboProductsCubit()),
        BlocProvider(create: (context) => CategoryCubit()),
        BlocProvider(create: (context) => BrandsCubit()),
      ],
      child: ExploreScreen(
        isExploreScreen: arguments['isExploreScreen'] ?? false,
        category: arguments['category'] as Category?,
        brandId: arguments['brandId'] as String?,
        sellerId: arguments['sellerId'] as int?,
        title: arguments['title'] as String?,
        isComboProduct: arguments['isComboProduct'] ?? false,
        productIds: arguments['productIds'] as List<int>? ?? [],
        comboProductIds: arguments['comboProductIds'] as List<int>? ?? [],
        forSellerDetailScreen: arguments['forSellerDetailScreen'] ?? false,
        fromSearchScreen: arguments['fromSearchScreen'] ?? false,
        storeId: arguments['storeId'] as int?,
        sellerProductScreen: arguments['sellerProductScreen'] ?? false,
      ),
    );
  }

  static Map<String, dynamic> buildArguments({
    Category? category,
    String? brandId,
    bool isExploreScreen = false,
    String? title,
    int? sellerId,
    List<int>? productIds,
    List<int>? comboProductIds,
    bool fromSearchScreen = false,
    bool forSellerDetailScreen = false,
    bool? isComboProduct = false,
    bool sellerProductScreen = false,
    int? storeId,
  }) {
    return {
      'category': category,
      'brandId': brandId,
      'isExploreScreen': isExploreScreen,
      'title': title,
      'sellerId': sellerId,
      'productIds': productIds,
      'comboProductIds': comboProductIds,
      'fromSearchScreen': fromSearchScreen,
      'isComboProduct': isComboProduct,
      'storeId': storeId,
      'forSellerDetailScreen': forSellerDetailScreen,
      'sellerProductScreen': sellerProductScreen,
    };
  }

  @override
  State<ExploreScreen> createState() => ExploreScreenState();
}

class ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  int _selectedTabIndex = 0;
  List<String> _tabs = [productsKey, comboKey, sellersKey];
  TextEditingController _searchController = TextEditingController();
  String _selectedSortBy = allKey;

  AnimationController? _animationController;

  // Separate filter attributes for products and combo products
  List<SelectedFilterAttribute> productSelectedFilterAttributes = [];
  List<SelectedFilterAttribute> comboSelectedFilterAttributes = [];

  ///[To store the selected min and max price from the text field]
  String productSelectedTextFieldMinPrice = '';
  String productSelectedTextFieldMaxPrice = '';
  String comboSelectedTextFieldMinPrice = '';
  String comboSelectedTextFieldMaxPrice = '';

  double productMinPrice = 0,
      productMaxPrice = 0,
      comboMinPrice = 0,
      comboMaxPrice = 0;
  String? filterCategoryIds,
      filterBrandIds,
      comboFilterCategoryIds,
      comboFilterBrandIds;

  dynamic sortByParams, filterParams;
  bool _productFilterAttributesLoaded = false;
  bool _comboFilterAttributesLoaded = false;
  List<FilterAttribute> _productFilterAttributes = [];
  List<FilterAttribute> _comboFilterAttributes = [];
  
  // Categories and brands data for both tabs
  List<Category> _productCategories = [];
  List<Category> _comboCategories = [];
  List<Brand> _productBrands = [];
  List<Brand> _comboBrands = [];
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController!.reverse();
    if (widget.fromSearchScreen ||
        widget.forSellerDetailScreen ||
        widget.sellerProductScreen) {
      _tabs.remove(sellersKey);
    }
    if (widget.fromSearchScreen) {
      _searchController.text = widget.title ?? '';
    }
    sortByParams = buildSortByParams();
    filterParams = buildFilterParams();
    Future.delayed(Duration.zero, () {
      getProducts();
      if (widget.isExploreScreen ||
          widget.fromSearchScreen ||
          widget.forSellerDetailScreen ||
          widget.sellerProductScreen) {
        getComboProducts();
        if (widget.isExploreScreen) {
          getSellers();
        }
      }
    });
  }

  ///[To change the sort by]
  void changeSortBy(String sortBy) {
    _selectedSortBy = sortBy;
  }

  ///[To get the current tab's selected filter attributes]
  List<SelectedFilterAttribute> get currentSelectedFilterAttributes {
    return _selectedTabIndex == 1 ? comboSelectedFilterAttributes : productSelectedFilterAttributes;
  }

  ///[To get the current tab's selected min price]
  String get currentSelectedTextFieldMinPrice {
    return _selectedTabIndex == 1 ? comboSelectedTextFieldMinPrice : productSelectedTextFieldMinPrice;
  }

  ///[To get the current tab's selected max price]
  String get currentSelectedTextFieldMaxPrice {
    return _selectedTabIndex == 1 ? comboSelectedTextFieldMaxPrice : productSelectedTextFieldMaxPrice;
  }

  ///[To get the current tab's filter attributes]
  List<FilterAttribute> get currentFilterAttributes {
    return _selectedTabIndex == 1 ? _comboFilterAttributes : _productFilterAttributes;
  }

  ///[To get the current tab's categories]
  List<Category> get currentCategories {
    return _selectedTabIndex == 1 ? _comboCategories : _productCategories;
  }

  ///[To get the current tab's brands]
  List<Brand> get currentBrands {
    return _selectedTabIndex == 1 ? _comboBrands : _productBrands;
  }

  ///[To get the selected filter attribute by name]
  SelectedFilterAttribute? getSelectedFilterAttribute(String attributeName) {
    return currentSelectedFilterAttributes.firstWhereOrNull(
      (element) => element.attributeName == attributeName,
    );
  }

  ///[To build the filter params to pass to the API]
  ({
    String? categoryIds,
    String? brandIds,
    int? sellerId,
    String? discount,
    String? rating,
    List<int> attributeIds,
    double? minPrice,
    double? maxPrice,
  }) buildFilterParams() {
    String? categoryIds = widget.category?.id.toString(),
        brandIds = widget.brandId,
        discount,
        rating;
    int? sellerId = widget.sellerId;
    List<int> attributeIds = [];
    double? minPrice, maxPrice;

    ///[If there is no filter attributes selected]
    if (currentSelectedFilterAttributes.isEmpty) {
      if (currentSelectedTextFieldMinPrice.isNotEmpty) {
        minPrice = double.parse(currentSelectedTextFieldMinPrice);
      }
      if (currentSelectedTextFieldMaxPrice.isNotEmpty) {
        maxPrice = double.parse(currentSelectedTextFieldMaxPrice);
      }

      return (
        categoryIds: categoryIds,
        brandIds: brandIds,
        sellerId: sellerId,
        discount: discount,
        rating: rating,
        attributeIds: attributeIds,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );
    }

    ///[To get the selected category ids]
    SelectedFilterAttribute? categoryAttribute = getSelectedFilterAttribute(
      categoryKey,
    );
    if (categoryAttribute != null && categoryAttribute.selectedIds.isNotEmpty) {
      categoryIds = categoryAttribute.selectedIds.join(',');
    }

    ///[To get the selected brand ids]
    SelectedFilterAttribute? brandAttribute = getSelectedFilterAttribute(
      brandKey,
    );

    if (brandAttribute != null && brandAttribute.selectedIds.isNotEmpty) {
      brandIds = brandAttribute.selectedIds.join(',');
    }

    ///[To get the selected discount]
    SelectedFilterAttribute? discountAttribute = getSelectedFilterAttribute(
      discountKey,
    );
    if (discountAttribute != null && discountAttribute.selectedIds.isNotEmpty) {
      discount = Utils.getFilterDiscountsValues(
        context: context,
      )[discountAttribute.selectedIds.first];
    }

    ///[To get the selected rating]
    SelectedFilterAttribute? ratingAttribute = getSelectedFilterAttribute(
      ratingsKey,
    );
    if (ratingAttribute != null && ratingAttribute.selectedIds.isNotEmpty) {
      rating = Utils.getFilterRatingsValues(
        context: context,
      )[ratingAttribute.selectedIds.first];
    }

    ///[To get the selected price list]
    SelectedFilterAttribute? priceRangeAttribute = getSelectedFilterAttribute(
      priceKey,
    );

    if (priceRangeAttribute != null &&
        priceRangeAttribute.selectedIds.isNotEmpty) {
      ///[Get the min and max price from the selected price range]
      ProductMinMaxPrice productMinMaxPrice = Utils.calculatePriceRanges(
        maxPrice: _selectedTabIndex == 1 ? comboMaxPrice : productMaxPrice,
        minPrice: _selectedTabIndex == 1 ? comboMinPrice : productMinPrice,
      )[priceRangeAttribute.selectedIds.first];

      if (productMinMaxPrice.minPrice != -1) {
        minPrice = productMinMaxPrice.minPrice;
      } else {
        minPrice = _selectedTabIndex == 1 ? comboMinPrice : productMinPrice;
      }
      if (productMinMaxPrice.maxPrice != -1) {
        maxPrice = productMinMaxPrice.maxPrice;
      } else {
        maxPrice = _selectedTabIndex == 1 ? comboMaxPrice : productMaxPrice;
      }
    } else {
      ///[If user has not selected any price range then get the min and max price from the text field]
      if (currentSelectedTextFieldMinPrice.isNotEmpty) {
        minPrice = double.parse(currentSelectedTextFieldMinPrice);
      }
      if (currentSelectedTextFieldMaxPrice.isNotEmpty) {
        maxPrice = double.parse(currentSelectedTextFieldMaxPrice);
      }
    }

    List<SelectedFilterAttribute> restOfFilterAttributes =
        currentSelectedFilterAttributes
            .where(
              (element) =>
                  element.attributeName != categoryKey &&
                  element.attributeName != brandKey &&
                  element.attributeName != discountKey &&
                  element.attributeName != ratingsKey &&
                  element.attributeName != priceKey,
            )
            .toList();

    for (var attribute in restOfFilterAttributes) {
      attributeIds.addAll(attribute.selectedIds);
    }

    return (
      categoryIds: categoryIds,
      brandIds: brandIds,
      sellerId: sellerId,
      discount: discount,
      rating: rating,
      attributeIds: attributeIds,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  ({String? orderBy, String? sortBy, int? topRatedProduct})
      buildSortByParams() {
    String? orderBy;
    String? sortBy;
    int? topRatedProduct;

    ///[Sort by will be set here before fetching the products]
    if (_selectedSortBy == popularityKey) {
      sortBy = "most_popular_products";
    } else if (_selectedSortBy == priceLowToHighKey) {
      orderBy = "asc";
      sortBy = "pv.price";
    } else if (_selectedSortBy == priceHighToLowKey) {
      orderBy = "desc";
      sortBy = "pv.price";
    } else if (_selectedSortBy == topRatedProductKey) {
      topRatedProduct = 1;
    } else if (_selectedSortBy == newArrivalsKey) {
      orderBy = "desc";
      sortBy = 'p.id';
    } else if (_selectedSortBy == discountKey) {
      sortBy = 'discount';
    } else if (_selectedSortBy == allKey) {
      sortBy = null;
      orderBy = null;
      topRatedProduct = null;
    }
    return (orderBy: orderBy, sortBy: sortBy, topRatedProduct: topRatedProduct);
  }

  void getProducts() {
    context.read<ProductsCubit>().getProducts(
          storeId: widget.storeId != null
              ? widget.storeId!
              : context.read<StoresCubit>().getDefaultStore().id!,
          sortBy: sortByParams.sortBy,
          orderBy: sortByParams.orderBy,
          topRatedProduct: sortByParams.topRatedProduct,
          attributeValueIds: filterParams.attributeIds,
          categoryIds: filterParams.categoryIds,
          brandIds: filterParams.brandIds,
          sellerId: filterParams.sellerId,
          discount: filterParams.discount,
          rating: filterParams.rating,
          maxPrice: filterParams.maxPrice,
          minPrice: filterParams.minPrice,
          productIds: widget.productIds,
          isComboProduct: widget.isComboProduct,
          zipcode: zipcode,
        );
  }

  void getComboProducts() {
    if (widget.isExploreScreen ||
        widget.fromSearchScreen ||
        widget.forSellerDetailScreen ||
        widget.sellerProductScreen) {
      context.read<ComboProductsCubit>().getProducts(
            storeId: widget.storeId != null
                ? widget.storeId!
                : context.read<StoresCubit>().getDefaultStore().id!,
            sortBy: sortByParams.sortBy,
            orderBy: sortByParams.orderBy,
            topRatedProduct: sortByParams.topRatedProduct,
            attributeValueIds: filterParams.attributeIds,
            categoryIds: filterParams.categoryIds,
            brandIds: filterParams.brandIds,
            sellerId: filterParams.sellerId,
            discount: filterParams.discount,
            rating: filterParams.rating,
            maxPrice: filterParams.maxPrice,
            minPrice: filterParams.minPrice,
            productIds: widget.comboProductIds,
            isComboProduct: true,
            zipcode: zipcode,
          );
    }
  }

  void loadMoreProducts() {
    context.read<ProductsCubit>().loadMore(
          orderBy: sortByParams.orderBy,
          sortBy: sortByParams.sortBy,
          topRatedProduct: sortByParams.topRatedProduct,
          storeId: widget.storeId != null
              ? widget.storeId!
              : context.read<StoresCubit>().getDefaultStore().id!,
          attributeValueIds: filterParams.attributeIds,
          categoryIds: filterParams.categoryIds,
          brandIds: filterParams.brandIds,
          sellerId: filterParams.sellerId,
          discount: filterParams.discount,
          rating: filterParams.rating,
          minPrice: filterParams.minPrice,
          maxPrice: filterParams.maxPrice,
          productIds: widget.productIds,
          isComboProduct: widget.isComboProduct,
          zipcode: zipcode,
        );
  }

  void loadMoreComboProducts() {
    context.read<ComboProductsCubit>().loadMore(
          orderBy: sortByParams.orderBy,
          sortBy: sortByParams.sortBy,
          topRatedProduct: sortByParams.topRatedProduct,
          storeId: widget.storeId != null
              ? widget.storeId!
              : context.read<StoresCubit>().getDefaultStore().id!,
          attributeValueIds: filterParams.attributeIds,
          categoryIds: filterParams.categoryIds,
          brandIds: filterParams.brandIds,
          sellerId: filterParams.sellerId,
          discount: filterParams.discount,
          rating: filterParams.rating,
          minPrice: filterParams.minPrice,
          maxPrice: filterParams.maxPrice,
          productIds: widget.comboProductIds,
          zipcode: zipcode,
          isComboProduct: true,
        );
  }

  void getSellers() {
    context.read<SellersCubit>().getSellers(
          storeId: context.read<StoresCubit>().getDefaultStore().id!,
        );
  }

  @override
  void dispose() {
    if (_animationController != null) _animationController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProductsCubit, ProductsState>(
          listener: (context, state) async{
            if (state is ProductsFetchSuccess) {
              if (!_productFilterAttributesLoaded) {
                _productFilterAttributes = state.filterAttributes;
                _productFilterAttributesLoaded = true;

                productMinPrice = state.minPrice;
                productMaxPrice = state.maxPrice;
                filterCategoryIds = state.categoryIds;
                filterBrandIds = state.brandIds;
                
                // Fetch categories and brands for products tab
                if (widget.category == null && state.categoryIds != null) {
              final result=  await    CategoryRepository()
        .getCategories(
            storeId:widget. storeId?? context.read<StoresCubit>().getDefaultStore().id!,
          
            categoryIds: state.categoryIds);
                 _productCategories = result.categories;
                }
                if (widget.brandId == null && state.brandIds != null) {
                  final brandResult = await BrandRepository().getBrands(
                    storeId: widget.storeId ?? context.read<StoresCubit>().getDefaultStore().id!,
                    brandIds: state.brandIds,
                  );
                  _productBrands = brandResult.brands;
                }
              }
            }
          },
        ),
        BlocListener<ComboProductsCubit, ComboProductsState>(
          listener: (context, state) async {
            if (state is ComboProductsFetchSuccess) {
              if (!_comboFilterAttributesLoaded) {
                _comboFilterAttributes = state.filterAttributes;
                _comboFilterAttributesLoaded = true;
                
                // Fetch categories and brands for combo products tab
                if (widget.category == null && state.categoryIds != null) {
                  final comboResult = await CategoryRepository()
                      .getCategories(
                          storeId: widget.storeId ?? context.read<StoresCubit>().getDefaultStore().id!,
                          categoryIds: state.categoryIds);
                  _comboCategories = comboResult.categories;
                }
                if (widget.brandId == null && state.brandIds != null) {
                  final comboBrandResult = await BrandRepository().getBrands(
                    storeId: widget.storeId ?? context.read<StoresCubit>().getDefaultStore().id!,
                    brandIds: state.brandIds,
                  );
                  _comboBrands = comboBrandResult.brands;
                }
              }
              comboMinPrice = state.minPrice;
              comboMaxPrice = state.maxPrice;
              comboFilterCategoryIds = state.categoryIds;
              comboFilterBrandIds = state.brandIds;
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        appBar: widget.isExploreScreen ||
                widget.forSellerDetailScreen ||
                widget.fromSearchScreen
            ? null
            : CustomAppbar(
                titleKey: '',
                trailingWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Utils.searchIcon(context),
                    Utils.favoriteIcon(context),
                    Utils.cartIcon(context),
                  ],
                ),
              ),
        body: SafeAreaWithBottomPadding(
          child: Stack(
            children: [
              Column(
                children: [
                 
                    Column(
                      children: <Widget>[
                        if (widget.isExploreScreen ||
                            widget.forSellerDetailScreen ||
                            widget.fromSearchScreen)...[
                          buildSearchBar(),
                           Container(
              height: 8,
              color: Theme.of(context).scaffoldBackgroundColor,
            ),],
                        if (widget.isExploreScreen ||
                          widget.fromSearchScreen ||
                          widget.forSellerDetailScreen ||
                          widget.sellerProductScreen)...[
                          buildTabBarWithChangeProductsStyleButton(), Container(
              height: 8,
              color: Theme.of(context).scaffoldBackgroundColor,
            )]
                      ],
                    ),
                  Expanded(
                    child: _selectedTabIndex == 0
                        ? widget.fromSearchScreen && widget.productIds.isEmpty
                            ? const Center(
                                child: CustomTextContainer(
                                  textKey: dataNotAvailableKey,
                                ),
                              )
                            : BlocConsumer<ProductsCubit, ProductsState>(
                              listener: (context, state) {},
                              builder: (context, state) {
                                if (state is ProductsFetchSuccess) {
                                  return (Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      buildTitle(state.total.toString()),
                                      Flexible(
                                        child: RefreshIndicator(
                                          triggerMode:
                                              RefreshIndicatorTriggerMode.onEdge,
                                          onRefresh: () async {
                                            sortByParams = buildSortByParams();
                                            filterParams = buildFilterParams();
                                            getProducts();
                                          },
                                          child: Padding(
                                             padding: Platform.isIOS
                                                  ? const EdgeInsets.only(
                                                      bottom: 70)
                                                  : const EdgeInsets.only(
                                                      bottom: 0),
                                            child: GridProductsContainer(
                                              loadMoreProducts: loadMoreProducts,
                                              products: state.products,
                                             
                                              hasMore: context
                                                  .read<ProductsCubit>()
                                                  .hasMore(),
                                              fetchMoreError: context
                                                  .read<ProductsCubit>()
                                                  .fetchMoreError(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ));
                                }
                                if (state is ProductsFetchFailure) {
                                  return ErrorScreen(
                                    text: state.errorMessage,
                                    image: state.errorMessage != noInternetKey
                                        ? AppAssets.noOrder
                                        : AppAssets.noInternet,
                                    child: state is ProductsFetchInProgress
                                        ? CustomCircularProgressIndicator(
                                            indicatorColor: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          )
                                        : null,
                                    onPressed: () {
                                      sortByParams = buildSortByParams();
                                      filterParams = buildFilterParams();
                                      getProducts();
                                    },
                                  );
                                }
                                return Center(
                                  child: CustomCircularProgressIndicator(
                                    indicatorColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                );
                              },
                            )
                      : _selectedTabIndex == 1
                          ? widget.fromSearchScreen &&
                                  widget.comboProductIds.isEmpty
                              ?  ErrorScreen(onPressed: (){},text: dataNotAvailableKey,)
                                
                              : BlocBuilder<ComboProductsCubit, ComboProductsState>(
                                  builder: (context, state) {
                                    if (state is ComboProductsFetchSuccess) {
                                      return (RefreshIndicator(
                                        onRefresh: () async {
                                          sortByParams = buildSortByParams();
                                          filterParams = buildFilterParams();
                                          getComboProducts();
                                        },
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            buildTitle(state.total.toString()),
                                            Flexible(
                                              child: Padding(
                                                padding: Platform.isIOS
                                                      ? const EdgeInsets.only(
                                                          bottom: 70)
                                                      : const EdgeInsets.only(
                                                          bottom: 0),
                                                child: GridProductsContainer(
                                                  loadMoreProducts:
                                                      loadMoreComboProducts,
                                                  products: state.products,
                                                 
                                                
                                                  hasMore: context
                                                      .read<ComboProductsCubit>()
                                                      .hasMore(),
                                                  fetchMoreError: context
                                                      .read<ComboProductsCubit>()
                                                      .fetchMoreError(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ));
                                    }
                                    if (state is ComboProductsFetchFailure) {
                                      return ErrorScreen(
                                        text: state.errorMessage,
                                        image: state.errorMessage != noInternetKey
                                            ? AppAssets.noOrder
                                            : AppAssets.noInternet,
                                        child: state is ComboProductsFetchInProgress
                                            ? CustomCircularProgressIndicator(
                                                indicatorColor: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              )
                                            : null,
                                        onPressed: () {
                                          sortByParams = buildSortByParams();
                                          filterParams = buildFilterParams();
                                          getComboProducts();
                                        },
                                      );
                                    }
                                    return Center(
                                      child: CustomCircularProgressIndicator(
                                        indicatorColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    );
                                  },
                                )
                          : BlocBuilder<SellersCubit, SellersState>(
                              builder: (context, state) {
                                if (state is SellersFetchSuccess) {
                                  return RefreshIndicator(
                                    onRefresh: () async {
                                      getSellers();
                                    },
                                    child: Padding(
                                      padding: Platform.isIOS ? const EdgeInsets.only(bottom: 70) : const EdgeInsets.only(bottom: 0),
                                      child: SellersContainer(sellers: state.sellers),
                                    ),
                                  );
                                }
                                if (state is SellersFetchFailure) {
                                  return ErrorScreen(
                                    text: state.errorMessage,
                                    child: state is SellersFetchInProgress
                                        ? CustomCircularProgressIndicator(
                                            indicatorColor: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          )
                                        : null,
                                    onPressed: getSellers,
                                  );
                                }
                                return Center(
                                  child: CustomCircularProgressIndicator(
                                    indicatorColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
                   
             
              buildSortAndFilterContainer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsetsDirectional.only(
          bottom: 6,
          top: MediaQuery.of(context).padding.top + 8,
          start: appContentHorizontalPadding,
          end: appContentHorizontalPadding,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.fromSearchScreen) ...[
              IconButton(
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -4,
                ),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back),
                onPressed: Navigator.of(context).pop,
              ),
            ],
            Expanded(
              child: CustomSearchContainer(
                textEditingController: _searchController,
                autoFocus: false,
                readOnly: true,
                onChanged: (v) {
                  _searchController.text = v;
                },
                onVoiceIconTap: setState,
                onTap: () => Utils.navigateToScreen(
                  context,
                  Routes.searchScreen,
                  arguments: widget.title,
                  replacePrevious: widget.fromSearchScreen,
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget buildTabBarWithChangeProductsStyleButton() {
    return Container(
            color: Theme.of(context).colorScheme.primaryContainer,
           
            child: CustomTabbar(
              currentPage: _selectedTabIndex,
              textStyle: Theme.of(context).textTheme.bodyLarge,
              
              tabTitles: _tabs,
              padding: 2,
              onTapTitle: (index) {
                _selectedTabIndex = index;
                setState(() {});
                if (_animationController != null) {
                  if (_selectedTabIndex == 2) {
                    _animationController!.forward();
                  } else {
                    _animationController!.reverse();
                  }
                }
              },
            ),
    );
  }

  /// Check if any sorting is applied (not default "all")
  bool get isSortingActive => _selectedSortBy != allKey;
  
  /// Check if any filters are applied
  bool get isFilteringActive => 
      currentSelectedFilterAttributes.isNotEmpty || 
      currentSelectedTextFieldMinPrice.isNotEmpty || 
      currentSelectedTextFieldMaxPrice.isNotEmpty;

  /// Count the number of active filters
  int get activeFiltersCount {
    int count = 0;
    
    // Count individual selected values from each filter attribute
    for (var filterAttribute in currentSelectedFilterAttributes) {
      count += filterAttribute.selectedIds.length;
    }
    
    // Count custom price range only if user has set values different from defaults
    bool hasCustomMinPrice = currentSelectedTextFieldMinPrice.isNotEmpty && 
        double.tryParse(currentSelectedTextFieldMinPrice) != (_selectedTabIndex == 1 ? comboMinPrice : productMinPrice);
    bool hasCustomMaxPrice = currentSelectedTextFieldMaxPrice.isNotEmpty && 
        double.tryParse(currentSelectedTextFieldMaxPrice) != (_selectedTabIndex == 1 ? comboMaxPrice : productMaxPrice);
    
    if (hasCustomMinPrice || hasCustomMaxPrice) {
      count += 1;
    }
    
    return count;
  }

  /// Create a badge widget for displaying counts
  Widget _buildBadge(int count,Widget child) {
    
    
    return Badge(
      
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            textColor: Theme.of(context).colorScheme.onPrimary,
                            isLabelVisible:count==0?false: true
                                ,
                            label: Text(
          count.toString(),
    
          style: TextStyle(
            color: Theme.of(context).colorScheme.onError,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          )),child: child,);
    
 
  }

  Widget buildSortAndFilterContainer() {
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, state) {
        if (state is ProductsFetchSuccess || state is ProductsFetchFailure) {
          return Stack(
            children: [
              _animationController == null
                  ? SizedBox.shrink()
                  : AnimatedBuilder(
                      animation: _animationController!,
                      builder: (context, child) {
                        return Positioned(
                          bottom:Platform.isIOS? (MediaQuery.of(context).padding.bottom +
                              ((-60) * (_animationController!.value))): ((-60) * (_animationController!.value)),
                          child: child!,
                          left: 0,
                          right: 0,
                        );
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 50,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: blackColor.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 0),
                            ),
                          ],
                          color: Theme.of(context).colorScheme.primaryContainer,
                        ),
                        child: Stack(
                          children: [
                            SizedBox(
                              height: 50,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        GestureDetector(
                                          onTap: () => {
                                            Utils.openModalBottomSheet(
                                              context,
                                              Column(
                                                children: [
                                                  SortProductBottomSheet(
                                                    onSortBySelected: changeSortBy,
                                                    selectedSortBy: _selectedSortBy,
                                                  ),
                                                  CustomBottomButtonContainer(
                                                    child: Row(
                                                      children: <Widget>[
                                                        Expanded(
                                                          child:
                                                              CustomRoundedButton(
                                                            widthPercentage: 0.4,
                                                            buttonTitle:
                                                                clearFiltersKey,
                                                            showBorder: true,
                                                            backgroundColor:
                                                                Theme.of(context)
                                                                    .colorScheme
                                                                    .onPrimary,
                                                            borderColor: Theme.of(
                                                              context,
                                                            ).hintColor,
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .bodyMedium!
                                                                .copyWith(
                                                                  color: Theme.of(
                                                                    context,
                                                                  )
                                                                      .colorScheme
                                                                      .secondary,
                                                                ),
                                                            onTap: () {
                                                             _selectedSortBy =
                                                                  allKey;
                                                              // Clear current tab's filters
                                                              if (_selectedTabIndex == 1) {
                                                                comboSelectedFilterAttributes.clear();
                                                                comboSelectedTextFieldMinPrice = '';
                                                                comboSelectedTextFieldMaxPrice = '';
                                                              } else {
                                                                productSelectedFilterAttributes.clear();
                                                                productSelectedTextFieldMinPrice = '';
                                                                productSelectedTextFieldMaxPrice = '';
                                                              }
                                                              sortByParams =
                                                                  buildSortByParams();
                                                              filterParams = buildFilterParams();
                                                              // Call only the current tab's API
                                                              if (_selectedTabIndex == 1) {
                                                                getComboProducts();
                                                              } else {
                                                                getProducts();
                                                              }
                                                              Navigator.of(
                                                                context,
                                                              ).pop();
                                                            },
                                                          ),
                                                        ),
                                                        const SizedBox(width: 16),
                                                        Expanded(
                                                          child:
                                                              CustomRoundedButton(
                                                            widthPercentage: 0.4,
                                                            buttonTitle: applyKey,
                                                            showBorder: false,
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .bodyMedium!
                                                                .copyWith(
                                                                  color: Theme.of(
                                                                    context,
                                                                  )
                                                                      .colorScheme
                                                                      .onPrimary,
                                                                ),
                                                            onTap: () {
                                                              sortByParams =
                                                                  buildSortByParams();

                                                              // Call only the current tab's API
                                                              if (_selectedTabIndex == 1) {
                                                                getComboProducts();
                                                              } else {
                                                                getProducts();
                                                              }
                                                              Navigator.of(
                                                                context,
                                                              ).pop();
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              isScrollControlled: false,
                                              staticContent: true,
                                            ),
                                          },
                                          child: Container(
                                            height: 50,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                 _buildBadge(
                                                    isSortingActive ? 1 : 0,Icon(Icons.import_export)),
                                                
                                                const SizedBox(width: 5.0),
                                                CustomTextContainer(
                                                  textKey: sortKey,
                                                  style: Theme.of(context).textTheme.bodyLarge,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                       
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            Get.toNamed(
                                              Routes.productFiltersScreen,
                                              arguments: ProductFiltersScreen
                                                  .buildArguments(
                                                selctedMaxPrice:
                                                    currentSelectedTextFieldMaxPrice,
                                                selctedMinPrice:
                                                    currentSelectedTextFieldMinPrice,
                                                selectedFilterAttributes:
                                                    currentSelectedFilterAttributes,
                                                filterAttributes: currentFilterAttributes,
                                                maxPrice: _selectedTabIndex == 1
                                                    ? comboMaxPrice
                                                    : productMaxPrice,
                                                minPrice: _selectedTabIndex == 1
                                                    ? comboMinPrice
                                                    : productMinPrice,
                                                totalProducts:
                                                    state is ProductsFetchSuccess
                                                        ? state.total
                                                        : 0,
                                                category: widget.category,
                                                brandId: widget.brandId,
                                                categoryIds: _selectedTabIndex == 1
                                                    ? comboFilterCategoryIds
                                                    : filterCategoryIds,
                                                brandIds: _selectedTabIndex == 1
                                                    ? comboFilterBrandIds
                                                    : filterBrandIds,
                                                categories: currentCategories,
                                                brands: currentBrands,
                                              ),
                                            )?.then((value) {
                                              if (value != null) {
                                                final result = (value)
                                                    as ProductFiltersScreenResult;

                                                // Save filters to the correct tab-specific variables
                                                if (_selectedTabIndex == 1) {
                                                  // Combo products tab
                                                  comboSelectedFilterAttributes =
                                                      result.filterAttributes;
                                                  comboSelectedTextFieldMinPrice =
                                                      result.minPrice;
                                                  comboSelectedTextFieldMaxPrice =
                                                      result.maxPrice;
                                                } else {
                                                  // Products tab
                                                  productSelectedFilterAttributes =
                                                      result.filterAttributes;
                                                  productSelectedTextFieldMinPrice =
                                                      result.minPrice;
                                                  productSelectedTextFieldMaxPrice =
                                                      result.maxPrice;
                                                }
                                                filterParams = buildFilterParams();
                                                setState(() {});
                                                // Call only the current tab's API
                                                if (_selectedTabIndex == 1) {
                                                  getComboProducts();
                                                } else {
                                                  getProducts();
                                                }
                                              }
                                            });
                                          },
                                          child: Container(
                                            height: 50,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                  _buildBadge(activeFiltersCount,
                                                    Icon(Icons.filter_list)),
                                                const SizedBox(width: 5.0),
                                                CustomTextContainer(
                                                  textKey: filterKey,
                                                  style: Theme.of(context).textTheme.bodyLarge,
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
                            ),
                            Center(
                              child: Container(
                                width: 1,
                                height: 20,
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondary.withValues(alpha: 0.26),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  buildTitle(String totalProducts) {
    if (!widget.isExploreScreen &&
        !widget.forSellerDetailScreen &&
        !widget.fromSearchScreen)
      return Padding(
        padding: const EdgeInsetsDirectional.all( appContentHorizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
      
            CustomTextContainer(
              textKey: widget.category != null
                  ? widget.category!.name
                  : widget.title != null
                      ? widget.title!
                      : '',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: 0.67),
                    ),
                children: [
                  TextSpan(text: totalProducts),
                  const TextSpan(text: " "),
                  TextSpan(
                    text: context
                        .read<SettingsAndLanguagesCubit>()
                        .getTranslatedValue(labelKey: productsKey),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
           
          ],
        ),
      );
    else
      return const SizedBox.shrink();
  }
}
