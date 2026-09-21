import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/trade_entry.dart';
import '../providers/challenges_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/challenge_math.dart';
import '../utils/sample_data.dart';

const _presetRules = [
  'Risk max 1% per trade',
  'Always use a stop loss',
  'Maximum 3 trades per day',
  'Stop trading after 2 consecutive losses',
  'No revenge trades',
  'No FOMO entries',
  'Follow my setup only',
  'No trade without a clear reason',
];

class ChallengeFormScreen extends StatefulWidget {
  const ChallengeFormScreen({super.key});

  @override
  State<ChallengeFormScreen> createState() => _ChallengeFormScreenState();
}

class _ChallengeFormScreenState extends State<ChallengeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  final _startCtrl = TextEditingController(text: '10');
  final _targetCtrl = TextEditingController(text: '1000');
  final _customDaysCtrl = TextEditingController();
  late final TextEditingController _maxDailyLossCtrl;
  final _customRuleCtrl = TextEditingController();
  int? _selectedPreset = 20;
  DateTime _startDate = dateOnly(DateTime.now());
  final Set<String> _selectedPresetRules = {};
  final List<String> _customRules = [];
  bool _includeSampleTrades = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: '\$10 → \$1,000 Challenge');
    _maxDailyLossCtrl = TextEditingController(text: '2');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _startCtrl.dispose();
    _targetCtrl.dispose();
    _customDaysCtrl.dispose();
    _maxDailyLossCtrl.dispose();
    _customRuleCtrl.dispose();
    super.dispose();
  }

  void _autofillSampleData() {
    setState(() {
      _nameCtrl.text = '\$10 → \$1,000 Challenge';
      _startCtrl.text = '10';
      _targetCtrl.text = '1000';
      _selectedPreset = 20;
      _startDate = dateOnly(DateTime.now().subtract(const Duration(days: 13)));
      _maxDailyLossCtrl.text = '2';
      _includeSampleTrades = true;
      _selectedPresetRules.clear();
      _selectedPresetRules.addAll([
        'Risk max 1% per trade',
        'Always use a stop loss',
        'Stop trading after 2 consecutive losses',
      ]);
    });
  }

  void _addCustomRule() {
    final rule = _customRuleCtrl.text.trim();
    if (rule.isEmpty) return;
    setState(() {
      _customRules.add(rule);
      _customRuleCtrl.clear();
    });
  }

  int? get _durationDays {
    if (_selectedPreset != null) return _selectedPreset;
    return int.tryParse(_customDaysCtrl.text);
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = dateOnly(picked));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final duration = _durationDays;
    if (duration == null || duration <= 0) return;

    final maxDailyLossInput = double.tryParse(_maxDailyLossCtrl.text);
    final sampleTrades = _includeSampleTrades ? generateSampleTrades(_startDate) : <TradeEntry>[];

    final challengesProv = context.read<ChallengesProvider>();
    final profileProv = context.read<ProfileProvider>();

    await challengesProv.addChallenge(
      name: _nameCtrl.text.trim(),
      startBalance: double.parse(_startCtrl.text),
      targetBalance: double.parse(_targetCtrl.text),
      durationDays: duration,
      startDate: _startDate,
      rules: [..._selectedPresetRules, ..._customRules],
      maxDailyLossPct: maxDailyLossInput == null ? null : maxDailyLossInput / 100,
      trades: sampleTrades,
    );

    if (!mounted) return;
    var xpGain = 50;
    if (sampleTrades.isNotEmpty) {
      xpGain += sampleTrades.length * 50;
    }
    await profileProv.addXp(xpGain);
    final newlyUnlocked = await profileProv.evaluateBadges(challengesProv.challenges);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newlyUnlocked.isNotEmpty
              ? '+$xpGain XP earned! Unlocked badge: ${newlyUnlocked.map((b) => b.title).join(', ')}'
              : '+$xpGain XP earned for creating challenge with sample trades!',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final start = double.tryParse(_startCtrl.text);
    final target = double.tryParse(_targetCtrl.text);
    final duration = _durationDays;
    final ratePreview = (start != null && target != null && start > 0 && duration != null && duration > 0)
        ? requiredDailyRate(start, target, duration) * 100
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Challenge'),
        actions: [
          TextButton.icon(
            onPressed: _autofillSampleData,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Fill sample'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('challengeNameField'),
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Challenge name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('startBalanceField'),
                    controller: _startCtrl,
                    decoration: const InputDecoration(labelText: 'Start balance (\$)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final d = double.tryParse(v ?? '');
                      if (d == null || d <= 0) return 'Enter a positive number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('targetBalanceField'),
                    controller: _targetCtrl,
                    decoration: const InputDecoration(labelText: 'Target balance (\$)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final d = double.tryParse(v ?? '');
                      final s = double.tryParse(_startCtrl.text);
                      if (d == null || d <= 0) return 'Enter a positive number';
                      if (s != null && d <= s) return 'Must be greater than start';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Duration', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('20 days'),
                  selected: _selectedPreset == 20,
                  onSelected: (_) => setState(() => _selectedPreset = 20),
                ),
                ChoiceChip(
                  label: const Text('30 days'),
                  selected: _selectedPreset == 30,
                  onSelected: (_) => setState(() => _selectedPreset = 30),
                ),
                ChoiceChip(
                  label: const Text('Custom'),
                  selected: _selectedPreset == null,
                  onSelected: (_) => setState(() => _selectedPreset = null),
                ),
              ],
            ),
            if (_selectedPreset == null) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customDaysCtrl,
                decoration: const InputDecoration(labelText: 'Number of days'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (_selectedPreset != null) return null;
                  final d = int.tryParse(v ?? '');
                  if (d == null || d <= 0) return 'Enter a valid number of days';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(Icons.calendar_today_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                title: const Text('Start date'),
                subtitle: Text(DateFormat.yMMMd().format(_startDate)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _pickStartDate,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('maxDailyLossField'),
              controller: _maxDailyLossCtrl,
              decoration: const InputDecoration(
                labelText: 'Max daily loss % (optional)',
                helperText: '% of your starting balance, e.g. 2 for a 2% daily loss limit',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final d = double.tryParse(v);
                if (d == null || d <= 0) return 'Enter a positive percentage';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text('Trading rules (optional)', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final rule in _presetRules)
                  FilterChip(
                    label: Text(rule),
                    selected: _selectedPresetRules.contains(rule),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _selectedPresetRules.add(rule);
                      } else {
                        _selectedPresetRules.remove(rule);
                      }
                    }),
                  ),
              ],
            ),
            if (_customRules.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final rule in _customRules)
                    InputChip(
                      label: Text(rule),
                      onDeleted: () => setState(() => _customRules.remove(rule)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _customRuleCtrl,
                    decoration: const InputDecoration(labelText: 'Add your own rule'),
                    onFieldSubmitted: (_) => _addCustomRule(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _addCustomRule,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            if (ratePreview != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.insights_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'To hit your target you need to grow the account by about '
                        '${ratePreview.toStringAsFixed(2)}% per day on average.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _includeSampleTrades,
              onChanged: (val) => setState(() => _includeSampleTrades = val),
              title: const Text('Generate 14 sample trades'),
              subtitle: const Text('Pre-populates heatmaps & charts with realistic profit & loss days'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('createChallengeButton'),
              onPressed: _submit,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Create challenge'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
