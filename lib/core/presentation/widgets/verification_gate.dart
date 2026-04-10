import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps any action or screen requiring the user to be approved.
/// Shows a blocking banner and redirects to /verification if not approved.
class VerificationGate extends ConsumerWidget {
  final Widget child;
  final String actionDescription; // e.g. 'نشر المشاريع'

  const VerificationGate({
    super.key,
    required this.child,
    required this.actionDescription,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // بناءً على طلب المستخدم: نظام التحقق لا يلغي أي ميزة.
    // لذلك، نُرجع الـ child مباشرة بدون القفل.
    return child;
  }
}



