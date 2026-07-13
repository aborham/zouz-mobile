import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _showSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    // Check permission and start camera immediately since this is a standalone screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermission();
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
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _checkPermission();
      });
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

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || _showSuccess || _errorMessage != null) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      _processQRCode(barcodes.first.rawValue!);
    }
  }

  void _processQRCode(String code) {
    if (_isProcessing || _showSuccess || _errorMessage != null) return;
    try {
      final uri = Uri.parse(code);
      String? tenantSlug;
      String? standId;

      // Validation logic for Zouz QR codes
      final bool isZouzMenu = uri.pathSegments.contains('menu');
      final bool isZouzDirect = uri.host == 'zouz.app' || uri.host == 'dev.zouzapp.com';
      
      if (isZouzMenu) {
        final index = uri.pathSegments.indexOf('menu');
        if (index + 1 < uri.pathSegments.length) {
          tenantSlug = uri.pathSegments[index + 1];
        }
        standId = uri.queryParameters['standId'];
      } else if (isZouzDirect) {
        tenantSlug = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      }

      if (tenantSlug != null && tenantSlug.isNotEmpty) {
        setState(() {
          _isProcessing = true;
          _showSuccess = true;
        });
        cameraController.stop();

        final query = standId != null ? '?standId=$standId' : '';
        
        // Show success feedback for a moment before navigating
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          context.push('/menu/$tenantSlug$query').then((_) {
            if (mounted) {
              setState(() {
                _isProcessing = false;
                _showSuccess = false;
              });
              cameraController.start();
            }
          });
        });
      } else {
        _handleInvalidQr();
      }
    } catch (e) {
      _handleInvalidQr();
    }
  }

  void _showDebugScannerDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug: Simulate QR Scan'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Paste QR Code URL here',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) {
                _processQRCode(controller.text);
              }
            },
            child: const Text('Simulate Scan'),
          ),
        ],
      ),
    );
  }

  void _handleInvalidQr() {
    setState(() {
      _errorMessage = 'scanner.invalid_qr_subtitle'.tr();
    });
    
    // Auto-hide error after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _errorMessage = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    if (kDebugMode) ...[
                      _buildGlassButton(
                        icon: Icons.bug_report,
                        onPressed: _showDebugScannerDialog,
                      ),
                      const SizedBox(width: 12),
                    ],
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
          if (isGranted && !_showSuccess && _errorMessage == null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 100, // Adjusted for notch bottom bar
              left: 24,
              right: 24,
              child: _buildGuidanceCard(),
            ),

          // 5. Success Overlay
          if (_showSuccess)
            _buildSuccessOverlay(),

          // 6. Error Overlay
          if (_errorMessage != null)
            _buildErrorOverlay(),
        ],
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.green, size: 64),
              ),
              const SizedBox(height: 24),
              Text(
                'scanner.success_msg'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 100,
      left: 24,
      right: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'scanner.invalid_qr_title'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
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
    final bool isDenied = _cameraPermissionStatus.isPermanentlyDenied;
    
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 40,
          left: 24,
          right: 24,
          bottom: 40,
        ),
        child: Column(
          children: [
            // 1. Illustration Area
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: AppColors.primary,
                    size: 80,
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            
            // 2. Text Content
            Text(
              'scanner.premium_permission_title'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'scanner.premium_permission_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            
            // 3. Feature Cards
            PermissionFeaturesCard(
              icon: Icons.privacy_tip_rounded,
              title: 'scanner.privacy_focused'.tr(),
              description: 'scanner.privacy_desc'.tr(),
            ),
            const SizedBox(height: 16),
            PermissionFeaturesCard(
              icon: Icons.bolt_rounded,
              title: 'scanner.instant_setup'.tr(),
              description: 'scanner.instant_desc'.tr(),
            ),
            const SizedBox(height: 60),
            
            // 4. Action Buttons
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: isDenied ? () => openAppSettings() : _requestPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                ),
                child: Text(
                  isDenied ? 'scanner.open_settings'.tr() : 'scanner.grant_permission'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'scanner.maybe_later'.tr(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
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

class PermissionFeaturesCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const PermissionFeaturesCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
