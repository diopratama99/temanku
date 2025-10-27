import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Empty state widget with actionable CTA
/// Improves user activation and reduces drop-off (C4 fix)
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyStateWidget({
    required this.title,
    required this.description,
    required this.icon,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$title. $description',
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Illustration icon
                Container(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  decoration: BoxDecoration(
                    color: (iconColor ?? theme.colorScheme.primary).withOpacity(
                      0.08,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 80,
                    color: (iconColor ?? theme.colorScheme.primary).withOpacity(
                      0.6,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space24),

                // Title
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.space12),

                // Description
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                // Action button (if provided)
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppTheme.space32),
                  FilledButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(actionLabel!),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space24,
                        vertical: AppTheme.space16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Loading state with progress indicator
class LoadingStateWidget extends StatelessWidget {
  final String? message;

  const LoadingStateWidget({this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: message ?? 'Memuat data',
      liveRegion: true,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: AppTheme.space16),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state with retry action
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    required this.title,
    required this.message,
    this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$title. $message',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error icon
              Container(
                padding: const EdgeInsets.all(AppTheme.space24),
                decoration: BoxDecoration(
                  color: AppTheme.expenseColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.expenseColor.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              // Title
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.expenseColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space12),

              // Error message
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),

              // Retry button (if provided)
              if (onRetry != null) ...[
                const SizedBox(height: AppTheme.space24),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.expenseColor,
                    side: const BorderSide(color: AppTheme.expenseColor),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Success snackbar helper
void showSuccessSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: AppTheme.incomeColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Error snackbar helper
void showErrorSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error, color: Colors.white),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: AppTheme.expenseColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: 'Tutup',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}
