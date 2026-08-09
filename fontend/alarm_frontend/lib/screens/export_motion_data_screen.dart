import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/primary_button.dart';
import 'package:alarm_frontend/components/export_format_selector.dart';
import 'package:alarm_frontend/components/option_toggle_row.dart';

class ExportMotionDataScreen extends StatefulWidget {
  const ExportMotionDataScreen({super.key});

  @override
  State<ExportMotionDataScreen> createState() => _ExportMotionDataScreenState();
}

class _ExportMotionDataScreenState extends State<ExportMotionDataScreen> {
  String _selectedFormat = 'CSV'; // CSV or JSON
  bool _includeHeaders = true;
  bool _includeTimestamps = true;
  bool _isExporting = false;
  bool _isSharing = false;

  Future<void> _onExport() async {
    setState(() => _isExporting = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _isExporting = false);
  }

  Future<void> _onShare() async {
    setState(() => _isSharing = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _isSharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Export Motion Data', style: AppTextStyles.heading),
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Last 7 Days',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(height: 1, color: theme.dividerColor),
                const SizedBox(height: 16),

                const Text(
                  'Format',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                ExportFormatSelector(
                  formats: const ['CSV', 'JSON'],
                  selectedFormat: _selectedFormat,
                  onFormatChanged: (format) => setState(() => _selectedFormat = format),
                ),

                const SizedBox(height: 20),
                Divider(height: 1, color: theme.dividerColor),
                const SizedBox(height: 16),

                const Text(
                  'Options',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                OptionToggleRow(
                  label: 'Include headers',
                  value: _includeHeaders,
                  onChanged: (v) => setState(() => _includeHeaders = v),
                ),
                const SizedBox(height: 8),
                OptionToggleRow(
                  label: 'Include timestamps',
                  value: _includeTimestamps,
                  onChanged: (v) => setState(() => _includeTimestamps = v),
                ),

                const SizedBox(height: 20),

                PrimaryButton(
                  text: 'Export Data',
                  isLoading: _isExporting,
                  onPressed: _onExport,
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSharing ? null : _onShare,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: BorderSide(color: theme.dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isSharing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5) ?? AppColors.textSecondary,
                            ),
                          )
                        : Text(
                            'Share',
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
