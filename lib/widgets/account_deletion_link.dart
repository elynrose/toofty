import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_links.dart';
import '../theme/app_colors.dart';
import '../utils/open_url.dart';

/// Link to the account deletion request page (Google Play requirement).
class AccountDeletionLink extends StatelessWidget {
  const AccountDeletionLink({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return TextButton(
        onPressed: () => openExternalUrl(context, AppLinks.accountDeletionUrl),
        child: Text(
          'Delete account & data',
          style: GoogleFonts.nunito(
            fontSize: 13,
            color: AppColors.textPrimary.withValues(alpha: 0.65),
            decoration: TextDecoration.underline,
          ),
        ),
      );
    }

    return TextButton.icon(
      onPressed: () => openExternalUrl(context, AppLinks.accountDeletionUrl),
      icon: Icon(
        Icons.delete_outline,
        size: 20,
        color: AppColors.textPrimary.withValues(alpha: 0.7),
      ),
      label: Text(
        'Request account deletion',
        style: GoogleFonts.nunito(
          color: AppColors.textPrimary.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
