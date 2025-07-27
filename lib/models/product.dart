import 'worker.dart';

class Product {
  final String name;
  final String description;
  final String category;
  final double price;
  final String location;
  final double rating;
  final List<Worker> workers;
  final String serviceType;

  Product({
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.location,
    required this.rating,
    required this.serviceType,
    this.workers = const [],
  });
}
