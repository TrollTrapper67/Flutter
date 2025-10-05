// lib/widgets/loading.dart
import 'package:flutter/material.dart';

Future<void> showLoading(BuildContext ctx, {String text = 'Loading...'}) {
  return showDialog<void>(
    context: ctx,
    barrierDismissible: false,
    builder: (_) => WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Flexible(child: Text(text)),
          ],
        ),
      ),
    ),
  );
}

void hideLoading(BuildContext ctx) {
  if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
}

