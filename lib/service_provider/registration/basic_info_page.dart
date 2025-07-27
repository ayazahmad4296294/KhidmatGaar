import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BasicInfoPage extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController cnicController;
  final GlobalKey<FormState> formKey;

  const BasicInfoPage({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.cnicController,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                if (value.length < 3) {
                  return 'Name must be at least 3 characters long';
                }
                if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
                  return 'Name can only contain letters and spaces';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (!RegExp(r'^\+?[0-9]{11,13}$').hasMatch(value)) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your address';
                }
                if (value.length < 10) {
                  return 'Please enter a complete address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: cnicController,
              decoration: const InputDecoration(
                labelText: 'CNIC Number',
                prefixIcon: Icon(Icons.credit_card),
                hintText: '35202-1234567-1',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your CNIC number';
                }
                // Pakistani CNIC format: 12345-1234567-1
                if (!RegExp(r'^\d{5}-\d{7}-\d{1}$').hasMatch(value)) {
                  return 'Please enter a valid CNIC number (e.g., 35202-1234567-1)';
                }
                return null;
              },
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                LengthLimitingTextInputFormatter(15),
                // Auto-format CNIC
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final text = newValue.text;
                  if (text.length > 13) return oldValue;
                  if (text.length >= 5 && !text.contains('-')) {
                    return TextEditingValue(
                      text: '${text.substring(0, 5)}-${text.substring(5)}',
                      selection:
                          TextSelection.collapsed(offset: text.length + 1),
                    );
                  }
                  if (text.length >= 13 && text.indexOf('-', 7) == -1) {
                    return TextEditingValue(
                      text: '${text.substring(0, 13)}-${text.substring(13)}',
                      selection:
                          TextSelection.collapsed(offset: text.length + 1),
                    );
                  }
                  return newValue;
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
