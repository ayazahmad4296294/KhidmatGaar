import '../models/product.dart';

class SearchService {
  List<Product> searchProducts(
    List<Product> products,
    String query, {
    String? location,
    double? minRating,
    double? maxPrice,
  }) {
    return products.where((product) {
      bool matchesQuery = query.isEmpty ||
          product.name.toLowerCase().contains(query.toLowerCase()) ||
          product.description.toLowerCase().contains(query.toLowerCase());

      bool matchesLocation = location == null ||
          product.location.toLowerCase().contains(location.toLowerCase());

      bool matchesRating = minRating == null || product.rating >= minRating;

      bool matchesPrice = maxPrice == null || product.price <= maxPrice;

      return matchesQuery && matchesLocation && matchesRating && matchesPrice;
    }).toList();
  }

  List<Product> filterProducts(
    List<Product> products, {
    String? category,
    double? minPrice,
    double? maxPrice,
  }) {
    return products.where((product) {
      bool categoryMatch = category == null || product.category == category;
      bool priceMatch = (minPrice == null || product.price >= minPrice) &&
          (maxPrice == null || product.price <= maxPrice);

      return categoryMatch && priceMatch;
    }).toList();
  }
}
