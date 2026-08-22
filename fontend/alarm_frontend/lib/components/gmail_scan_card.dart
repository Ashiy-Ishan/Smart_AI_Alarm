import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'dart:convert';
import 'package:alarm_frontend/screens/email_screen.dart';

enum MeetingStatus { scheduled, canceled, updated, unknown }

class GmailScanCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final MeetingStatus status;
  final String? fullBody;

  const GmailScanCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.status = MeetingStatus.unknown,
    this.fullBody,
  });

  @override
  State<GmailScanCard> createState() => _GmailScanCardState();
}

class _GmailScanCardState extends State<GmailScanCard> {
  bool _isExpanded = false;

  Color _getStatusColor() {
    switch (widget.status) {
      case MeetingStatus.scheduled:
        return Colors.greenAccent.shade700;
      case MeetingStatus.canceled:
        return Colors.redAccent;
      case MeetingStatus.updated:
        return Colors.orangeAccent;
      case MeetingStatus.unknown:
        return AppColors.primary;
    }
  }

  String _getStatusText() {
    switch (widget.status) {
      case MeetingStatus.scheduled:
        return "SCHEDULED";
      case MeetingStatus.canceled:
        return "CANCELED";
      case MeetingStatus.updated:
        return "UPDATED";
      case MeetingStatus.unknown:
        return "PRIORITY";
    }
  }

  String _decodeBody(String? base64Body) {
    if (base64Body == null || base64Body.isEmpty) return "No content available.";
    try {
      // Gmail base64url encoding uses '-' instead of '+' and '_' instead of '/'
      String normalized = base64Body.replaceAll('-', '+').replaceAll('_', '/');
      // Add padding if necessary
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      return utf8.decode(base64.decode(normalized));
    } catch (e) {
      return "Error decoding email content.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        if (widget.fullBody != null) {
          setState(() => _isExpanded = !_isExpanded);
        } else {
          Navigator.of(
            context,
            rootNavigator: true,
          ).push(MaterialPageRoute(builder: (_) => const EmailScreen()));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isExpanded ? AppColors.primary : theme.dividerColor,
            width: _isExpanded ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _getStatusColor().withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Icon(
                      widget.status == MeetingStatus.canceled
                          ? Icons.event_busy
                          : Icons.event_available,
                      color: _getStatusColor(),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _getStatusText(),
                            style: TextStyle(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color:
                              theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
                              AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: _isExpanded ? 10 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5) ??
                      AppColors.textSecondary,
                  size: 18,
                ),
              ],
            ),
            if (_isExpanded && widget.fullBody != null) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                _decodeBody(widget.fullBody),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Tap to collapse",
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primary.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
