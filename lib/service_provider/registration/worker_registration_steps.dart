import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pending_approval_page.dart';
import 'registration_drawer.dart';
import 'license_forms.dart';
import 'package:provider/provider.dart';
import '../../../providers/location_provider.dart';
import '../../../services/location_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

enum RegistrationStep {
  selectService,
  basicInfo,
  licenses,
  cnicInfo,
  verification
}

enum StepStatus { notStarted, inProgress, completed }

class _CNICFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll('-', ''); // Remove existing hyphens

    // If backspace was pressed, handle it properly
    if (oldValue.text.length > newValue.text.length) {
      // Remove a digit
      text = text.substring(0, text.length);
      // Format remaining digits
      if (text.length > 5)
        text = '${text.substring(0, 5)}-${text.substring(5)}';
      if (text.length > 12)
        text = '${text.substring(0, 13)}-${text.substring(13)}';
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    // Only allow up to 13 digits
    if (text.length > 13) {
      return TextEditingValue(
        text: oldValue.text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    // Format the text with hyphens
    String formattedText = text;
    if (text.length >= 5) {
      formattedText = '${text.substring(0, 5)}-${text.substring(5)}';
    }
    if (text.length >= 12) {
      formattedText = '${formattedText.substring(0, 13)}-${text.substring(12)}';
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class WorkerRegistrationSteps extends StatefulWidget {
  const WorkerRegistrationSteps({super.key});

  @override
  State<WorkerRegistrationSteps> createState() =>
      _WorkerRegistrationStepsState();
}

class _WorkerRegistrationStepsState extends State<WorkerRegistrationSteps> {
  final _formKey = GlobalKey<FormState>();
  bool _showBasicInfo = false;
  bool _showCNICInfo = false;
  bool _isBasicInfoCompleted = false;
  bool _isCNICCompleted = false;
  bool _showLicensesInfo = false;
  bool _isLicensesCompleted = false;
  bool _isAdditionalLicenseCompleted = false;

  // Files for upload
  XFile? _profilePictureFile;
  XFile? _videoIntroductionFile;
  XFile? _cnicFrontFile;
  XFile? _cnicBackFile;
  PlatformFile? _policeCertificateFile;
  PlatformFile? _weaponLicenseFile;
  PlatformFile? _driverLicenseFile;
  String? _weaponLicenseUrl;
  String? _driverLicenseUrl;

  // Form Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cnicController = TextEditingController();
  final _experienceController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedService;
  String? _selectedLocation;

  final List<String> _locations = [
    'Johar Town',
    'Model Town',
    'Gulberg',
    'DHA',
    'Bahria Town',
    'WAPDA Town',
    'Allama Iqbal Town',
    'Faisal Town',
    'Lake City',
    'Valencia Town',
  ]..sort();

  final List<String> _experienceLevels = [
    'Less than 6 months',
    '6 months to 1 year',
    '1-2 years',
    '2-3 years',
    '3-5 years',
    '5+ years'
  ];

  @override
  void initState() {
    super.initState();
    if (_selectedLocation != null) {
      _locationController.text = _selectedLocation!;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<XFile?> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    return pickedFile;
  }

  Future<XFile?> _pickVideo() async {
    final pickedFile =
        await ImagePicker().pickVideo(source: ImageSource.gallery);
    return pickedFile;
  }

  Future<PlatformFile?> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );
    if (result != null) {
      return result.files.single;
    }
    return null;
  }

  Future<String?> _uploadFile({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String? mimeType,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.storage.from(bucket).uploadBinary(path, bytes,
          fileOptions: FileOptions(contentType: mimeType));
      final url = supabase.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e, st) {
      debugPrint('Supabase upload error: $e\n$st');
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload file: $e')),
      );
      return null;
    }
  }

  Widget _buildServiceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedService,
          decoration: const InputDecoration(
            labelText: 'Select Service',
            border: OutlineInputBorder(),
          ),
          items: [
            'Auto Mechanic',
            'Baby Caretaker',
            'Chef',
            'Driver',
            'Gardener',
            'Handyman',
            'Locksmith',
            'Maid',
            'Security Guard',
          ].map((String service) {
            return DropdownMenuItem(
              value: service,
              child: Text(service),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedService = value;
              _isAdditionalLicenseCompleted = false;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a service';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Location selection (replace dropdown with map & GPS picker)
        TextFormField(
          controller: _locationController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Service Location',
            border: const OutlineInputBorder(),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.map),
                  tooltip: 'Select on Map',
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => LocationPicker(
                          onLocationSelected: (lat, lng, address) {
                            setState(() {
                              _selectedLocation = address;
                              _locationController.text = address;
                            });
                            final locationProvider =
                                Provider.of<LocationProvider>(context,
                                    listen: false);
                            locationProvider.updateAddress(address,
                                fullAddress: address);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          validator: (value) {
            if ((_selectedLocation ?? '').isEmpty) {
              return 'Please select a location';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _experienceController.text.isEmpty
              ? null
              : _experienceController.text,
          decoration: const InputDecoration(
            labelText: 'Years of Experience',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            labelStyle: TextStyle(color: Colors.grey),
            floatingLabelStyle: TextStyle(color: Colors.black),
          ),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
          items: _experienceLevels.map((level) {
            return DropdownMenuItem(
              value: level,
              child: Text(level),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _experienceController.text = value ?? '';
            });
          },
          validator: (value) => value == null ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildBasicInfoButton() {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _showBasicInfo = true;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: const BorderSide(color: Colors.black),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.person, color: Colors.purple),
        title: const Text(
          'Basic Information',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        trailing: _isBasicInfoCompleted
            ? const Icon(Icons.check_circle, color: Color(0xFF4CAF50))
            : const Icon(Icons.arrow_forward_ios, color: Colors.black),
      ),
    );
  }

  Widget _buildBasicInfoForm() {
    return Column(
      children: [
        TextFormField(
          controller: _firstNameController,
          decoration: const InputDecoration(
            labelText: 'First Name',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            labelStyle: TextStyle(color: Colors.grey),
            floatingLabelStyle: TextStyle(color: Colors.black),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your first name';
            }
            if (value.length < 3) {
              return 'Name must be at least 3 characters long';
            }
            if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
              return 'Name can only contain letters and spaces';
            }
            return null;
          },
          // Only allow letters and spaces
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _lastNameController,
          decoration: const InputDecoration(
            labelText: 'Last Name',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            labelStyle: TextStyle(color: Colors.grey),
            floatingLabelStyle: TextStyle(color: Colors.black),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your last name';
            }
            if (value.length < 3) {
              return 'Name must be at least 3 characters long';
            }
            if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
              return 'Name can only contain letters and spaces';
            }
            return null;
          },
          // Only allow letters and spaces
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            labelStyle: TextStyle(color: Colors.grey),
            floatingLabelStyle: TextStyle(color: Colors.black),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            labelStyle: TextStyle(color: Colors.grey),
            floatingLabelStyle: TextStyle(color: Colors.black),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            if (value.length != 11) {
              return 'Phone number must be 11 digits';
            }
            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
              return 'Phone number can only contain digits';
            }
            return null;
          },
          // Only allow numbers and limit to 11 digits
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
        ),
        const SizedBox(height: 24),
        // Profile Picture Section
        const Text(
          'Profile Picture',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                  image: _profilePictureFile != null
                      ? DecorationImage(
                          image: kIsWeb
                              ? NetworkImage(_profilePictureFile!.path)
                              : FileImage(File(_profilePictureFile!.path))
                                  as ImageProvider,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _profilePictureFile == null
                    ? const Icon(
                        Icons.person,
                        size: 80,
                        color: Colors.grey,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () async {
            final file = await _pickImage(ImageSource.camera);
            if (file != null) {
              setState(() {
                _profilePictureFile = file;
              });
            }
          },
          icon: const Icon(Icons.camera_alt),
          label: const Text('Choose Picture'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.purple,
            minimumSize: const Size(double.infinity, 45),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              setState(() {
                _showBasicInfo = false;
                _isBasicInfoCompleted = true;
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          child: const Text(
            'Save Basic Info',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCNICButton() {
    return ElevatedButton(
      onPressed: _isBasicInfoCompleted
          ? () {
              setState(() {
                _showCNICInfo = true;
              });
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: const BorderSide(color: Colors.black),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.credit_card, color: Colors.purple),
        title: const Text(
          'CNIC Information',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        trailing: _isCNICCompleted
            ? const Icon(Icons.check_circle, color: Color(0xFF4CAF50))
            : const Icon(Icons.arrow_forward_ios, color: Colors.black),
      ),
    );
  }

  Widget _buildCNICForm() {
    return Column(
      children: [
        TextFormField(
          controller: _cnicController,
          decoration: const InputDecoration(
            labelText: 'CNIC Number',
            hintText: '35201-1234567-1',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            labelStyle: TextStyle(color: Colors.grey),
            floatingLabelStyle: TextStyle(color: Colors.black),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
            LengthLimitingTextInputFormatter(15), // 13 digits + 2 hyphens
            _CNICFormatter(),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your CNIC number';
            }
            // Remove hyphens for length check
            String digitsOnly = value.replaceAll('-', '');
            if (digitsOnly.length != 13) {
              return 'CNIC must be 13 digits';
            }
            if (!RegExp(r'^\d{5}-\d{7}-\d$').hasMatch(value)) {
              return 'Invalid CNIC format';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('CNIC Front'),
            subtitle: _cnicFrontFile == null
                ? const Text('Upload front side of your CNIC')
                : Text(_cnicFrontFile!.name),
            trailing: _cnicFrontFile == null
                ? const Icon(Icons.upload)
                : const Icon(Icons.check_circle, color: Colors.green),
            onTap: () async {
              final file = await _pickImage(ImageSource.gallery);
              if (file != null) {
                setState(() {
                  _cnicFrontFile = file;
                });
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('CNIC Back'),
            subtitle: _cnicBackFile == null
                ? const Text('Upload back side of your CNIC')
                : Text(_cnicBackFile!.name),
            trailing: _cnicBackFile == null
                ? const Icon(Icons.upload)
                : const Icon(Icons.check_circle, color: Colors.green),
            onTap: () async {
              final file = await _pickImage(ImageSource.gallery);
              if (file != null) {
                setState(() {
                  _cnicBackFile = file;
                });
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              setState(() {
                _showCNICInfo = false;
                _isCNICCompleted = true;
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          child: const Text(
            'Save CNIC Info',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLicensesButton() {
    return ElevatedButton(
      onPressed: _selectedService != null
          ? () {
              setState(() {
                _showLicensesInfo = true;
              });
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: BorderSide(
            color: Colors.black,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.security, color: Colors.purple),
        title: const Text(
          'Police Character Certificate',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        trailing: _isLicensesCompleted
            ? const Icon(Icons.check_circle, color: Color(0xFF4CAF50))
            : const Icon(Icons.arrow_forward_ios, color: Colors.black),
      ),
    );
  }

  Widget _buildLicensesForm() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Please upload your Police Character Certificate',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'The certificate should be issued within the last 3 months',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Upload Certificate'),
            subtitle: _policeCertificateFile == null
                ? const Text('Upload your Police Character Certificate')
                : Text(_policeCertificateFile!.name),
            trailing: _policeCertificateFile == null
                ? const Icon(Icons.upload)
                : const Icon(Icons.check_circle, color: Colors.green),
            onTap: () async {
              final file = await _pickFile();
              if (file != null) {
                setState(() {
                  _policeCertificateFile = file;
                });
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _showLicensesInfo = false;
              _isLicensesCompleted = true;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          child: const Text(
            'Save Certificate',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalLicensesButton() {
    if (_selectedService != 'Driver' && _selectedService != 'Security Guard') {
      return const SizedBox.shrink();
    }

    List<Widget> widgets = [];
    if (_selectedService == 'Driver') {
      widgets.add(
        ElevatedButton(
          onPressed: () async {
            final file = await _pickFile();
            if (file != null) {
              setState(() {
                _driverLicenseFile = file;
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
              side: const BorderSide(color: Colors.black),
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.drive_eta, color: Colors.purple),
            title: const Text(
              'Driver License',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
              ),
            ),
            trailing: _driverLicenseFile != null
                ? const Icon(Icons.check_circle, color: Color(0xFF4CAF50))
                : const Icon(Icons.arrow_forward_ios, color: Colors.black),
          ),
        ),
      );
    }
    if (_selectedService == 'Security Guard') {
      widgets.add(
        ElevatedButton(
          onPressed: () async {
            final file = await _pickFile();
            if (file != null) {
              setState(() {
                _weaponLicenseFile = file;
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
              side: const BorderSide(color: Colors.black),
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.security, color: Colors.purple),
            title: const Text(
              'Weapon License',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
              ),
            ),
            trailing: _weaponLicenseFile != null
                ? const Icon(Icons.check_circle, color: Color(0xFF4CAF50))
                : const Icon(Icons.arrow_forward_ios, color: Colors.black),
          ),
        ),
      );
    }
    return Column(children: widgets);
  }

  @override
  Widget build(BuildContext context) {
    final bool isAllCompleted = _selectedService != null &&
        _selectedLocation != null &&
        _experienceController.text.isNotEmpty &&
        _isBasicInfoCompleted &&
        _isCNICCompleted &&
        _isLicensesCompleted &&
        ((_selectedService == 'Driver' && _driverLicenseFile != null) ||
            (_selectedService == 'Security Guard' &&
                _weaponLicenseFile != null) ||
            (_selectedService != 'Driver' &&
                _selectedService != 'Security Guard'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Registration'),
        leading: (_showBasicInfo || _showCNICInfo || _showLicensesInfo)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    if (_showBasicInfo) _showBasicInfo = false;
                    if (_showCNICInfo) _showCNICInfo = false;
                    if (_showLicensesInfo) _showLicensesInfo = false;
                  });
                },
              )
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
      ),
      drawer: (!_showBasicInfo && !_showCNICInfo && !_showLicensesInfo)
          ? const RegistrationDrawer()
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_showBasicInfo && !_showCNICInfo && !_showLicensesInfo) ...[
                _buildServiceSelection(),
                const SizedBox(height: 24),
                _buildBasicInfoButton(),
                const SizedBox(height: 16),
                _buildCNICButton(),
                const SizedBox(height: 16),
                _buildLicensesButton(),
                const SizedBox(height: 16),
                _buildAdditionalLicensesButton(),
                const SizedBox(height: 24),
                const Text(
                  'Approval Time: 24-48 hours',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: isAllCompleted ? _submitRegistration : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Text(
                    isAllCompleted
                        ? 'Submit Registration'
                        : 'Complete All Sections to Submit',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (!isAllCompleted) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Remaining sections:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_selectedService == null ||
                      _selectedLocation == null ||
                      _experienceController.text.isEmpty)
                    Text(
                      '• Complete service selection',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  if (!_isBasicInfoCompleted)
                    Text(
                      '• Complete basic information',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  if (!_isCNICCompleted)
                    Text(
                      '• Complete CNIC information',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  if (!_isLicensesCompleted)
                    Text(
                      '• Upload Police Character Certificate',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                ],
              ],
              if (_showBasicInfo) _buildBasicInfoForm(),
              if (_showCNICInfo) _buildCNICForm(),
              if (_showLicensesInfo) _buildLicensesForm(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not found';

      final now = DateTime.now();
      final year = DateFormat('yyyy').format(now);
      final month = DateFormat('MM').format(now);
      final workerId = user.uid;

      String? profilePictureUrl;
      if (_profilePictureFile != null) {
        final file = _profilePictureFile!;
        final bytes = await file.readAsBytes();
        final ext = file.name.split('.').last;
        final path = '$workerId/profile.$ext';
        profilePictureUrl = await _uploadFile(
          bucket: 'worker-registration',
          path: path,
          bytes: bytes,
          mimeType: file.mimeType,
        );
      }

      String? videoUrl;
      if (_videoIntroductionFile != null) {
        final file = _videoIntroductionFile!;
        final bytes = await file.readAsBytes();
        final ext = file.name.split('.').last;
        final path = '$workerId/introduction.$ext';
        videoUrl = await _uploadFile(
          bucket: 'worker-registration',
          path: path,
          bytes: bytes,
          mimeType: file.mimeType,
        );
      }

      String? cnicFrontUrl;
      if (_cnicFrontFile != null) {
        final file = _cnicFrontFile!;
        final bytes = await file.readAsBytes();
        final ext = file.name.split('.').last;
        final path = '$workerId/cnic_front.$ext';
        cnicFrontUrl = await _uploadFile(
          bucket: 'worker-registration',
          path: path,
          bytes: bytes,
          mimeType: file.mimeType,
        );
      }

      String? cnicBackUrl;
      if (_cnicBackFile != null) {
        final file = _cnicBackFile!;
        final bytes = await file.readAsBytes();
        final ext = file.name.split('.').last;
        final path = '$workerId/cnic_back.$ext';
        cnicBackUrl = await _uploadFile(
          bucket: 'worker-registration',
          path: path,
          bytes: bytes,
          mimeType: file.mimeType,
        );
      }

      String? policeCertificateUrl;
      if (_policeCertificateFile != null) {
        final file = _policeCertificateFile!;
        final bytes = file.bytes ?? await File(file.path!).readAsBytes();
        final ext = file.extension ?? 'pdf';
        final path = '$workerId/police_certificate.$ext';
        policeCertificateUrl = await _uploadFile(
          bucket: 'worker-registration',
          path: path,
          bytes: bytes,
        );
      }

      String? weaponLicenseUrl;
      if (_weaponLicenseFile != null) {
        final file = _weaponLicenseFile!;
        final bytes = file.bytes ?? await File(file.path!).readAsBytes();
        final ext = file.extension ?? 'pdf';
        final path = '$workerId/weapon_license.$ext';
        weaponLicenseUrl = await _uploadFile(
          bucket: 'worker-registration',
          path: path,
          bytes: bytes,
        );
      }

      String? driverLicenseUrl;
      if (_driverLicenseFile != null) {
        final file = _driverLicenseFile!;
        final bytes = file.bytes ?? await File(file.path!).readAsBytes();
        final ext = file.extension ?? 'pdf';
        final path = '$workerId/driver_license.$ext';
        driverLicenseUrl = await _uploadFile(
          bucket: 'worker-registration',
          path: path,
          bytes: bytes,
        );
      }

      await FirebaseFirestore.instance.collection('workers').doc(user.uid).set({
        'userId': user.uid,
        'service': _selectedService,
        'location': _selectedLocation,
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'phone': _phoneController.text,
        'cnic': _cnicController.text,
        'experience': _experienceController.text,
        'hasLicense': _isLicensesCompleted,
        'status': 'pending',
        'registrationDate': FieldValue.serverTimestamp(),
        'profilePictureUrl': profilePictureUrl,
        'videoIntroductionUrl': videoUrl,
        'cnicFrontUrl': cnicFrontUrl,
        'cnicBackUrl': cnicBackUrl,
        'policeCertificateUrl': policeCertificateUrl,
        'weaponLicenseUrl': weaponLicenseUrl,
        'driverLicenseUrl': driverLicenseUrl,
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loading indicator
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PendingApprovalPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    }
  }
}
