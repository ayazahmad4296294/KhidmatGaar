class ServiceProviderModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String address;
  final String serviceType;
  final double rating;
  final bool isVerified;
  final bool isAvailable;
  final List<String> certificates;
  final String experience;
  final double hourlyRate;
  final double monthlyRate;

  ServiceProviderModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.serviceType,
    this.rating = 0.0,
    this.isVerified = false,
    this.isAvailable = true,
    this.certificates = const [],
    required this.experience,
    required this.hourlyRate,
    required this.monthlyRate,
  });

  factory ServiceProviderModel.fromMap(Map<String, dynamic> map) {
    return ServiceProviderModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      serviceType: map['serviceType'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      isVerified: map['isVerified'] ?? false,
      isAvailable: map['isAvailable'] ?? true,
      certificates: List<String>.from(map['certificates'] ?? []),
      experience: map['experience'] ?? '',
      hourlyRate: (map['hourlyRate'] ?? 0.0).toDouble(),
      monthlyRate: (map['monthlyRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'serviceType': serviceType,
      'rating': rating,
      'isVerified': isVerified,
      'isAvailable': isAvailable,
      'certificates': certificates,
      'experience': experience,
      'hourlyRate': hourlyRate,
      'monthlyRate': monthlyRate,
    };
  }
}
