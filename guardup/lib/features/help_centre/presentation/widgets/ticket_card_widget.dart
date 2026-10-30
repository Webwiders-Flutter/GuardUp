import 'package:flutter/material.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/utils/extensions/size_extensions.dart';

import '../../domain/entities/ticket_entity.dart';

class TicketCardWidget extends StatelessWidget {
  final String ticketId;
  final String category;
  final String date;
  final TicketStatus status;

  const TicketCardWidget({
    super.key,
    required this.ticketId,
    required this.category,
    required this.date,
    required this.status,
  });

  String _getStatusText(BuildContext context) {
    switch (status) {
      case TicketStatus.inProgress:
        return context.l10n.inProgress;
      case TicketStatus.pending:
        return context.l10n.pending;
      case TicketStatus.closed:
        return context.l10n.closed;
    }
  }

  Color _getStatusBgColor() {
    switch (status) {
      case TicketStatus.inProgress:
        return AppColors.surfaceLight; // White-ish
      case TicketStatus.pending:
        return const Color(0xFFFFE0B2); // Light orange/yellow
      case TicketStatus.closed:
        return const Color(0xFFC8E6C9); // Light green
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lightBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticketId,
                  style: const TextStyle(
                    color: AppColors.whiteColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                4.height,
                Text(
                  category,
                  style: const TextStyle(
                    color: AppColors.headingTextFieldColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusBgColor(),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getStatusText(context),
                  style: const TextStyle(
                    color: AppColors.blackColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              8.height,
              Text(
                date,
                style: const TextStyle(
                  color: AppColors.headingTextFieldColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
