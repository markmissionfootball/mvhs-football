import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/broadcast.dart';
import '../../providers/auth_provider.dart';
import '../../providers/broadcast_provider.dart';
import '../../theme/diablo_colors.dart';

/// Compose a compliant one-to-many broadcast.
///
/// The audience is chosen by ROLE and LEVEL — there is intentionally no
/// individual-recipient picker. A live recipient counter (resolved server-side)
/// shows reach before sending.
class ComposeBroadcastScreen extends ConsumerStatefulWidget {
  const ComposeBroadcastScreen({super.key});

  @override
  ConsumerState<ComposeBroadcastScreen> createState() =>
      _ComposeBroadcastScreenState();
}

class _ComposeBroadcastScreenState
    extends ConsumerState<ComposeBroadcastScreen> {
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  final Set<String> _roles = {'player', 'parent'};
  final Set<String> _levels = {};
  final Set<BroadcastChannel> _channels = {BroadcastChannel.push};
  String _priority = 'normal';
  bool _allowReplies = true;

  bool _sending = false;
  int? _recipientCount;
  bool _previewLoading = false;
  Timer? _previewDebounce;

  static const _levelOptions = ['varsity', 'jv', 'freshman'];
  static const _levelLabels = {
    'varsity': 'Varsity',
    'jv': 'JV',
    'freshman': 'Freshman',
  };
  static const _roleOptions = ['player', 'parent', 'coach'];
  static const _roleLabels = {
    'player': 'Players',
    'parent': 'Parents',
    'coach': 'Coaches',
  };

  @override
  void initState() {
    super.initState();
    _schedulePreview();
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  BroadcastAudience get _audience => BroadcastAudience(
        roles: _roles.toList(),
        levels: _levels.toList(),
      );

  void _schedulePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 350), _runPreview);
  }

  Future<void> _runPreview() async {
    if (_roles.isEmpty) {
      setState(() => _recipientCount = 0);
      return;
    }
    setState(() => _previewLoading = true);
    final preview = await ref
        .read(broadcastServiceProvider)
        .previewAudience(_audience);
    if (!mounted) return;
    setState(() {
      _recipientCount = preview.total;
      _previewLoading = false;
    });
  }

  Future<void> _send() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      _snack('Message body is required', DiabloColors.red);
      return;
    }
    if (_roles.isEmpty) {
      _snack('Select at least one audience role', DiabloColors.red);
      return;
    }
    if (_channels.isEmpty) {
      _snack('Select at least one delivery channel', DiabloColors.red);
      return;
    }

    setState(() => _sending = true);
    final user = ref.read(appUserProvider).whenOrNull(data: (u) => u);
    final draft = Broadcast(
      id: '',
      senderUid: user?.uid ?? '',
      senderName: user?.displayName ?? 'Staff',
      senderRole: user?.role.name ?? 'coach',
      subject: _subjectController.text.trim().isEmpty
          ? null
          : _subjectController.text.trim(),
      body: body,
      audience: _audience,
      channels: _channels.toList(),
      allowReplies: _allowReplies,
      priority: _priority,
      createdAt: DateTime.now(),
    );

    final result = await ref.read(broadcastServiceProvider).send(draft);
    if (!mounted) return;
    setState(() => _sending = false);

    if (result.ok) {
      _snack(
        'Sent to ${result.recipientCount} recipient'
        '${result.recipientCount == 1 ? '' : 's'}',
        const Color(0xFF4CAF50),
      );
      context.pop();
    } else {
      _snack(result.error ?? 'Failed to send', DiabloColors.red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiabloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'NEW BROADCAST',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _complianceBanner(),
            const SizedBox(height: 20),

            _label('AUDIENCE — ROLES'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _roleOptions.map((r) {
                final on = _roles.contains(r);
                return _chip(
                  _roleLabels[r]!,
                  on,
                  () => setState(() {
                    on ? _roles.remove(r) : _roles.add(r);
                    _schedulePreview();
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            _label('TEAM LEVELS'),
            const SizedBox(height: 4),
            Text(
              'No level selected = all levels',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _levelOptions.map((l) {
                final on = _levels.contains(l);
                return _chip(
                  _levelLabels[l]!,
                  on,
                  () => setState(() {
                    on ? _levels.remove(l) : _levels.add(l);
                    _schedulePreview();
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            _recipientCounter(),
            const SizedBox(height: 20),

            _label('SUBJECT (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration('Subject', Icons.title),
            ),
            const SizedBox(height: 16),

            _label('MESSAGE'),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              style: const TextStyle(color: Colors.white),
              maxLines: 6,
              decoration: _decoration('Write your message…', null),
            ),
            const SizedBox(height: 20),

            _label('DELIVER VIA'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BroadcastChannel.values.map((c) {
                final on = _channels.contains(c);
                return _chip(
                  c.label,
                  on,
                  () => setState(() {
                    on ? _channels.remove(c) : _channels.add(c);
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'Texts and emails are sent from the program — never a coach’s '
              'personal number.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _label('PRIORITY'),
                ),
                _priorityToggle(),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: DiabloColors.gold,
              title: const Text(
                'Allow public replies',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: const Text(
                'Replies are visible to the whole group',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              value: _allowReplies,
              onChanged: (v) => setState(() => _allowReplies = v),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DiabloColors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      DiabloColors.red.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _sending ? 'SENDING…' : 'SEND BROADCAST',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _complianceBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DiabloColors.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: DiabloColors.gold, width: 3)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: DiabloColors.gold, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'You’re messaging roles, not individual students. Every '
              'broadcast is logged and visible to administrators.',
              style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recipientCounter() {
    final count = _recipientCount;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        gradient: DiabloColors.redGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Text(
            _previewLoading
                ? 'Calculating reach…'
                : count == null
                    ? 'Select an audience'
                    : 'Reaching $count recipient${count == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (_previewLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _priorityToggle() {
    final urgent = _priority == 'urgent';
    return GestureDetector(
      onTap: () => setState(() => _priority = urgent ? 'normal' : 'urgent'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: urgent ? DiabloColors.red : DiabloColors.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: urgent ? DiabloColors.red : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.priority_high,
              size: 16,
              color: urgent ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 4),
            Text(
              urgent ? 'Urgent' : 'Normal',
              style: TextStyle(
                color: urgent ? Colors.white : Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? DiabloColors.gold : DiabloColors.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? DiabloColors.gold : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );

  InputDecoration _decoration(String label, IconData? icon) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIcon: icon != null ? Icon(icon, color: DiabloColors.gold) : null,
      filled: true,
      fillColor: DiabloColors.darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: DiabloColors.gold),
      ),
    );
  }
}
