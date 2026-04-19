import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zouz_mobile/features/dashboard/providers/navigation_provider.dart';
import 'package:zouz_mobile/core/theme/colors.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  MobileScannerController cameraController = MobileScannerController(
    autoStart: false,
    formats: [BarcodeFormat.qrCode],
  );
  bool _isProcessing = false;
  PermissionStatus _cameraPermissionStatus = PermissionStatus.denied;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    // Initial check but don't start camera unless we are at index 1
    // The listener below will handle the logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(navigationProvider) == 1) {
        _checkPermission();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final currentIndex = ref.read(navigationProvider);
      if (currentIndex == 1) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _checkPermission();
        });
      }
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (cameraController.value.isRunning) {
        cameraController.stop();
      }
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (!mounted) return;

    setState(() {
      _cameraPermissionStatus = status;
    });

    if (status.isGranted || status.isProvisional) {
      try {
        if (!cameraController.value.isRunning && !cameraController.value.isStarting) {
          await cameraController.start();
        }
      } catch (e) {
        debugPrint('Zouz: Error starting camera: $e');
      }
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() => _cameraPermissionStatus = status);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!;
      setState(() => _isProcessing = true);
      
      // Visual feedback: Subtle haptic if possible, or just immediate logic
      try {
        final uri = Uri.parse(code);
        String? tenantSlug;
        String? standId;

        if (uri.pathSegments.contains('menu')) {
          final index = uri.pathSegments.indexOf('menu');
          if (index + 1 < uri.pathSegments.length) {
            tenantSlug = uri.pathSegments[index + 1];
          }
          standId = uri.queryParameters['standId'];
        } else {
          tenantSlug = code;
        }

        if (tenantSlug != null && tenantSlug.isNotEmpty) {
          final query = standId != null ? '?standId=$standId' : '';
          context.push('/menu/$tenantSlug$query').then((_) {
            if (mounted && ref.read(navigationProvider) == 1) {
              setState(() => _isProcessing = false);
              cameraController.start();
            } else if (mounted) {
              setState(() => _isProcessing = false);
            }
          });
        } else {
          setState(() => _isProcessing = false);
        }
      } catch (e) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to tab changes to start/stop camera
    ref.listen(navigationProvider, (previous, next) {
      if (next == 1 && previous != 1) {
        // Switched TO Scanner tab
        _checkPermission();
      } else if (next != 1 && previous == 1) {
        // Switched AWAY FROM Scanner tab
        if (cameraController.value.isRunning) {
          cameraController.stop();
        }
      }
    });

    final bool isGranted = _cameraPermissionStatus.isGranted || _cameraPermissionStatus.isProvisional;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera View
          if (isGranted)
            MobileScanner(
              controller: cameraController,
              onDetect: _onDetect,
            )
          else
            _buildPermissionPlaceholder(),

          // 2. Animated Overlay
          if (isGranted)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ScannerOverlayPainter(
                    scanLinePosition: _animationController.value,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),

          // 3. Floating Header (Title + Glass Buttons)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGlassButton(
                  icon: Icons.close,
                  onPressed: () => context.pop(),
                ),
                Text(
                  'dashboard.scan_stand'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  children: [
                    _buildGlassButton(
                      icon: Icons.flash_on,
                      onPressed: () => cameraController.toggleTorch(),
                    ),
                    const SizedBox(width: 12),
                    _buildGlassButton(
                      icon: Icons.flip_camera_ios,
                      onPressed: () => cameraController.switchCamera(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4. Floating Guidance Card
          if (isGranted)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 100, // Adjusted for notch bottom bar
              left: 24,
              right: 24,
              child: _buildGuidanceCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onPressed}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 20),
            onPressed: onPressed,
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildGuidanceCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_2, color: AppColors.secondary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${"scanner.align_qr".tr().split(' ').first} QR Code',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'scanner.align_qr'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white38),
            const SizedBox(height: 24),
            Text(
              'scanner.permission_required'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 32),
            if (_cameraPermissionStatus.isPermanentlyDenied)
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () => openAppSettings(),
                    child: Text('scanner.open_settings'.tr()),
                  ),
                  TextButton(
                    onPressed: _checkPermission,
                    child: Text('scanner.check_status'.tr(), style: const TextStyle(color: Colors.white70)),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: _requestPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('scanner.grant_permission'.tr()),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final double scanLinePosition;

  _ScannerOverlayPainter({required this.scanLinePosition});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Cutout Dimensions (Optimized for Menu Stands)
    final scanAreaWidth = size.width * 0.75;
    final scanAreaHeight = scanAreaWidth; // Square
    final center = Offset(size.width / 2, size.height * 0.45); // Centered slightly higher

    final cutOutRect = Rect.fromCenter(
      center: center,
      width: scanAreaWidth,
      height: scanAreaHeight,
    );

    // 1. Draw the dark background with cutout
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(cutOutRect, const Radius.circular(32))),
      ),
      paint,
    );

    // 2. Draw animated scan line
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.secondary.withValues(alpha: 0.01),
          AppColors.secondary.withValues(alpha: 0.6),
          AppColors.secondary.withValues(alpha: 0.01),
        ],
      ).createShader(Rect.fromLTWH(cutOutRect.left, cutOutRect.top, cutOutRect.width, 2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final lineY = cutOutRect.top + (cutOutRect.height * scanLinePosition);
    canvas.drawLine(Offset(cutOutRect.left + 20, lineY), Offset(cutOutRect.right - 20, lineY), linePaint);

    // 3. Draw premium corner accents
    final cornerPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    final cornerLength = scanAreaWidth * 0.12;

    // Helper to draw a corner path
    void drawCorner(Offset p1, Offset corner, Offset p2) {
      canvas.drawPath(
        Path()
          ..moveTo(p1.dx, p1.dy)
          ..quadraticBezierTo(corner.dx, corner.dy, p2.dx, p2.dy),
        cornerPaint,
      );
    }

    // Top Left
    drawCorner(
      Offset(cutOutRect.left, cutOutRect.top + cornerLength),
      Offset(cutOutRect.left, cutOutRect.top),
      Offset(cutOutRect.left + cornerLength, cutOutRect.top),
    );
    // Top Right
    drawCorner(
      Offset(cutOutRect.right - cornerLength, cutOutRect.top),
      Offset(cutOutRect.right, cutOutRect.top),
      Offset(cutOutRect.right, cutOutRect.top + cornerLength),
    );
    // Bottom Left
    drawCorner(
      Offset(cutOutRect.left, cutOutRect.bottom - cornerLength),
      Offset(cutOutRect.left, cutOutRect.bottom),
      Offset(cutOutRect.left + cornerLength, cutOutRect.bottom),
    );
    // Bottom Right
    drawCorner(
      Offset(cutOutRect.right - cornerLength, cutOutRect.bottom),
      Offset(cutOutRect.right, cutOutRect.bottom),
      Offset(cutOutRect.right, cutOutRect.bottom - cornerLength),
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanLinePosition != scanLinePosition;
  }
}
