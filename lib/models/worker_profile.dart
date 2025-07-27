class WorkerProfile {
  final String name;
  final String image;
  final String experience;
  final int completedJobs;
  final double rating;
  final List<String> preferredLocations;
  final String description;
  final String service;

  const WorkerProfile({
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
