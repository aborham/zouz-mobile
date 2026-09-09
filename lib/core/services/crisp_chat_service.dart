import 'package:crisp_chat/crisp_chat.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zouz_mobile/core/config/app_config.dart';

class CrispChatService {
  CrispChatService._();

  static bool _opening = false;

  static String? _optional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static String? _validEmail(String? value) {
    final email = _optional(value);
    if (email == null) return null;
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email) ? email : null;
  }

  static Future<void> open(
    BuildContext context, {
    String? email,
    String? name,
    String? phone,
  }) async {
    if (_opening) return;
    _opening = true;

    final safeEmail = _validEmail(email);
    final safeName = _optional(name);
    final safePhone = _optional(phone);
    final hasUserData =
        safeEmail != null || safeName != null || safePhone != null;

    try {
      await FlutterCrispChat.openCrispChat(
        config: CrispConfig(
          websiteID: AppConfig.crispWebsiteId,
          user: hasUserData
              ? User(email: safeEmail, nickName: safeName, phone: safePhone)
              : null,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('[Crisp] Failed to open chat: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('support.chat_unavailable'.tr())),
        );
      }
    } finally {
      _opening = false;
    }
  }
}
