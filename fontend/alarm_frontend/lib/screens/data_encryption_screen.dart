import 'package:flutter/material.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:alarm_frontend/components/security_overview_card.dart';
import 'package:alarm_frontend/components/custom_checkbox_tile.dart';
import 'package:alarm_frontend/components/key_status_card.dart';

class DataEncryptionScreen extends StatefulWidget {
  const DataEncryptionScreen({super.key});

  @override
  State<DataEncryptionScreen> createState() => _DataEncryptionScreenState();
}

class _DataEncryptionScreenState extends State<DataEncryptionScreen> {
  final TextEditingController _passphraseController = TextEditingController();
  bool _isUpdating = false;

  final List<String> _encryptedTypes = [
    'Sleep Analytics',
    'Motion Logs',
    'Account & profile data',
    'Device Environment data',
  ];

  late final List<bool> _encryptedChecked;

  @override
  void initState() {
    super.initState();
    _encryptedChecked = List.filled(_encryptedTypes.length, true);
  }

  Future<void> _onUpdatePassphrase() async {
    setState(() => _isUpdating = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _isUpdating = false);
  }

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

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
        title: const Text('Data Encryption', style: AppTextStyles.heading),
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),

          // Security Overview Card
          const SecurityOverviewCard(
            isEncryptionActive: true,
          ),

          const SizedBox(height: 16),

          // Encryption Data Types Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Encryption Data types',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_encryptedTypes.length, (i) {
                  return CustomCheckboxTile(
                    label: _encryptedTypes[i],
                    isChecked: _encryptedChecked[i],
                    onChanged: (val) => setState(() => _encryptedChecked[i] = val),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Key Status Card
          KeyStatusCard(
            controller: _passphraseController,
            isUpdating: _isUpdating,
            onUpdatePassphrase: _onUpdatePassphrase,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
