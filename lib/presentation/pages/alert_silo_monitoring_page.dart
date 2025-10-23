import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/alerts_api_service.dart';

class AlertSiloMonitoringPage extends StatefulWidget {
  const AlertSiloMonitoringPage({super.key});

  @override
  State<AlertSiloMonitoringPage> createState() => _AlertSiloMonitoringPageState();
}

class _AlertSiloMonitoringPageState extends State<AlertSiloMonitoringPage> {
  List<ProcessedAlert> _alertSilos = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  int _currentPage = 1;
  PaginationInfo? _pagination;
  static const int _itemsPerPage = 20; // Fixed at 20 items per page (matching React app)

  @override
  void initState() {
    super.initState();
    _fetchAlertSilos();
  }

  Future<void> _fetchAlertSilos({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      print('🚨 [ALERT SILO MONITORING] Fetching alerts for page $page...');
      
      final result = await AlertsApiService.fetchActiveAlerts(
        forceRefresh: false,
        page: page,
        limit: _itemsPerPage,
      );

      if (result.error != null) {
        throw Exception(result.error);
      }

      setState(() {
        _alertSilos = result.alerts;
        // Always update pagination info when we get it from API
        if (result.pagination != null) {
          _pagination = result.pagination;
        }
        _currentPage = page;
      });

      print('🚨 [ALERT SILO MONITORING] Successfully loaded ${result.alerts.length} alerts for page $page');
    } catch (error) {
      print('🚨 [ALERT SILO MONITORING] Failed to fetch alert silos: $error');
      setState(() {
        _error = error.toString();
        _alertSilos = [];
        // Don't clear pagination on error - keep it visible
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _handleManualRefresh() async {
    if (_refreshing || _loading) return;

    setState(() {
      _refreshing = true;
      _error = null;
    });

    print('🚨 [ALERT SILO MONITORING] Manual refresh triggered - clearing cache');
    AlertsApiService.clearAlertsCache();

    try {
      await _fetchAlertSilos(page: _currentPage);
    } catch (error) {
      print('🚨 [ALERT SILO MONITORING] Manual refresh failed: $error');
    } finally {
      setState(() {
        _refreshing = false;
      });
    }
  }

  Future<void> _handlePageChange(int page) async {
    if (page == _currentPage || _loading || _refreshing) return;
    
    // Preserve current pagination info during page change
    final currentPagination = _pagination;
    
    setState(() {
      _currentPage = page;
      // Keep pagination visible during loading
      if (currentPagination != null) {
        _pagination = currentPagination;
      }
    });
    
    await _fetchAlertSilos(page: page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade600, size: 24.sp),
            SizedBox(width: 8.w),
            Text(
              'Alert Silo Monitoring',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _handleManualRefresh,
            icon: Icon(
              Icons.refresh,
              color: _refreshing ? Colors.blue : Colors.grey.shade600,
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return _buildAlertsContent();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.blue.shade500,
              strokeWidth: 3,
            ),
            SizedBox(height: 16.h),
            Text(
              'Loading Alert Data',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Fetching and processing alert information from all silos...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: Colors.red.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              'Failed to Load Alerts',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _handleManualRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade500,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: Text(
                _refreshing ? 'Retrying...' : 'Retry',
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsContent() {
    return Column(
      children: [
        // Alert Summary Cards
        _buildAlertSummary(),
        
        // Alerts List
        Expanded(
          child: _alertSilos.isEmpty ? _buildNoAlertsState() : _buildAlertsList(),
        ),
        
        // Pagination Controls
        if (_pagination != null && _pagination!.totalPages > 1)
          _buildPaginationControls(),
      ],
    );
  }

  Widget _buildAlertSummary() {
    final criticalCount = _alertSilos.where((s) => s.priority == AlertPriority.critical).length;
    final warningCount = _alertSilos.where((s) => s.priority == AlertPriority.warning).length;
    final disconnectCount = _alertSilos.where((s) => s.alertType == AlertType.disconnect).length;

    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Critical Alerts',
              criticalCount.toString(),
              Icons.error,
              Colors.red.shade50,
              Colors.red.shade500,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildSummaryCard(
              'Warning Alerts',
              warningCount.toString(),
              Icons.warning,
              Colors.orange.shade50,
              Colors.orange.shade500,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildSummaryCard(
              'Disconnect Alerts',
              disconnectCount.toString(),
              Icons.link_off,
              Colors.grey.shade50,
              Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20.sp),
          SizedBox(height: 4.h),
          Text(
            count,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.sp,
              color: iconColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAlertsState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64.sp,
              color: Colors.green.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              'No Alerts',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'No temperature alerts detected. All silos are operating safely.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _alertSilos.length,
      itemBuilder: (context, index) {
        final alert = _alertSilos[index];
        return _buildAlertCard(alert);
      },
    );
  }

  Widget _buildAlertCard(ProcessedAlert alert) {
    final bgColor = _parseColor(alert.siloColor);
    final isColorDark = _isColorDark(alert.siloColor);
    final textColor = isColorDark ? Colors.white : Colors.black;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: bgColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with silo number and status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _getStatusIcon(alert.overallStatus),
                    SizedBox(width: 8.w),
                    Text(
                      'Silo ${alert.siloNumber}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                _getStatusBadge(alert.priority),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            // Temperature summary
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isColorDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Max Temperature',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        '${alert.maxTemp.toStringAsFixed(1)}°C',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Alert Sensors',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        '${alert.alertCount}/8',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12.h),
            
            // Sensor grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8.w,
                mainAxisSpacing: 8.h,
                childAspectRatio: 1.2,
              ),
              itemCount: alert.sensorReadings.length,
              itemBuilder: (context, index) {
                final sensor = alert.sensorReadings[index];
                return _buildSensorTile(sensor, index + 1);
              },
            ),
            
            SizedBox(height: 12.h),
            
            // Alert details (Active Since, Duration, Affected Levels)
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isColorDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Since
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14.sp,
                        color: textColor.withOpacity(0.8),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Active Since:',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _formatDateTime(alert.activeSince),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: textColor.withOpacity(0.9),
                    ),
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  // Duration
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 14.sp,
                        color: textColor.withOpacity(0.8),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Duration:',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        alert.duration,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: textColor.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  // Affected Levels
                  if (alert.affectedLevels.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.layers,
                          size: 14.sp,
                          color: textColor.withOpacity(0.8),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Affected Levels:',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: textColor.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          alert.affectedLevels.join(', '),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: textColor.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            SizedBox(height: 12.h),
            
            // Status message
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: alert.priority == AlertPriority.critical 
                    ? Colors.red.shade100 
                    : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    alert.priority == AlertPriority.critical 
                        ? Icons.error 
                        : Icons.warning,
                    color: alert.priority == AlertPriority.critical 
                        ? Colors.red.shade800 
                        : Colors.orange.shade800,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      alert.priority == AlertPriority.critical
                          ? '🚨 Immediate attention required - Critical temperature detected'
                          : '⚠️ Monitor closely - Temperature warning detected',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: alert.priority == AlertPriority.critical 
                            ? Colors.red.shade800 
                            : Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorTile(SensorReading sensor, int sensorNumber) {
    Color sensorColor;
    switch (sensor.status) {
      case AlertStatus.red:
        sensorColor = Colors.red.shade500;
        break;
      case AlertStatus.yellow:
        sensorColor = Colors.orange.shade500;
        break;
      case AlertStatus.ok:
        sensorColor = Colors.green.shade500;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: sensorColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'S$sensorNumber',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            sensor.value == -127 ? 'N/A' : '${sensor.value.toStringAsFixed(1)}°',
            style: TextStyle(
              fontSize: 9.sp,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(AlertStatus status) {
    switch (status) {
      case AlertStatus.red:
        return Icon(Icons.error, color: Colors.red.shade500, size: 20.sp);
      case AlertStatus.yellow:
        return Icon(Icons.warning, color: Colors.orange.shade500, size: 20.sp);
      case AlertStatus.ok:
        return Icon(Icons.check_circle, color: Colors.green.shade500, size: 20.sp);
    }
  }

  Widget _getStatusBadge(AlertPriority priority) {
    Color bgColor;
    String text;
    
    switch (priority) {
      case AlertPriority.critical:
        bgColor = Colors.red.shade500;
        text = 'Critical';
        break;
      case AlertPriority.warning:
        bgColor = Colors.orange.shade500;
        text = 'Warning';
        break;
      case AlertPriority.normal:
        bgColor = Colors.green.shade500;
        text = 'Normal';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _parseColor(String colorHex) {
    try {
      String hex = colorHex.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (e) {
      // Fall back to white if parsing fails
    }
    return Colors.white;
  }

  bool _isColorDark(String color) {
    try {
      String hex = color.replaceFirst('#', '');
      if (hex.length == 6) {
        final r = int.parse(hex.substring(0, 2), radix: 16);
        final g = int.parse(hex.substring(2, 4), radix: 16);
        final b = int.parse(hex.substring(4, 6), radix: 16);
        
        // Calculate luminance
        final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
        return luminance < 0.5;
      }
    } catch (e) {
      // Fall back to false if parsing fails
    }
    return false;
  }

  String _formatDateTime(DateTime dateTime) {
    // Format like: 10/13/2025, 07:15:40
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    
    return '$month/$day/$year, $hour:$minute:$second';
  }

  Widget _buildPaginationControls() {
    if (_pagination == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Page info
          Text(
            'Showing ${((_currentPage - 1) * _itemsPerPage) + 1} to ${_currentPage * _itemsPerPage} of ${_pagination!.totalItems} alerts',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 12.h),
          
          // Pagination buttons (matching React app style)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.w,
            children: [
              // Previous button
              _buildPaginationButton(
                'Previous',
                _pagination!.hasPreviousPage ? () => _handlePageChange(_currentPage - 1) : null,
                isActive: false,
                icon: Icons.chevron_left,
              ),
              
              // Page numbers (show 5 pages max)
              ..._buildPageNumbers(),
              
              // Next button
              _buildPaginationButton(
                'Next',
                _pagination!.hasNextPage ? () => _handlePageChange(_currentPage + 1) : null,
                isActive: false,
                icon: Icons.chevron_right,
                iconAfter: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton(
    String text,
    VoidCallback? onPressed, {
    bool isActive = false,
    IconData? icon,
    bool iconAfter = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.blue.shade500 : Colors.grey.shade200,
        foregroundColor: isActive ? Colors.white : Colors.grey.shade700,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        minimumSize: Size(40.w, 32.h),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null && !iconAfter) Icon(icon, size: 14.sp),
          if (icon != null && !iconAfter) SizedBox(width: 4.w),
          Text(text, style: TextStyle(fontSize: 11.sp)),
          if (icon != null && iconAfter) SizedBox(width: 4.w),
          if (icon != null && iconAfter) Icon(icon, size: 14.sp),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    if (_pagination == null) return [];
    
    final List<Widget> pages = [];
    final totalPages = _pagination!.totalPages;
    final current = _currentPage;
    
    // Show first page if current page is far from start
    if (current > 3) {
      pages.add(_buildPaginationButton(
        '1',
        () => _handlePageChange(1),
        isActive: current == 1,
      ));
      if (current > 4) {
        pages.add(Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          child: Text('...', style: TextStyle(fontSize: 11.sp)),
        ));
      }
    }
    
    // Show pages around current page
    final start = (current - 2).clamp(1, totalPages);
    final end = (current + 2).clamp(1, totalPages);
    
    for (int i = start; i <= end; i++) {
      pages.add(_buildPaginationButton(
        i.toString(),
        () => _handlePageChange(i),
        isActive: current == i,
      ));
    }
    
    // Show last page if current page is far from end
    if (current < totalPages - 2) {
      if (current < totalPages - 3) {
        pages.add(Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          child: Text('...', style: TextStyle(fontSize: 11.sp)),
        ));
      }
      pages.add(_buildPaginationButton(
        totalPages.toString(),
        () => _handlePageChange(totalPages),
        isActive: current == totalPages,
      ));
    }
    
    return pages;
  }
}
