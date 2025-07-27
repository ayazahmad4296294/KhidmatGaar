import 'package:flutter/material.dart';
import '../utils/sample_data_util.dart';

/// This widget is for development purposes only
/// It provides a button to seed the database with sample data
class SeedDataButton extends StatefulWidget {
  const SeedDataButton({Key? key}) : super(key: key);

  @override
  State<SeedDataButton> createState() => _SeedDataButtonState();
}

class _SeedDataButtonState extends State<SeedDataButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Opacity(
        opacity: 0.7,
        child: FloatingActionButton(
          backgroundColor: Colors.grey[800],
          onPressed: _isLoading ? null : _seedDatabase,
          tooltip: 'Seed Database (Dev Only)',
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Icon(Icons.data_array),
        ),
      ),
    );
  }

  Future<void> _seedDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await SampleDataUtil.addSampleSpecialOffers();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sample special offers added to database'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error seeding database: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
