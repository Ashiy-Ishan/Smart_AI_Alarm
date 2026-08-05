import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/primary_button.dart';
import 'package:alarm_frontend/components/info_card.dart';
import 'package:alarm_frontend/components/custom_checkbox_tile.dart';
import 'package:alarm_frontend/components/warning_card.dart';

class ClearHistoryScreen extends StatefulWidget {
  const ClearHistoryScreen({super.key});

  @override
  State<ClearHistoryScreen> createState() => _ClearHistoryScreenState();
}

class _ClearHistoryScreenState extends State<ClearHistoryScreen> {
  bool _isClearing = false;

  final List<String> _historyItems = [
    'Search History',
    'Activity Records',
    'Motion Logs',
    'Email Cache',
    'AI Predictions',
    'Recent Notifications',
  ];

  late final List<bool> _checked;

  @override
  void initState() {
    super.initState();
    _checked = List.filled(_historyItems.length, true);
  }

  bool get _anySelected => _checked.any((v) => v);

  Future<void> _onClearSelected() async {
    setState(() => _isClearing = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isClearing = false;
        for (int i = 0; i < _checked.length; i++) {
          _checked[i] = false;
        }
      });
    }
  }

  void _onCancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Clear History', style: AppTextStyles.heading),
        titleSpacing: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // History Management Header Card
            const InfoCard(
              title: 'History Management',
              description: 'Manage and remove stored activity data\nfrom your account',
            ),

            const SizedBox(height: 14),

            // Checklist Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: List.generate(_historyItems.length, (i) {
                  final isLast = i == _historyItems.length - 1;
                  return Column(
                    children: [
                      CustomCheckboxTile(
                        label: _historyItems[i],
                        isChecked: _checked[i],
                        onChanged: (val) => setState(() => _checked[i] = val),
                      ),
                      if (!isLast)
                        const Divider(
                          height: 1,
                          color: AppColors.border,
                          indent: 16,
                          endIndent: 16,
                        ),
                    ],
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            // Warning Card
            const WarningCard(
              title: 'Warning:',
              description: 'Cleaning history will permanently remove\nselected records',
            ),

            const Spacer(),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A3F4B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    text: 'Clear Selected',
                    isLoading: _isClearing,
                    onPressed: _anySelected ? _onClearSelected : () {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
