import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/challenge.dart';
import '../models/trade_entry.dart';
import '../providers/challenges_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_palette.dart';
import '../utils/challenge_math.dart';
import '../utils/trade_math.dart';
import '../widgets/section_header.dart';

const _setups = ['Breakout', 'Pullback', 'Reversal', 'Trend continuation', 'Other'];
const _emotions = ['Calm', 'Neutral', 'Fear', 'Excited', 'Angry', 'Revenge', 'FOMO'];

class AddTradeScreen extends StatefulWidget {
  const AddTradeScreen({super.key, required this.challenge, this.initialDate});

  final Challenge challenge;
  final DateTime? initialDate;

  @override
  State<AddTradeScreen> createState() => _AddTradeScreenState();
}

class _AddTradeScreenState extends State<AddTradeScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  String? _direction;
  String? _setup;
  String? _emotion;
  bool? _followedPlan;
  final _instrumentCtrl = TextEditingController();
  final _entryCtrl = TextEditingController();
  final _exitCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _stopLossCtrl = TextEditingController();
  final _takeProfitCtrl = TextEditingController();
  final _pnlCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _lessonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final requested = dateOnly(widget.initialDate ?? DateTime.now());
    final start = dateOnly(widget.challenge.startDate);
    final end = dateOnly(widget.challenge.endDate);
    _date = requested.isBefore(start)
        ? start
        : (requested.isAfter(end) ? end : requested);

    _pnlCtrl.text = '25.00';
    _setup = 'Breakout';
    _emotion = 'Calm';
    _followedPlan = true;
    _instrumentCtrl.text = 'EUR/USD';
    _lessonCtrl.text = 'Stayed patient for clear setup confirmation.';
  }

  void _autofillSampleTrade() {
    setState(() {
      _pnlCtrl.text = '25.00';
      _setup = 'Breakout';
      _instrumentCtrl.text = 'EUR/USD';
      _direction = 'long';
      _entryCtrl.text = '1.0850';
      _exitCtrl.text = '1.0900';
      _sizeCtrl.text = '0.5';
      _stopLossCtrl.text = '1.0820';
      _takeProfitCtrl.text = '1.0910';
      _followedPlan = true;
      _emotion = 'Calm';
      _lessonCtrl.text = 'Stayed patient for clear setup confirmation.';
    });
  }

  @override
  void dispose() {
    _instrumentCtrl.dispose();
    _entryCtrl.dispose();
    _exitCtrl.dispose();
    _sizeCtrl.dispose();
    _stopLossCtrl.dispose();
    _takeProfitCtrl.dispose();
    _pnlCtrl.dispose();
    _noteCtrl.dispose();
    _lessonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: dateOnly(widget.challenge.startDate),
      lastDate: dateOnly(widget.challenge.endDate),
    );
    if (picked != null) setState(() => _date = picked);
  }

  TradeEntry _draftTrade() {
    return TradeEntry(
      id: '',
      date: _date,
      pnl: double.tryParse(_pnlCtrl.text) ?? 0,
      entryPrice: double.tryParse(_entryCtrl.text),
      stopLoss: double.tryParse(_stopLossCtrl.text),
      takeProfit: double.tryParse(_takeProfitCtrl.text),
      size: double.tryParse(_sizeCtrl.text),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final trade = TradeEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: _date,
      pnl: double.parse(_pnlCtrl.text),
      instrument: _instrumentCtrl.text.trim().isEmpty ? null : _instrumentCtrl.text.trim(),
      direction: _direction,
      entryPrice: _entryCtrl.text.trim().isEmpty ? null : double.tryParse(_entryCtrl.text),
      exitPrice: _exitCtrl.text.trim().isEmpty ? null : double.tryParse(_exitCtrl.text),
      size: _sizeCtrl.text.trim().isEmpty ? null : double.tryParse(_sizeCtrl.text),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      setup: _setup,
      stopLoss: _stopLossCtrl.text.trim().isEmpty ? null : double.tryParse(_stopLossCtrl.text),
      takeProfit: _takeProfitCtrl.text.trim().isEmpty ? null : double.tryParse(_takeProfitCtrl.text),
      emotion: _emotion,
      followedPlan: _followedPlan,
      lesson: _lessonCtrl.text.trim().isEmpty ? null : _lessonCtrl.text.trim(),
    );

    var xpEarned = 50;
    if (trade.followedPlan == true) xpEarned += 150;
    if (trade.emotion == 'Calm' || trade.emotion == 'Neutral') xpEarned += 50;
    if (trade.lesson != null && trade.lesson!.trim().isNotEmpty) xpEarned += 100;

    final challengesProv = context.read<ChallengesProvider>();
    final profileProv = context.read<ProfileProvider>();

    await challengesProv.addTrade(widget.challenge.id, trade);
    await profileProv.addXp(xpEarned);
    final newlyUnlocked = await profileProv.evaluateBadges(challengesProv.challenges);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newlyUnlocked.isNotEmpty
              ? '+$xpEarned XP! Unlocked badge: ${newlyUnlocked.map((b) => b.title).join(', ')}'
              : '+$xpEarned XP earned for logging trade!',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final draft = _draftTrade();
    final risk = riskAmount(draft);
    final rr = riskRewardRatio(draft);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Trade'),
        actions: [
          TextButton.icon(
            onPressed: _autofillSampleTrade,
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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(Icons.calendar_today_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                title: const Text('Date'),
                subtitle: Text(DateFormat.yMMMd().format(_date)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(icon: Icons.description_rounded, label: 'Setup'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('setupDropdown'),
              initialValue: _setup,
              decoration: const InputDecoration(labelText: 'Setup type (optional)'),
              items: [for (final s in _setups) DropdownMenuItem(value: s, child: Text(s))],
              onChanged: (v) => setState(() => _setup = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _instrumentCtrl,
              decoration: const InputDecoration(labelText: 'Instrument (optional)'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _direction,
              decoration: const InputDecoration(labelText: 'Direction (optional)'),
              items: const [
                DropdownMenuItem(value: 'long', child: Text('Long')),
                DropdownMenuItem(value: 'short', child: Text('Short')),
              ],
              onChanged: (v) => setState(() => _direction = v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _entryCtrl,
                    decoration: const InputDecoration(labelText: 'Entry price (optional)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _exitCtrl,
                    decoration: const InputDecoration(labelText: 'Exit price (optional)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sizeCtrl,
              decoration: const InputDecoration(labelText: 'Size / quantity (optional)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),
            const SectionHeader(icon: Icons.shield_outlined, label: 'Risk'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stopLossCtrl,
                    decoration: const InputDecoration(labelText: 'Stop loss (optional)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _takeProfitCtrl,
                    decoration: const InputDecoration(labelText: 'Take profit (optional)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            if (risk != null || rr != null) ...[
              const SizedBox(height: 10),
              Text(
                [
                  if (risk != null) 'Risk \$${risk.toStringAsFixed(2)}',
                  if (rr != null) 'R:R 1:${rr.toStringAsFixed(2)}',
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
            ],
            const SizedBox(height: 24),
            const SectionHeader(icon: Icons.attach_money_rounded, label: 'Outcome'),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('pnlField'),
              controller: _pnlCtrl,
              decoration: const InputDecoration(
                labelText: 'Profit / Loss (\$)',
                helperText: 'Use a negative number for a loss, e.g. -25.50',
              ),
              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 24),
            const SectionHeader(icon: Icons.self_improvement_rounded, label: 'Reflection'),
            const SizedBox(height: 12),
            Text('Did you follow your plan?', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Yes')),
                ButtonSegment(value: false, label: Text('No')),
              ],
              selected: _followedPlan == null ? {} : {_followedPlan!},
              emptySelectionAllowed: true,
              onSelectionChanged: (selection) => setState(
                () => _followedPlan = selection.isEmpty ? null : selection.first,
              ),
            ),
            const SizedBox(height: 16),
            Text('Emotion (optional)', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in _emotions)
                  ChoiceChip(
                    label: Text(e),
                    selected: _emotion == e,
                    onSelected: (selected) => setState(() => _emotion = selected ? e : null),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('lessonField'),
              controller: _lessonCtrl,
              decoration: const InputDecoration(labelText: 'What did you learn? (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('saveTradeButton'),
              onPressed: _submit,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Save trade'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
