enum CategoryStyle {
  style1,
  style2,
  style3,
}

// --- 2. Helper Extension to convert String to Enum ---
// This is a safe and clean way to get the enum value from a string
// coming from your data source (e.g., a backend API).
extension CategoryStyleExtension on String {
  CategoryStyle toCategoryStyle() {
    switch (this) {
      case 'category_style_1':
        return CategoryStyle.style1;
      case 'category_style_2':
        return CategoryStyle.style2;
      case 'category_style_3':
        return CategoryStyle.style3;
      default:

        return CategoryStyle.style1;
    }
  }
}

enum CategoryCardStyle {
  style1,
  style2,
  style3,
}

extension CategoryCardStyleExtension on String {
  CategoryCardStyle toCategoryCardStyle() {
    switch (this) {
      case 'category_card_style_1':
        return CategoryCardStyle.style1;
      case 'category_card_style_2':
        return CategoryCardStyle.style2;
      case 'category_card_style_3':
        return CategoryCardStyle.style3;
      default:
        return CategoryCardStyle.style1;
    }
  }
}

enum CardStyle {
  style1,
  style2,
  style3,
}
extension CardStyleExtension on String {
  CardStyle toCardStyle() {
    switch (this) {
      case 'style_1':
        return CardStyle.style1;
      case 'style_2':
        return CardStyle.style2;
      case 'style_3':
        return CardStyle.style3;
      default:

        return CardStyle.style1;
    }
  }
}

enum BrandStyle {
  style1,
  style2,
  style3,
}
extension BrandStyleExtension on String {
  BrandStyle toBrandStyle() {
    switch (this) {
      case 'brands_style_1':
        return BrandStyle.style1;
      case 'brands_style_2':
        return BrandStyle.style2;
      case 'brands_style_3':
        return BrandStyle.style3;
      default:
    
        return BrandStyle.style1;
    }
  }
}


enum HeaderStyle {
  style1,
  style2,
  style3,
}
extension HeaderStyleExtension on String {
  HeaderStyle toHeaderStyle() {
    switch (this) {
      case 'header_style_1':
        return HeaderStyle.style1;
      case 'header_style_2':
        return HeaderStyle.style2;
      case 'header_style_3':
        return HeaderStyle.style3;
      default:
    
        return HeaderStyle.style1;
    }
  }
}

enum SliderStyle {
  style1,
  style2,
  style3,
  style4,
  style5
}
extension SliderStyleExtension on String {
  SliderStyle toSliderStyle() {
    switch (this) {
      case 'slider_style_1':
        return SliderStyle.style1;
      case 'slider_style_2':
        return SliderStyle.style2;
      case 'slider_style_3':
        return SliderStyle.style3;
         case 'slider_style_4':
        return SliderStyle.style4;
          case 'slider_style_5':
        return SliderStyle.style5;
      default:
    
        return SliderStyle.style1;
    }
  }
}
