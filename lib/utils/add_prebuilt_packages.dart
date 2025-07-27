import 'package:cloud_firestore/cloud_firestore.dart';

// This is a utility script to add pre-built packages to Firestore
class AddPreBuiltPackages {
  static Future<void> addPackages() async {
    final firestore = FirebaseFirestore.instance;
    final prebuiltPackagesCollection =
        firestore.collection('prebuilt_packages');

    // First, check if packages already exist
    final existingDocs = await prebuiltPackagesCollection.get();
    if (existingDocs.docs.isNotEmpty) {
      print('Pre-built packages already exist. Skipping addition.');
      return;
    }

    // Define packages
    final packages = [
      {
        'name': 'Home Essentials',
        'description':
            'Essential services for your home covering cleaning, cooking, and basic maintenance.',
        'includedServices': ['Maid', 'Cook', 'Gardener'],
        'price': 7000.0,
        'durationMonths': 1,
        'discount': 10.0, // 10% discount
        'imageUrl':
            'https://images.unsplash.com/photo-1503424886307-b090341d25d1',
      },
      {
        'name': 'Premium Home Package',
        'description':
            'Complete home care package with premium services including personal chef and security.',
        'includedServices': ['Maid', 'Chef', 'Security Guard', 'Gardener'],
        'price': 12000.0,
        'durationMonths': 2,
        'discount': 15.0, // 15% discount
        'imageUrl':
            'https://images.unsplash.com/photo-1513694203232-719a280e022f',
      },
      {
        'name': 'Family Care',
        'description':
            'Perfect for families with children. Includes babysitting, cooking, and home cleaning.',
        'includedServices': ['Maid', 'Cook', 'Baby Care Taker'],
        'price': 9000.0,
        'durationMonths': 1,
        'discount': 8.0, // 8% discount
        'imageUrl':
            'https://images.unsplash.com/photo-1581578731548-c64695cc6952',
      },
      {
        'name': 'Executive Package',
        'description':
            'For busy professionals. Includes driver, security, and home maintenance services.',
        'includedServices': ['Driver', 'Security Guard', 'Maid'],
        'price': 9500.0,
        'durationMonths': 1,
        'discount': 12.0, // 12% discount
        'imageUrl': 'https://images.unsplash.com/photo-1562157873-818bc0726f68',
      },
      {
        'name': 'Complete Home Services - 3 Months',
        'description':
            'A comprehensive package with all essential home services for 3 months at an excellent discount.',
        'includedServices': [
          'Maid',
          'Cook',
          'Gardener',
          'Handyman',
          'Security Guard'
        ],
        'price': 16000.0,
        'durationMonths': 3,
        'discount': 20.0, // 20% discount
        'imageUrl':
            'https://images.unsplash.com/photo-1507089947368-19c1da9775ae',
      },
    ];

    // Add packages to Firestore
    for (final package in packages) {
      await prebuiltPackagesCollection.add(package);
    }

    print(
        'Successfully added ${packages.length} pre-built packages to Firestore.');
  }
}
