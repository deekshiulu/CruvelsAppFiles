import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Force the Android status and navigation bars to be transparent/dark immediately
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparent status bar
      statusBarIconBrightness: Brightness.light, // White icons (battery, clock)
      statusBarBrightness: Brightness.dark, // For iOS light text
      systemNavigationBarColor: Color(
        0xFF0B132B,
      ), // Match Next.js dark background
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Initialize Firebase FCM and notification services
  await NotificationService.initialize();

  runApp(const CruvelsApp());
}

class CruvelsApp extends StatelessWidget {
  const CruvelsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PortalScreen(),
    );
  }
}

class PortalScreen extends StatefulWidget {
  const PortalScreen({super.key});

  @override
  State<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends State<PortalScreen> {
  late final WebViewController _controller;

  // Emulator mapping: 'http://10.0.2.2:3005' reaches your PC's localhost:3005
  // If your website is deployed online, use 'https://your-production-url.com'
  final String portalUrl = 'https://sublevel-giving-unfounded.ngrok-free.dev';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B132B))
      ..loadRequest(
        Uri.parse(portalUrl),
        headers: {'Bypass-Tunnel-Reminder': 'true'},
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF0B132B),
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (await _controller.canGoBack()) {
            await _controller.goBack();
          } else {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF0B132B),
          body: SafeArea(
            top: true,
            bottom: false,
            child: WebViewWidget(controller: _controller),
          ),
        ),
      ),
    );
  }
}
