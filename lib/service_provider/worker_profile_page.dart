import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../chat/start_chat_button.dart';
import '../services/review_service.dart';
import '../services/worker_service.dart';
import '../models/review.dart';

class WorkerProfile {
  final String id;
  final String name;
  final String image;
  final String experience;
  final int completedJobs;
  final double rating;
  final List<String> preferredLocations;
  final String description;
  final String service;

  const WorkerProfile({
    required this.id,
    required this.name,
    required this.image,
    required this.experience,
    required this.completedJobs,
    required this.rating,
    required this.preferredLocations,
    required this.description,
    required this.service,
  });
}

class WorkerProfilePage extends StatefulWidget {
  final WorkerProfile worker;

  const WorkerProfilePage({
    super.key,
    required this.worker,
  });

  @override
  State<WorkerProfilePage> createState() => _WorkerProfilePageState();
}

class _WorkerProfilePageState extends State<WorkerProfilePage> {
  final ReviewService _reviewService = ReviewService();
  final WorkerService _workerService = WorkerService();
  bool _isLoadingReviews = true;
  List<Review> _reviews = [];
  int _completedJobs = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadCompletedJobsCount();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await _reviewService.getWorkerReviews(widget.worker.id);
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      print('Error loading reviews: $e');
      setState(() {
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _loadCompletedJobsCount() async {
    try {
      print(
          'Fetching latest completed jobs count for worker: ${widget.worker.id}');
      final count =
          await _workerService.getCompletedJobsCount(widget.worker.id);
      print('Fetched completed jobs count: $count');
      setState(() {
        _completedJobs = count;
      });
    } catch (e) {
      print('Error loading completed jobs count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Profile'),
        actions: [
          StartChatButton(
            workerId: widget.worker.id,
            workerName: widget.worker.name,
            isIconButton: true,
          ),
        ],
        backgroundColor: Colors.purple.shade50,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.purple),
        titleTextStyle: const TextStyle(
          color: Colors.purple,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                image: DecorationImage(
                  image: NetworkImage(widget.worker.image),
                  fit: BoxFit.cover,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          widget.worker.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.worker.service,
                          style: const TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[700], size: 18),
                      const SizedBox(width: 4),
                      Text(
                        widget.worker.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '  (${_reviews.length} reviews)',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _profileSectionTitle('Experience'),
                  const SizedBox(height: 4),
                  Text(
                    widget.worker.experience,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.work, color: Colors.purple.shade200, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '$_completedJobs Jobs Completed',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _profileSectionTitle('Preferred Locations'),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.worker.preferredLocations
                        .map(
                          (location) => Chip(
                            label: Text(location),
                            backgroundColor: Colors.purple.shade50,
                            labelStyle: const TextStyle(color: Colors.purple),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  _profileSectionTitle('About'),
                  const SizedBox(height: 4),
                  Text(
                    widget.worker.description,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _profileSectionTitle('Customer Reviews'),
                  const SizedBox(height: 8),
                  _isLoadingReviews
                      ? const Center(
                          child:
                              CircularProgressIndicator(color: Colors.purple))
                      : _reviews.isEmpty
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.purple.shade100!),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.star_border,
                                      size: 36,
                                      color: Colors.purple,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No reviews yet',
                                      style: TextStyle(
                                        color: Colors.purple,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                ..._reviews
                                    .take(3)
                                    .map((review) => _buildReviewItem(review))
                                    .toList(),
                                if (_reviews.length > 3)
                                  TextButton.icon(
                                    icon: const Icon(Icons.list,
                                        color: Colors.purple),
                                    label: Text(
                                      'View All ${_reviews.length} Reviews',
                                      style:
                                          const TextStyle(color: Colors.purple),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Viewing all reviews will be available soon'),
                                          ),
                                        );
                                      });
                                    },
                                  ),
                              ],
                            ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.purple,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildReviewItem(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.purple,
                    child: Icon(Icons.person, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    review.customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Text(
                DateFormat('MMM d, yyyy').format(review.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < review.rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 18,
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: TextStyle(
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Service: ${review.serviceType}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
