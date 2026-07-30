import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../pages/document_viewer_page.dart';

/// Booking documents for a shipment.
///
/// The shipment-details API exposes exactly one document per booking (the
/// generated booking PDF), so this renders that single real entry rather than
/// a fixed list of document types.
class TripDocumentsCard extends StatelessWidget {
  final String? documentUrl;
  final String bookingId;

  const TripDocumentsCard({
    super.key,
    required this.documentUrl,
    required this.bookingId,
  });

  bool get _hasDocument =>
      documentUrl != null && documentUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Documents',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          if (_hasDocument)
            _DocumentRow(
              title: 'Booking Confirmation',
              subtitle: 'PDF · Booking $bookingId',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentViewerPage(
                    url: documentUrl!.trim(),
                    title: 'Booking Confirmation',
                  ),
                ),
              ),
            )
          else
            const _NoDocuments(),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DocumentRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.danger,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.visibility_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoDocuments extends StatelessWidget {
  const _NoDocuments();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.description_outlined,
            size: 20,
            color: AppColors.textLight,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No documents have been published for this shipment yet.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: AppColors.textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
