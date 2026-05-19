import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/permission_features_card.dart';

class ScannerPermissionSheet extends StatefulWidget {
  final PermissionStatus initialStatus;
  final VoidCallback onGranted;

  const ScannerPermissionSheet({
    super.key,
    required this.initialStatus,
    required this.onGranted,
  });

  @override
  State<ScannerPermissionSheet> createState() => _ScannerPermissionSheetState();
}

class _ScannerPermissionSheetState extends State<ScannerPermissionSheet> with WidgetsBindingObserver {
  late PermissionStatus _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _status = widget.initialStatus;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionSilently();
    }
  }

  Future<void> _checkPermissionSilently() async {
    final status = await Permission.camera.status;
    if (!mounted) return;
    
    if (status.isGranted || status.isProvisional) {
      Navigator.pop(context);
      widget.onGranted();
    } else {
      setState(() {
        _status = status;
      });
    }
  }

  Future<void> _handleAction() async {
    if (_status.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      final result = await Permission.camera.request();
      if (!mounted) return;
      
      setState(() {
        _status = result;
      });

      if (result.isGranted || result.isProvisional) {
        Navigator.pop(context);
        widget.onGranted();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDenied = _status.isPermanentlyDenied;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          
          // Header
          Text(
            'scanner.premium_permission_title'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'scanner.premium_permission_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          
          // Features
          PermissionFeaturesCard(
            icon: Icons.privacy_tip_rounded,
            title: 'scanner.privacy_focused'.tr(),
            description: 'scanner.privacy_desc'.tr(),
          ),
          const SizedBox(height: 12),
          PermissionFeaturesCard(
            icon: Icons.bolt_rounded,
            title: 'scanner.instant_setup'.tr(),
            description: 'scanner.instant_desc'.tr(),
          ),
          const SizedBox(height: 40),
          
          // Actions
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _handleAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                isDenied ? 'scanner.open_settings'.tr() : 'scanner.grant_permission'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'scanner.maybe_later'.tr(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
