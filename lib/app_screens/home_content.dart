import 'package:flutter/material.dart';
import '../services_for_users/on_demand.dart';
import '../services_for_users/monthly_hiring.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../widgets/recent_bookings_widget.dart';
import '../services/special_offers_service.dart';
import '../models/special_offer.dart';
//import '../utils/icon_helper.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String? selectedService;
  double workerRating = 5.0; // Worker rating filter
  String searchQuery = '';
  List<String> filteredServices = [];
  bool isSearching = false;
  bool hasActiveFilters = false;
  // Add FocusNode for the search field
  final FocusNode _searchFocusNode = FocusNode();

  // Special offers
  final SpecialOffersService _specialOffersService = SpecialOffersService();
  List<SpecialOffer> _specialOffers = [];
  bool _isLoadingOffers = false;
  String? _offersError;

  final List<String> _services = [
    'Security Guard',
    'Driver',
    'Maid',
    'Gardener',
    'Handyman',
    'Locksmith',
    'Auto Mechanic',
    'Chef',
    'Baby Care Taker',
  ]..sort();

  @override
  void initState() {
    super.initState();
    filteredServices = [];
    _loadSpecialOffers();
  }

  @override
  void dispose() {
    // Dispose the focus node when the widget is disposed
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialOffers() async {
    setState(() {
      _isLoadingOffers = true;
      _offersError = null;
    });

    try {
      final offers = await _specialOffersService.getSpecialOffers();

      if (mounted) {
        setState(() {
          _specialOffers = offers;
          _isLoadingOffers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _offersError = 'Failed to load special offers';
          _isLoadingOffers = false;
        });
      }
      print('Error loading special offers: $e');
    }
  }

  void filterServices(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredServices = [];
        isSearching = false;
      } else {
        isSearching = true;
        filteredServices = _services
            .where((service) =>
                service.toLowerCase().contains(query.toLowerCase()))
            .toList();

        // Apply additional filters if they're active
        if (hasActiveFilters) {
          applyAdditionalFilters();
        }
      }
    });
  }

  void applyAdditionalFilters() {
    // Apply service type filter (if needed in future)
    if (selectedService != null) {
      filteredServices = filteredServices
          .where((service) => service == selectedService)
          .toList();
    }
  }

  void applyFilters() {
    setState(() {
      // Include worker rating in active filters check
      hasActiveFilters = selectedService != null || workerRating > 0;

      // If search is active, reapply the search with new filters
      if (searchQuery.isNotEmpty) {
        filterServices(searchQuery);
      }
    });
  }

  void resetFilters() {
    setState(() {
      selectedService = null;
      workerRating = 3.0;
      hasActiveFilters = false;

      // Reapply search if active
      if (searchQuery.isNotEmpty) {
        filterServices(searchQuery);
      }
    });
  }

  void navigateToService(String service) {
    // Dismiss keyboard if it's showing
    _searchFocusNode.unfocus();

    // Reset search
    setState(() {
      searchQuery = '';
      isSearching = false;
      filteredServices = [];
    });

    // Navigate to service page with filter
    Map<String, dynamic> filters = {
      'service': service,
    };

    // Add worker rating filter
    if (workerRating > 0) {
      filters['minRating'] = workerRating;
    }

    // Check if service is available in monthly hiring or on-demand
    // Services in monthly hiring
    final List<String> monthlyServices = [
      'Baby Care Taker',
      'Cook',
      'Driver',
      'Gardener',
      'Maid',
      'Security Guard',
    ];

    // Navigate to the appropriate service page based on service type
    if (monthlyServices.contains(service)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MonthlyHiringService(filters: filters),
          settings: RouteSettings(arguments: {'filters': filters}),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnDemandService(filters: filters),
          settings: RouteSettings(arguments: {'filters': filters}),
        ),
      );
    }
  }

  void browseAllServices(String serviceType) {
    // Dismiss keyboard if it's showing
    _searchFocusNode.unfocus();

    Map<String, dynamic>? filters;

    // Apply filters if active
    if (hasActiveFilters) {
      filters = {};

      if (selectedService != null) {
        filters['service'] = selectedService;
      }

      // Add worker rating filter
      if (workerRating > 0) {
        filters['minRating'] = workerRating;
      }
    }

    if (serviceType == 'on-demand') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnDemandService(filters: filters),
          settings: RouteSettings(arguments: {'filters': filters}),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MonthlyHiringService(filters: filters),
          settings: RouteSettings(arguments: {'filters': filters}),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Dismiss keyboard when tapping outside the TextField
      onTap: () {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      },
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.grey[400]!,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        focusNode: _searchFocusNode,
                        onChanged: filterServices,
                        decoration: InputDecoration(
                          hintText: 'Search services...',
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.black),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      searchQuery = '';
                                      filteredServices = [];
                                      isSearching = false;
                                      // Clear focus when clearing search
                                      _searchFocusNode.unfocus();
                                    });
                                  },
                                )
                              : null,
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: hasActiveFilters ? Colors.green : Colors.purple,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.tune,
                              color: Colors.white, size: 20),
                          onPressed: _showFilterDialog,
                        ),
                        if (hasActiveFilters)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Active Filters
            if (hasActiveFilters)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (selectedService != null)
                        _buildFilterChip(
                          selectedService!,
                          Icons.work,
                          () {
                            setState(() {
                              selectedService = null;
                              applyFilters();
                            });
                          },
                        ),
                      if (workerRating > 0)
                        _buildFilterChip(
                          '${workerRating.toStringAsFixed(1)}★ Rating',
                          Icons.star,
                          () {
                            setState(() {
                              workerRating = 0;
                              applyFilters();
                            });
                          },
                        ),
                      TextButton(
                        onPressed: resetFilters,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                ),
              ),

            // Search Results
            if (isSearching && filteredServices.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredServices.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final service = filteredServices[index];
                    IconData serviceIcon = _getServiceIcon(service);
                    Color serviceColor = _getServiceColor(service);

                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: serviceColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          serviceIcon,
                          color: serviceColor,
                          size: 20,
                        ),
                      ),
                      title: Text(service),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => navigateToService(service),
                    );
                  },
                ),
              ),

            // Rest of content (only show if not searching or no results)
            if (!isSearching || filteredServices.isEmpty) ...[
              // Image Slider
              CarouselSlider(
                options: CarouselOptions(
                  height: 180.0,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  aspectRatio: 16 / 9,
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enableInfiniteScroll: true,
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  viewportFraction: 0.8,
                ),
                items: [
                  'assets/slider1.jpg',
                  'assets/slider2.jpg',
                  'assets/slider3.jpg',
                  'assets/slider4.jpg',
                ].map((item) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: DecorationImage(
                            image: AssetImage(item),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),

              // Services Grid
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Our Services',
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildServiceButton(
                            context,
                            'On Demand\nServices',
                            Icons.flash_on,
                            () => browseAllServices('on-demand'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildServiceButton(
                            context,
                            'Monthly\nHiring',
                            Icons.calendar_month,
                            () => browseAllServices('monthly'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Special Offers Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Special Offers',
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Show loading indicator while fetching offers
                    if (_isLoadingOffers)
                      const Center(
                        child: CircularProgressIndicator(color: Colors.purple),
                      )
                    // Show error message if there was an error
                    else if (_offersError != null)
                      Center(
                        child: Text(
                          _offersError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    // Show message if no offers found
                    else if (_specialOffers.isEmpty)
                      const Center(
                        child: Column(
                          children: [
                            Icon(Icons.local_offer,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'No special offers available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    // Show offers list
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: _specialOffers.map((offer) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: _buildOfferCard(offer),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Recent History Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecentBookingsWidget(
                      onViewAll: () {
                        // Navigate to bookings tab
                        Navigator.of(context).pushNamed('/user-bookings');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        backgroundColor: Colors.grey[200],
        label: Text(label),
        avatar: Icon(icon, size: 16),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildServiceButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.black),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(SpecialOffer offer) {
    // Use a fixed width for all offers based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth =
        screenWidth < 360 ? 160.0 : 200.0; // Adjust width for smaller screens

    return Container(
      key: ValueKey(offer.id), // Add a key for proper rebuilding
      width: cardWidth,
      height: 220, // Increase height to accommodate content
      padding: const EdgeInsets.all(12), // Reduce padding slightly
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max, // Take all available space
        children: [
          // Icon or image with fixed height
          SizedBox(
            height: 40, // Reduce height slightly
            child: offer.imageUrl.isNotEmpty
                ? Image.network(
                    offer.imageUrl,
                    height: 40,
                    width: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.local_offer,
                        size: 24,
                        color: Colors.purple),
                  )
                : const Icon(Icons.local_offer, size: 24, color: Colors.purple),
          ),
          const SizedBox(height: 6), // Reduce spacing
          // Title with fixed height
          SizedBox(
            height: 38,
            child: Text(
              offer.title,
              style: const TextStyle(
                fontSize: 15, // Slightly smaller font
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2), // Reduce spacing
          // Discount with fixed style and size
          Text(
            "${offer.discount}% OFF",
            style: const TextStyle(
              fontSize: 18, // Slightly smaller font
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 2), // Reduce spacing
          // Description with fixed height
          SizedBox(
            height: 36,
            child: Text(
              offer.description,
              style: TextStyle(
                fontSize: 11, // Smaller font for description
                color: Colors.grey[600],
              ),
              maxLines: 3, // Allow one more line
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(), // Push remaining content to bottom
          // Valid until date
          Text(
            "Valid until: ${_formatDate(offer.validUntil)}",
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          if (offer.code.isNotEmpty) ...[
            const SizedBox(height: 2), // Reduce spacing
            // Container for code with warning stripes
            Container(
              width: double.infinity,
              height: 20, // Fixed height for consistency
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.yellow.shade100,
                    Colors.yellow.shade200,
                  ],
                  stops: const [0.85, 0.85], // Creates a stripe effect
                  tileMode: TileMode.repeated,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                    color: Colors.yellow.shade800,
                    width: 1,
                    style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                // Center the content
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center, // Center the row
                  children: [
                    Text(
                      "Code: ",
                      style: TextStyle(
                        fontSize: 9, // Smaller font size
                        color: Colors.grey[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        offer.code,
                        style: TextStyle(
                          fontSize: 9, // Smaller font size
                          color: Colors.grey[800],
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Format date to show Month day, year
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showFilterDialog() {
    // Dismiss keyboard if it's showing
    _searchFocusNode.unfocus();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            contentPadding: const EdgeInsets.all(20),
            title: const Row(
              children: [
                Icon(Icons.filter_list, size: 24, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Filter Services',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Type Filter
                  const Text(
                    'Service Type',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedService,
                        hint: const Text('Select Service'),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: _services
                            .map((service) => DropdownMenuItem(
                                  value: service,
                                  child: Text(service),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => selectedService = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Worker Rating Filter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Minimum Worker Rating',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          Text(
                            ' ${workerRating.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.amber,
                        inactiveTrackColor: Colors.amber.withOpacity(0.3),
                        thumbColor: Colors.amber,
                        overlayColor: Colors.amber.withOpacity(0.4),
                        valueIndicatorColor: Colors.amber,
                        valueIndicatorTextStyle: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      child: Slider(
                        min: 0,
                        max: 5,
                        divisions: 10,
                        value: workerRating,
                        label: workerRating.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() => workerRating = value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedService = null;
                    workerRating = 3.0;
                  });
                },
                child: Text(
                  'Reset',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              FilledButton(
                onPressed: () {
                  // Apply filters
                  this.setState(() {
                    applyFilters();
                  });
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.purple,
                ),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getServiceIcon(String title) {
    switch (title) {
      case 'Maid':
        return Icons.cleaning_services;
      case 'Cook':
        return Icons.restaurant;
      case 'Driver':
        return Icons.drive_eta;
      case 'Security Guard':
        return Icons.security;
      case 'Gardener':
        return Icons.grass;
      case 'Baby Care Taker':
        return Icons.child_care;
      case 'Handyman':
        return Icons.handyman;
      case 'Locksmith':
        return Icons.lock;
      case 'Auto Mechanic':
        return Icons.car_repair;
      case 'Chef':
        return Icons.restaurant;
      default:
        return Icons.work;
    }
  }

  Color _getServiceColor(String title) {
    switch (title) {
      case 'Maid':
        return Colors.teal;
      case 'Cook':
        return Colors.orange;
      case 'Driver':
        return Colors.blue;
      case 'Security Guard':
        return Colors.red;
      case 'Gardener':
        return Colors.green;
      case 'Baby Care Taker':
        return Colors.purple;
      case 'Handyman':
        return Colors.orange;
      case 'Locksmith':
        return Colors.grey;
      case 'Auto Mechanic':
        return Colors.blue;
      case 'Chef':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
