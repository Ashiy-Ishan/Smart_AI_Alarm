import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Data Encryption', style: AppTextStyles.heading),
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),
          const SecurityOverviewCard(isEncryptionActive: true),
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
                const Text(
                  'Encryption Data types',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...List.generate(_encryptedTypes.length, (i) {
                  return CustomCheckboxTile(
                    label: _encryptedTypes[i],
                    isChecked: _encryptedChecked[i],
                    onChanged: (val) =>
                        setState(() => _encryptedChecked[i] = val),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
