import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zouz_mobile/core/theme/colors.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  MobileScannerController cameraController = MobileScannerController(
    autoStart: false,
  );
  bool _isProcessing = false;
  PermissionStatus _cameraPermissionStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('Zouz: App Lifecycle State changed to $state');
    if (state == AppLifecycleState.resumed) {
      // Add a slight delay as iOS might not update the status immediately
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          debugPrint('Zouz: Re-checking permissions after resume...');
          _checkPermission();
        }
      });
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    debugPrint('Zouz: Checking Camera Permission Status: $status');
    if (!mounted) return;

    setState(() {
      _cameraPermissionStatus = status;
    });

    // If granted, ensure the camera starts safely
    if (status.isGranted || status.isProvisional) {
      try {
        if (!cameraController.value.isRunning &&
            !cameraController.value.isStarting) {
          await cameraController.start();
        }
      } catch (e) {
        debugPrint('Zouz: Error starting camera: $e');
      }
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    debugPrint('Zouz: Requested Camera Permission: $status');
    if (!mounted) return;
    setState(() {
      _cameraPermissionStatus = status;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!;
      setState(() => _isProcessing = true);
      cameraController.stop();

      try {
        final uri = Uri.parse(code);
        String? tenantSlug;
        String? standId;

        // Example: https://zouz.app/menu/zouz-coffee?standId=123
        if (uri.pathSegments.contains('menu')) {
          final index = uri.pathSegments.indexOf('menu');
          if (index + 1 < uri.pathSegments.length) {
            tenantSlug = uri.pathSegments[index + 1];
          }
          standId = uri.queryParameters['standId'];
        } else {
          // Fallback if it's just a slug or something else
          tenantSlug = code;
        }

        if (tenantSlug != null && tenantSlug.isNotEmpty) {
          final query = standId != null ? '?standId=$standId' : '';
          context.push('/menu/$tenantSlug$query').then((_) {
            setState(() => _isProcessing = false);
            cameraController.start();
          });
        } else {
          // Invalid code
          setState(() => _isProcessing = false);
          cameraController.start();
        }
      } catch (e) {
        // Not a valid URI or error parsing
        setState(() => _isProcessing = false);
        cameraController.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('dashboard.scan_stand'.tr()),
        actions: [
          if (_cameraPermissionStatus.isGranted ||
              _cameraPermissionStatus.isProvisional) ...[
            IconButton(
              icon: const Icon(Icons.flash_on),
              iconSize: 32.0,
              onPressed: () => cameraController.toggleTorch(),
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              iconSize: 32.0,
              onPressed: () => cameraController.switchCamera(),
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _checkPermission,
            ),
        ],
      ),
      body:
          _cameraPermissionStatus.isGranted ||
              _cameraPermissionStatus.isProvisional
          ? Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: _onDetect,
                ),
                CustomPaint(
                  painter: _ScannerOverlayPainter(),
                  child: const SizedBox.expand(),
                ),
                Positioned(
                  bottom: 60,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'scanner.align_qr'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'scanner.permission_required'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    if (_cameraPermissionStatus.isPermanentlyDenied)
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: () => openAppSettings(),
                            child: Text('scanner.open_settings'.tr()),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _checkPermission,
                            child: Text('scanner.check_status'.tr()),
                          ),
                        ],
                      )
                    else
                      ElevatedButton(
                        onPressed: _requestPermission,
                        child: Text('scanner.grant_permission'.tr()),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // The size of the cutout
    final scanAreaSize = size.width * 0.7;
    final center = Offset(size.width / 2, size.height / 2);

    final cutOutRect = Rect.fromCenter(
      center: center,
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Draw the dark background
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(
          RRect.fromRectAndRadius(cutOutRect, const Radius.circular(16)),
        ),
      ),
      paint,
    );

    // Draw corners
    final cornerPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final length = scanAreaSize * 0.1;

    // Top left
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left, cutOutRect.top + length)
        ..lineTo(cutOutRect.left, cutOutRect.top)
        ..lineTo(cutOutRect.left + length, cutOutRect.top),
      cornerPaint,
    );
    // Top right
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right - length, cutOutRect.top)
        ..lineTo(cutOutRect.right, cutOutRect.top)
        ..lineTo(cutOutRect.right, cutOutRect.top + length),
      cornerPaint,
    );
    // Bottom left
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left, cutOutRect.bottom - length)
        ..lineTo(cutOutRect.left, cutOutRect.bottom)
        ..lineTo(cutOutRect.left + length, cutOutRect.bottom),
      cornerPaint,
    );
    // Bottom right
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right - length, cutOutRect.bottom)
        ..lineTo(cutOutRect.right, cutOutRect.bottom)
        ..lineTo(cutOutRect.right, cutOutRect.bottom - length),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
