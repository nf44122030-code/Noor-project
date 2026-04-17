import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../features/auth/presentation/providers/auth_controller.dart';
import '../../../../core/theme/theme_controller.dart';

// ── Country Data ─────────────────────────────────────────────────────────────
const Map<String, Map<String, Object>> _kCountries = {
  'Algeria':        {'code': '+213', 'cities': ['Algiers', 'Oran', 'Constantine', 'Annaba']},
  'Bahrain':        {'code': '+973', 'cities': ['Manama', 'Riffa', 'Muharraq', 'Hamad Town']},
  'Egypt':          {'code': '+20',  'cities': ['Cairo', 'Alexandria', 'Giza', 'Luxor', 'Aswan']},
  'France':         {'code': '+33',  'cities': ['Paris', 'Marseille', 'Lyon', 'Toulouse', 'Nice']},
  'Germany':        {'code': '+49',  'cities': ['Berlin', 'Munich', 'Hamburg', 'Frankfurt', 'Cologne']},
  'India':          {'code': '+91',  'cities': ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Kolkata', 'Hyderabad']},
  'Iran':           {'code': '+98',  'cities': ['Tehran', 'Isfahan', 'Mashhad', 'Tabriz', 'Shiraz']},
  'Iraq':           {'code': '+964', 'cities': ['Baghdad', 'Basra', 'Mosul', 'Erbil', 'Kirkuk', 'Sulaymaniyah', 'Najaf', 'Karbala', 'Nasiriyah', 'Amarah', 'Diwaniyah', 'Samawah']},
  'Jordan':         {'code': '+962', 'cities': ['Amman', 'Zarqa', 'Irbid', 'Aqaba', 'Madaba']},
  'Kuwait':         {'code': '+965', 'cities': ['Kuwait City', 'Salmiya', 'Hawalli', 'Jahra', 'Ahmadi']},
  'Lebanon':        {'code': '+961', 'cities': ['Beirut', 'Tripoli', 'Sidon', 'Tyre', 'Zahle']},
  'Libya':          {'code': '+218', 'cities': ['Tripoli', 'Benghazi', 'Misrata', 'Sabha']},
  'Morocco':        {'code': '+212', 'cities': ['Casablanca', 'Rabat', 'Fez', 'Marrakech', 'Tangier']},
  'Oman':           {'code': '+968', 'cities': ['Muscat', 'Salalah', 'Sohar', 'Nizwa', 'Sur']},
  'Pakistan':       {'code': '+92',  'cities': ['Karachi', 'Lahore', 'Islamabad', 'Rawalpindi', 'Faisalabad']},
  'Palestine':      {'code': '+970', 'cities': ['Gaza', 'Ramallah', 'Hebron', 'Nablus', 'Jenin']},
  'Qatar':          {'code': '+974', 'cities': ['Doha', 'Al Wakrah', 'Al Khor', 'Dukhan']},
  'Saudi Arabia':   {'code': '+966', 'cities': ['Riyadh', 'Jeddah', 'Mecca', 'Medina', 'Dammam', 'Taif', 'Khobar']},
  'Sudan':          {'code': '+249', 'cities': ['Khartoum', 'Omdurman', 'Port Sudan', 'Kassala']},
  'Syria':          {'code': '+963', 'cities': ['Damascus', 'Aleppo', 'Homs', 'Latakia', 'Deir ez-Zor']},
  'Tunisia':        {'code': '+216', 'cities': ['Tunis', 'Sfax', 'Sousse', 'Kairouan']},
  'Turkey':         {'code': '+90',  'cities': ['Istanbul', 'Ankara', 'Izmir', 'Bursa', 'Antalya']},
  'UAE':            {'code': '+971', 'cities': ['Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman', 'Ras Al Khaimah']},
  'United Kingdom': {'code': '+44',  'cities': ['London', 'Manchester', 'Birmingham', 'Glasgow', 'Edinburgh', 'Liverpool']},
  'United States':  {'code': '+1',   'cities': ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia']},
  'Yemen':          {'code': '+967', 'cities': ['Sanaa', 'Aden', 'Taiz', 'Hodeidah', 'Mukalla']},
};

List<String> _citiesFor(String country) =>
    (_kCountries[country]?['cities'] as List?)?.cast<String>() ?? [];

// ─────────────────────────────────────────────────────────────────────────────

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController; // number only (no code)
  late TextEditingController _bioController;

  String _selectedCountryCode = '+964'; // phone country code
  String _selectedCountry = '';         // location country
  String _selectedCity = '';            // location city

  final authController = Get.find<AuthController>();
  final themeController = Get.find<ThemeController>();
  
  bool _isUploadingImage = false;

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String get _formattedPhone {
    final num = _phoneNumberController.text.trim();
    return num.isEmpty ? '' : '$_selectedCountryCode $num';
  }

  String get _formattedLocation {
    if (_selectedCountry.isEmpty) return '';
    return _selectedCity.isEmpty ? _selectedCountry : '$_selectedCountry, $_selectedCity';
  }

  // ── Init ────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _nameController  = TextEditingController(text: authController.userName);
    _emailController = TextEditingController(text: authController.userEmail);
    _bioController   = TextEditingController(text: authController.bio);

    // Parse saved phone → code + number
    final savedPhone = authController.phone;
    _selectedCountryCode = '+964'; // default Iraq
    String numberPart = savedPhone;
    if (savedPhone.startsWith('+')) {
      for (final entry in _kCountries.entries) {
        final code = entry.value['code'] as String;
        if (savedPhone.startsWith(code)) {
          _selectedCountryCode = code;
          numberPart = savedPhone.substring(code.length).trim();
          break;
        }
      }
    }
    _phoneNumberController = TextEditingController(text: numberPart);

    // Parse saved location → country + city
    final savedLocation = authController.location;
    if (savedLocation.contains(',')) {
      final parts = savedLocation.split(',');
      _selectedCountry = parts[0].trim();
      _selectedCity    = parts.length > 1 ? parts[1].trim() : '';
    } else {
      _selectedCountry = savedLocation;
      _selectedCity    = '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<void> _handleSave() async {
    setState(() => _isEditing = false);
    await authController.updateFullProfile(
      name:     _nameController.text,
      email:    _emailController.text,
      phone:    _formattedPhone,
      location: _formattedLocation,
      bio:      _bioController.text,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('profile_updated'.tr)),
      );
    }
  }

  // ── Image Picker ────────────────────────────────────────────────────────────

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final isDarkMode = themeController.isDarkMode;
        final bgColor = isDarkMode ? const Color(0xFF132F4C) : Colors.white;
        final textColor = isDarkMode ? Colors.white : const Color(0xFF1F2937);
        final iconColor = isDarkMode ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(color: bgColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('update_profile_pic'.tr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.camera_alt, color: iconColor),
                ),
                title: Text('take_photo'.tr, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.photo_library, color: iconColor),
                ),
                title: Text('choose_gallery'.tr, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() => _isUploadingImage = true);
      bool success = false;
      try {
        // readAsBytes() works on both web and native (dart:io File fails on web)
        final bytes = await pickedFile.readAsBytes();
        success = await authController.uploadProfilePicture(bytes);
      } finally {
        // Always stop the spinner — even if an unhandled exception occurs
        if (mounted) setState(() => _isUploadingImage = false);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'profile_pic_success'.tr
                  : (authController.lastErrorMessage ?? 'profile_pic_fail'.tr),
            ),
          ),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDarkMode = themeController.isDarkMode;

      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: isDarkMode
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A1929), Color(0xFF0A1929)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                  ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  // Curved Header
                  Container(
                    decoration: BoxDecoration(
                      gradient: isDarkMode
                          ? const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)],
                            )
                          : const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFF0284C7), Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                            ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.only(top: 40, bottom: 96, left: 24, right: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'profile_title'.tr,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 6,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isEditing ? Icons.save : Icons.edit,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () {
                            if (_isEditing) {
                              _handleSave();
                            } else {
                              setState(() => _isEditing = true);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // Main Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                      child: Column(
                        children: [
                          // Name
                          _isEditing
                              ? TextField(
                                  controller: _nameController,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isDarkMode ? const Color(0xFF1E4976) : const Color(0xFFBAE6FD),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
                                    ),
                                    filled: true,
                                    fillColor: isDarkMode ? const Color(0xFF132F4C) : Colors.white,
                                  ),
                                )
                              : Text(
                                  _nameController.text,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
                                  ),
                                ),
                          const SizedBox(height: 8),
                          Text(
                            'member_since'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Subscription Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: authController.isPremium 
                                  ? (isDarkMode ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
                                  : (isDarkMode ? const Color(0xFF374151) : const Color(0xFFF3F4F6)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: authController.isPremium
                                    ? (isDarkMode ? const Color(0xFF059669) : const Color(0xFF10B981))
                                    : (isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  authController.isPremium ? Icons.workspace_premium : Icons.stars_rounded,
                                  size: 16,
                                  color: authController.isPremium
                                      ? (isDarkMode ? const Color(0xFF34D399) : const Color(0xFF059669))
                                      : (isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  authController.isPremium 
                                      ? '${authController.currentPlanName} Plan' 
                                      : 'starter_plan'.tr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: authController.isPremium
                                        ? (isDarkMode ? const Color(0xFF34D399) : const Color(0xFF059669))
                                        : (isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF374151)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Bio
                          _buildSectionCard(
                            title: 'bio'.tr,
                            isDarkMode: isDarkMode,
                            child: _isEditing
                                ? TextField(
                                    controller: _bioController,
                                    maxLines: 3,
                                    style: TextStyle(
                                      color: isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.all(12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: isDarkMode ? const Color(0xFF1E4976) : const Color(0xFFBAE6FD),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
                                      ),
                                      filled: true,
                                      fillColor: isDarkMode ? const Color(0xFF0A1929) : const Color(0xFFF0F9FF),
                                    ),
                                  )
                                : Container(
                                    width: double.infinity,
                                    constraints: const BoxConstraints(minHeight: 80),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? const Color(0xFF0A1929) : const Color(0xFFF0F9FF),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDarkMode ? const Color(0xFF1E4976) : const Color(0xFFBAE6FD),
                                      ),
                                    ),
                                    child: Text(
                                      _bioController.text.isEmpty ? 'no_bio'.tr : _bioController.text,
                                      style: TextStyle(
                                        color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),

                          // Contact Information
                          _buildSectionCard(
                            title: 'contact_info'.tr,
                            isDarkMode: isDarkMode,
                            child: Column(
                              children: [
                                _buildProfileField(
                                  icon: Icons.email,
                                  label: 'email'.tr,
                                  controller: _emailController,
                                  isEditing: _isEditing,
                                  isDarkMode: isDarkMode,
                                  inputType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 12),
                                // ── Phone field ──────────────────────────────
                                _buildPhoneField(isDarkMode),
                                const SizedBox(height: 12),
                                // ── Location field ───────────────────────────
                                _buildLocationField(isDarkMode),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Stats
                          Row(
                            children: [
                              Expanded(child: _buildStatCard(label: 'sessions'.tr, value: authController.sessionsCount.toString(), isDarkMode: isDarkMode)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildStatCard(label: 'queries'.tr, value: authController.queriesCount.toString(), isDarkMode: isDarkMode)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildStatCard(label: 'reports'.tr, value: authController.reportsCount.toString(), isDarkMode: isDarkMode)),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Save / Cancel buttons
                          if (_isEditing)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _handleSave,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: isDarkMode
                                            ? const LinearGradient(colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)])
                                            : const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF06B6D4)]),
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'Save Changes',
                                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => setState(() => _isEditing = false),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDarkMode ? const Color(0xFF1E4976) : const Color(0xFFE0F2FE),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                    ),
                                    child: Text(
                                      'cancel'.tr,
                                      style: TextStyle(
                                        color: isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF0369A1),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Floating Profile Image
              Positioned(
                top: 120,
                left: 0,
                right: 0,
                child: Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _isEditing ? _showImagePickerOptions : null,
                        child: Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF132F4C) : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                            image: authController.profileImage.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(authController.profileImage),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _isUploadingImage
                              ? const Center(child: CircularProgressIndicator())
                              : authController.profileImage.isEmpty
                                  ? Icon(Icons.person, size: 64, color: isDarkMode ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7))
                                  : null,
                        ),
                      ),
                      if (_isEditing && !_isUploadingImage)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImagePickerOptions,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: isDarkMode
                                    ? const LinearGradient(colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)])
                                    : const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF06B6D4)]),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ── Phone field with country code ────────────────────────────────────────────

  Widget _buildPhoneField(bool isDarkMode) {
    final labelColor = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final textColor  = isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937);
    final iconColor  = isDarkMode ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7);
    final fillColor  = isDarkMode ? const Color(0xFF0A1929) : const Color(0xFFF0F9FF);
    final borderColor = isDarkMode ? const Color(0xFF1E4976) : const Color(0xFFBAE6FD);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.phone, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('phone'.tr, style: TextStyle(fontSize: 12, color: labelColor)),
              const SizedBox(height: 4),
              if (_isEditing) ...[
                Row(
                  children: [
                    // Country code dropdown
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: fillColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCountryCode,
                          dropdownColor: isDarkMode ? const Color(0xFF132F4C) : Colors.white,
                          style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.bold),
                          items: _kCountries.entries.map((e) {
                            final code = e.value['code'] as String;
                            return DropdownMenuItem(
                              value: code,
                              child: Text('${e.key} ($code)', style: TextStyle(fontSize: 13, color: textColor)),
                            );
                          }).toList(),
                          selectedItemBuilder: (_) => _kCountries.entries.map((e) {
                            final code = e.value['code'] as String;
                            return Center(child: Text(code, style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.bold)));
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedCountryCode = v!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Number field
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: TextField(
                          controller: _phoneNumberController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            hintText: 'phone_number'.tr,
                            hintStyle: TextStyle(color: labelColor, fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2)),
                            filled: true,
                            fillColor: fillColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  _formattedPhone.isEmpty ? 'not_set'.tr : _formattedPhone,
                  style: TextStyle(fontSize: 15, color: _formattedPhone.isEmpty ? labelColor : textColor),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Location field: country + city dropdowns ──────────────────────────────

  Widget _buildLocationField(bool isDarkMode) {
    final labelColor  = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final textColor   = isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937);
    final iconColor   = isDarkMode ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7);
    final fillColor   = isDarkMode ? const Color(0xFF0A1929) : const Color(0xFFF0F9FF);
    final borderColor = isDarkMode ? const Color(0xFF1E4976) : const Color(0xFFBAE6FD);

    final cities       = _citiesFor(_selectedCountry);
    final validCity    = cities.contains(_selectedCity) ? _selectedCity : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('location'.tr, style: TextStyle(fontSize: 12, color: labelColor)),
              const SizedBox(height: 4),
              if (_isEditing) ...[
                // Country dropdown
                _buildDropdown(
                  hint: 'select_country'.tr,
                  value: _kCountries.containsKey(_selectedCountry) ? _selectedCountry : null,
                  items: _kCountries.keys.toList(),
                  fillColor: fillColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  labelColor: labelColor,
                  isDarkMode: isDarkMode,
                  onChanged: (v) => setState(() {
                    _selectedCountry = v!;
                    _selectedCity = '';        // reset city when country changes
                    // auto-select country code if possible
                    final code = _kCountries[v]?['code'] as String?;
                    if (code != null && _phoneNumberController.text.isEmpty) {
                      _selectedCountryCode = code;
                    }
                  }),
                ),
                if (_selectedCountry.isNotEmpty && cities.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  // City dropdown
                  _buildDropdown(
                    hint: 'select_city'.tr,
                    value: validCity,
                    items: cities,
                    fillColor: fillColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    labelColor: labelColor,
                    isDarkMode: isDarkMode,
                    onChanged: (v) => setState(() => _selectedCity = v!),
                  ),
                ],
              ] else ...[
                Text(
                  _formattedLocation.isEmpty ? 'not_set'.tr : _formattedLocation,
                  style: TextStyle(fontSize: 15, color: _formattedLocation.isEmpty ? labelColor : textColor),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Color fillColor,
    required Color borderColor,
    required Color textColor,
    required Color labelColor,
    required bool isDarkMode,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: TextStyle(fontSize: 13, color: labelColor)),
          dropdownColor: isDarkMode ? const Color(0xFF132F4C) : Colors.white,
          style: TextStyle(fontSize: 13, color: textColor),
          icon: Icon(Icons.arrow_drop_down, color: textColor),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item, style: TextStyle(fontSize: 13, color: textColor)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── Shared Widgets ───────────────────────────────────────────────────────────

  Widget _buildSectionCard({required String title, required bool isDarkMode, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF132F4C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? const Color(0xFF1E4976) : const Color(0xFFBAE6FD)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDarkMode ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7))),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required bool isDarkMode,
    TextInputType? inputType,
  }) {
    final labelColor = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final textColor  = isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937);
    final iconColor  = isDarkMode ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: labelColor)),
              const SizedBox(height: 4),
              isEditing
                  ? TextField(
                      controller: controller,
                      keyboardType: inputType,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDarkMode ? const Color(0xFF1E4976) : const Color(0xFFBAE6FD))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDarkMode ? const Color(0xFF1E4976) : const Color(0xFFBAE6FD))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2)),
                        filled: true,
                        fillColor: isDarkMode ? const Color(0xFF0A1929) : const Color(0xFFF0F9FF),
                      ),
                    )
                  : Text(controller.text, style: TextStyle(fontSize: 15, color: textColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({required String label, required String value, required bool isDarkMode}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF132F4C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? const Color(0xFF1E4976) : const Color(0xFFBAE6FD)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDarkMode ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7))),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))),
        ],
      ),
    );
  }
}
