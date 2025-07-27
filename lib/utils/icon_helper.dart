import 'package:flutter/material.dart';

class IconHelper {
  static IconData getIconFromName(String iconName) {
    switch (iconName) {
      case 'security':
        return Icons.security;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'drive_eta':
        return Icons.drive_eta;
      case 'restaurant':
        return Icons.restaurant;
      case 'grass':
        return Icons.grass;
      case 'child_care':
        return Icons.child_care;
      case 'handyman':
        return Icons.handyman;
      case 'lock':
        return Icons.lock;
      case 'car_repair':
        return Icons.car_repair;
      case 'home_repair_service':
        return Icons.home_repair_service;
      case 'discount':
        return Icons.discount;
      case 'local_offer':
        return Icons.local_offer;
      case 'payments':
        return Icons.payments;
      case 'kitchen':
        return Icons.kitchen;
      default:
        return Icons.work;
    }
  }
} 