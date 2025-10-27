import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import '../widgets/weather_station_widget.dart';
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  
  // Settings state
  bool _autoScanEnabled = true;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _darkModeEnabled = false;
  double _scanInterval = 3.0; // minutes
  double _alertThreshold = 40.0; // °C
  String _selectedLanguage = 'English';
  String _temperatureUnit = 'Celsius';
  
  final List<String> _languages = ['English', 'Arabic', 'French'];
  final List<String> _temperatureUnits = ['Celsius', 'Fahrenheit'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // In a real app, load from SharedPreferences or secure storage
    setState(() {
      _autoScanEnabled = true;
      _notificationsEnabled = true;
      _soundEnabled = true;
      _vibrationEnabled = true;
      _darkModeEnabled = false;
      _scanInterval = 3.0;
      _alertThreshold = 40.0;
      _selectedLanguage = 'English';
      _temperatureUnit = 'Celsius';
    });
  }

  void _saveSettings() {
    // In a real app, save to SharedPreferences or secure storage
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Settings saved successfully'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _resetSettings() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to default values?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadSettings(); // Reset to defaults
              _saveSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header with weather station
            // Container(
            //   width: double.infinity,
            //   padding: EdgeInsets.all(8.w),
            //   child: const WeatherStationWidget(),
            // ),
            
            // Settings content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page title
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E8B57),
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Monitoring Settings
                    _buildSettingsSection(
                      'Monitoring Settings',
                      Icons.monitor_heart,
                      [
                        _buildSwitchTile(
                          'Auto Scan',
                          'Automatically scan silos every ${_scanInterval.toInt()} minutes',
                          _autoScanEnabled,
                          (value) => setState(() => _autoScanEnabled = value),
                        ),
                        _buildSliderTile(
                          'Scan Interval',
                          'Minutes between automatic scans',
                          _scanInterval,
                          1.0,
                          10.0,
                          (value) => setState(() => _scanInterval = value),
                          '${_scanInterval.toInt()} min',
                        ),
                        _buildSliderTile(
                          'Alert Threshold',
                          'Temperature threshold for alerts',
                          _alertThreshold,
                          20.0,
                          60.0,
                          (value) => setState(() => _alertThreshold = value),
                          '${_alertThreshold.toInt()}°C',
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Notification Settings
                    _buildSettingsSection(
                      'Notifications',
                      Icons.notifications,
                      [
                        _buildSwitchTile(
                          'Push Notifications',
                          'Receive alerts for temperature warnings',
                          _notificationsEnabled,
                          (value) => setState(() => _notificationsEnabled = value),
                        ),
                        _buildSwitchTile(
                          'Sound Alerts',
                          'Play sound for critical alerts',
                          _soundEnabled,
                          (value) => setState(() => _soundEnabled = value),
                        ),
                        _buildSwitchTile(
                          'Vibration',
                          'Vibrate for alert notifications',
                          _vibrationEnabled,
                          (value) => setState(() => _vibrationEnabled = value),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Display Settings
                    _buildSettingsSection(
                      'Display',
                      Icons.display_settings,
                      [
                        _buildSwitchTile(
                          'Dark Mode',
                          'Use dark theme (Coming Soon)',
                          _darkModeEnabled,
                          (value) => setState(() => _darkModeEnabled = value),
                        ),
                        _buildDropdownTile(
                          'Temperature Unit',
                          'Display temperature in',
                          _temperatureUnit,
                          _temperatureUnits,
                          (value) => setState(() => _temperatureUnit = value!),
                        ),
                        _buildDropdownTile(
                          'Language',
                          'App display language',
                          _selectedLanguage,
                          _languages,
                          (value) => setState(() => _selectedLanguage = value!),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // System Information
                    _buildSettingsSection(
                      'System Information',
                      Icons.info,
                      [
                        _buildInfoTile('Total Silos', '195'),
                        _buildInfoTile('Temperature Sensors', '1,560'),
                        _buildInfoTile('App Version', '1.0.0'),
                        _buildInfoTile('Build Number', '1'),
                        _buildInfoTile('Developer', 'Eng. Bashar Moh Imad'),
                        _buildInfoTile('Company', 'iDEALCHiP Technology Co. Ltd.'),
                      ],
                    ),
                    
                    SizedBox(height: 32.h),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveSettings,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Settings'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E8B57),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(width: 16.w),
                        
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _resetSettings,
                            icon: const Icon(Icons.restore),
                            label: const Text('Reset'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Footer
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Silo Monitor',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E8B57),
                            ),
                          ),
                          Text(
                            'Industrial IoT Platform',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '© 2024 iDEALCHiP Technology Co. Ltd.',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
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
  }

  Widget _buildSettingsSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF2E8B57),
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E8B57),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF2E8B57),
      ),
    );
  }

  Widget _buildSliderTile(String title, String subtitle, double value, double min, double max, ValueChanged<double> onChanged, String displayValue) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Text(
                displayValue,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E8B57),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            onChanged: onChanged,
            activeColor: const Color(0xFF2E8B57),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(String title, String subtitle, String value, List<String> options, ValueChanged<String?> onChanged) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.grey[600],
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        underline: Container(),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
