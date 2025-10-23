import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewApp extends StatefulWidget {
  const WebViewApp({super.key});

  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  int _selectedIndex = 0;
  late List<WebViewController> _controllers;

  // React app base URL - GitHub Pages deployment
  static const String baseUrl = 'https://basharagb.github.io/replica-view-studio';
  
  final List<WebViewPage> _pages = [
    WebViewPage(
      title: 'Dashboard',
      url: '$baseUrl/',
      icon: Icons.dashboard,
    ),
    WebViewPage(
      title: 'Analytics',
      url: '$baseUrl/analytics',
      icon: Icons.analytics,
    ),
    WebViewPage(
      title: 'Reports',
      url: '$baseUrl/reports',
      icon: Icons.assessment,
    ),
    WebViewPage(
      title: 'Maintenance',
      url: '$baseUrl/maintenance',
      icon: Icons.build,
    ),
    WebViewPage(
      title: 'Settings',
      url: '$baseUrl/settings',
      icon: Icons.settings,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _controllers = _pages.map((page) {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // Update loading bar
            },
            onPageStarted: (String url) {
              // Page started loading
            },
            onPageFinished: (String url) {
              // Page finished loading
            },
            onWebResourceError: (WebResourceError error) {
              // Handle error
            },
          ),
        )
        ..loadRequest(Uri.parse(page.url));
      return controller;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _controllers.map((controller) {
            return WebViewWidget(controller: controller);
          }).toList(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF2196F3),
        unselectedItemColor: Colors.grey,
        items: _pages.map((page) {
          return BottomNavigationBarItem(
            icon: Icon(page.icon),
            label: page.title,
          );
        }).toList(),
      ),
    );
  }
}

class WebViewPage {
  final String title;
  final String url;
  final IconData icon;

  const WebViewPage({
    required this.title,
    required this.url,
    required this.icon,
  });
}
