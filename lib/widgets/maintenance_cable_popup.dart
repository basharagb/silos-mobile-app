import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/maintenance_api_service.dart';

class MaintenanceCablePopup extends StatefulWidget {
  final int siloNumber;
  final VoidCallback onClose;

  const MaintenanceCablePopup({
    super.key,
    required this.siloNumber,
    required this.onClose,
  });

  @override
  State<MaintenanceCablePopup> createState() => _MaintenanceCablePopupState();
}

class _MaintenanceCablePopupState extends State<MaintenanceCablePopup> {
  MaintenanceSiloData? _siloData;
  bool _loading = true;
  String? _error;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _fetchSiloMaintenanceData();
  }

  Future<void> _fetchSiloMaintenanceData({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        setState(() {
          _refreshing = true;
          _error = null;
        });
      } else {
        setState(() {
          _loading = true;
          _error = null;
        });
      }

      print('🔄 [MAINTENANCE POPUP] Fetching ${isRefresh ? 'FRESH' : 'INITIAL'} data for silo ${widget.siloNumber}...');
      final data = await MaintenanceApiService.fetchMaintenanceSiloData(widget.siloNumber);
      
      setState(() {
        _siloData = data;
      });
      
      print('✅ [MAINTENANCE POPUP] Successfully fetched ${isRefresh ? 'FRESH' : 'INITIAL'} data for silo ${widget.siloNumber}');
    } catch (err) {
      print('🚨 [MAINTENANCE POPUP] Failed to fetch silo ${widget.siloNumber} data: $err');
      final errorMessage = err.toString().replaceFirst('Exception: ', '');
      
      setState(() {
        _error = errorMessage;
      });
      
      print('🚨 [MAINTENANCE POPUP] Stopping automatic retries for silo ${widget.siloNumber}');
    } finally {
      setState(() {
        _loading = false;
        _refreshing = false;
      });
    }
  }

  void _handleRefresh() {
    _fetchSiloMaintenanceData(isRefresh: true);
  }

  Widget _getStatusIcon(String color, {bool isDisconnected = false}) {
    if (isDisconnected) {
      return Icon(Icons.close, size: 10.sp, color: Colors.red); // 35% smaller: 16 -> 10.4 ≈ 10
    }
    if (color == '#d14141') {
      return Icon(Icons.warning, size: 10.sp, color: Colors.red); // 35% smaller: 16 -> 10.4 ≈ 10
    }
    if (color == '#ff9800') {
      return Icon(Icons.warning, size: 10.sp, color: Colors.orange); // 35% smaller: 16 -> 10.4 ≈ 10
    }
    return Icon(Icons.check_circle, size: 10.sp, color: Colors.green); // 35% smaller: 16 -> 10.4 ≈ 10
  }

  String _getStatusText(String color, {bool isDisconnected = false}) {
    if (isDisconnected) return 'Disconnected';
    if (color == '#d14141') return 'Critical';
    if (color == '#ff9800') return 'Warning';
    return 'Normal';
  }

  Color _parseColor(String colorString) {
    try {
      final cleanColor = colorString.replaceAll('#', '');
      return Color(int.parse('FF$cleanColor', radix: 16));
    } catch (e) {
      return Colors.grey.shade300;
    }
  }

  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: 0.95.sw,
          height: 0.9.sh,
          margin: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.cable,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Silo ${widget.siloNumber} - Cable Testing',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (_siloData != null) ...[
                            SizedBox(height: 4.h),
                            Flexible(
                              child: Text(
                                '${_siloData!.siloGroup} • ${_siloData!.cableCount == 2 ? 'Circular' : 'Square'} • ${_siloData!.cableCount} Cable${_siloData!.cableCount != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _refreshing ? null : _handleRefresh,
                          icon: _refreshing
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(Icons.refresh, color: Colors.white, size: 24.sp),
                        ),
                        IconButton(
                          onPressed: widget.onClose,
                          icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48.w,
              height: 48.h,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Loading maintenance data...',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64.sp,
                color: Colors.red,
              ),
              SizedBox(height: 16.h),
              Text(
                'Connection Error',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: _handleRefresh,
                    child: Text('Try Again'),
                  ),
                  SizedBox(width: 16.w),
                  ElevatedButton(
                    onPressed: widget.onClose,
                    child: Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_siloData == null) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cable Temperature Comparison Table Only
          _buildCableComparison(),
        ],
      ),
    );
  }

  Widget _buildSystemOverview() {
    final maxTemp = _siloData!.sensorValues.where((v) => v != -127).isNotEmpty
        ? _siloData!.sensorValues.where((v) => v != -127).reduce((a, b) => a > b ? a : b)
        : 0.0;
    final totalSensors = _siloData!.cables.fold(0, (total, cable) => total + cable.sensors.length);
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thermostat, size: 20.sp, color: Colors.grey[600]),
              SizedBox(width: 8.w),
              Text(
                'System Overview',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
              ),
              Spacer(),
              Text(
                'Last Updated: ${_formatDateTime(_siloData!.timestamp)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  '${maxTemp.toStringAsFixed(1)}°C',
                  'Max Temperature',
                  _parseColor(_siloData!.siloColor),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildOverviewCard(
                  totalSensors.toString(),
                  'Total Sensors',
                  Colors.blue.shade600,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildOverviewCard(
                  _siloData!.cables.length.toString(),
                  'Active Cables',
                  Colors.green.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCableComparison() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.cable, size: 20.sp, color: Colors.blue.shade600),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cable Temperature Comparison',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                    ),
                    Text(
                      '${_siloData!.cableCount == 2 ? 'Cable 0 & Cable 1' : 'Cable 0 Only'} • Sensors displayed top→bottom: S8 → S1',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildCableTable(),
        ],
      ),
    );
  }

  Widget _buildCableTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade200, width: 1),
      columnWidths: {
        0: const FlexColumnWidth(1),
        1: const FlexColumnWidth(2),
        if (_siloData!.cableCount == 2) 2: const FlexColumnWidth(2),
        (_siloData!.cableCount == 2 ? 3 : 2): const FlexColumnWidth(1),
      },
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade50),
          children: [
            _buildTableCell('Sensor', isHeader: true),
            _buildTableCell('Cable 0', isHeader: true),
            if (_siloData!.cableCount == 2)
              _buildTableCell('Cable 1', isHeader: true),
            _buildTableCell('Status', isHeader: true),
          ],
        ),
        
        // Data rows (S8 to S1)
        for (int i = 7; i >= 0; i--) ...[
          _buildSensorRow(i),
        ],
      ],
    );
  }

  TableRow _buildSensorRow(int sensorIndex) {
    final cable0Sensor = _siloData!.cables.isNotEmpty && _siloData!.cables[0].sensors.length > sensorIndex
        ? _siloData!.cables[0].sensors[sensorIndex]
        : null;
    final cable1Sensor = _siloData!.cables.length > 1 && _siloData!.cables[1].sensors.length > sensorIndex
        ? _siloData!.cables[1].sensors[sensorIndex]
        : null;
    final sensorColor = _siloData!.sensorColors.length > sensorIndex
        ? _siloData!.sensorColors[sensorIndex]
        : '#46d446';

    return TableRow(
      children: [
        // Sensor Label
        _buildTableCell(
          'S${sensorIndex + 1}',
          color: _parseColor(sensorColor),
        ),
        
        // Cable 0
        _buildSensorCell(cable0Sensor),
        
        // Cable 1 (if exists)
        if (_siloData!.cableCount == 2)
          _buildSensorCell(cable1Sensor),
        
        // Status
        _buildTableCell(
          _getStatusText(sensorColor, isDisconnected: cable0Sensor?.level == -127),
          icon: _getStatusIcon(sensorColor, isDisconnected: cable0Sensor?.level == -127),
        ),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, Color? color, Widget? icon}) {
    return Container(
      padding: EdgeInsets.all(5.w), // 35% smaller: 8 -> 5.2 ≈ 5
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (color != null) ...[
            Container(
              width: 8.w, // 35% smaller: 12 -> 7.8 ≈ 8
              height: 8.h, // 35% smaller: 12 -> 7.8 ≈ 8
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 5.w), // 35% smaller: 8 -> 5.2 ≈ 5
          ],
          if (icon != null) ...[
            icon,
            SizedBox(width: 3.w), // 35% smaller: 4 -> 2.6 ≈ 3
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isHeader ? 9.sp : 8.sp, // 35% smaller: 14->9, 12->8
                fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
                color: isHeader ? Colors.grey[700] : Colors.grey[900],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCell(CableSensorData? sensor) {
    if (sensor == null) {
      return Container(
        padding: EdgeInsets.all(5.w), // 35% smaller: 8 -> 5.2 ≈ 5
        child: Container(
          padding: EdgeInsets.all(5.w), // 35% smaller: 8 -> 5.2 ≈ 5
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4.r), // 35% smaller: 6 -> 3.9 ≈ 4
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            'N/A',
            style: TextStyle(
              fontSize: 8.sp, // 35% smaller: 12 -> 7.8 ≈ 8
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final isDisconnected = sensor.level == -127;
    final sensorColor = _parseColor(sensor.color);

    return Container(
      padding: EdgeInsets.all(5.w), // 35% smaller: 8 -> 5.2 ≈ 5
      child: Container(
        padding: EdgeInsets.all(5.w), // 35% smaller: 8 -> 5.2 ≈ 5
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.r), // 35% smaller: 6 -> 3.9 ≈ 4
          border: Border.all(color: sensorColor, width: 1.3), // 35% smaller: 2 -> 1.3
        ),
        child: Column(
          children: [
            Text(
              isDisconnected ? 'DISC' : '${sensor.level.toStringAsFixed(1)}°C',
              style: TextStyle(
                fontSize: isDisconnected ? 7.sp : 9.sp, // 35% smaller: 10->7, 14->9
                fontWeight: FontWeight.bold,
                color: sensorColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h), // 35% smaller: 4 -> 2.6 ≈ 2
            _getStatusIcon(sensor.color, isDisconnected: isDisconnected),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorValues() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thermostat, size: 20.sp, color: Colors.grey[600]),
              SizedBox(width: 8.w),
              Text(
                'Sensor Values (S8 → S1)',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 6.w,
              mainAxisSpacing: 6.h,
              childAspectRatio: 1.1,
            ),
            itemCount: 8,
            itemBuilder: (context, index) {
              final sensorIndex = 7 - index; // S8 to S1
              final value = _siloData!.sensorValues.length > sensorIndex
                  ? _siloData!.sensorValues[sensorIndex]
                  : 0.0;
              final isDisabled = value == -127;
              final displayColor = isDisabled
                  ? Colors.grey.shade400
                  : _parseColor(_siloData!.sensorColors.length > sensorIndex
                      ? _siloData!.sensorColors[sensorIndex]
                      : '#46d446');
              final displayValue = isDisabled ? 'DISCONNECTED' : '${value.toStringAsFixed(1)}°C';

              return Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: displayColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: displayColor, width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'S${sensorIndex + 1}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    if (isDisabled) ...[
                      Icon(Icons.warning, size: 12.sp, color: displayColor),
                      SizedBox(height: 1.h),
                      Text(
                        'DISC',
                        style: TextStyle(
                          fontSize: 7.sp,
                          fontWeight: FontWeight.bold,
                          color: displayColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      Text(
                        displayValue,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: displayColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
