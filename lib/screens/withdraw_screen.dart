import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/wallet_summary_service.dart';
import '../services/withdraw_request_service.dart';
import '../services/ad_service.dart';
import '../widgets/app_dialog.dart';
import '../widgets/bank_picker.dart';
import '../widgets/app_bottom_nav.dart';
import '../theme/ui_colors.dart';
import '../widgets/skeleton.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _authService = AuthService();
  final _summaryService = WalletSummaryService();
  final _withdrawService = WithdrawRequestService();
  final _upiController = TextEditingController();
  final _otherBankController = TextEditingController();
  final _holderController = TextEditingController();

  static final _upiPattern = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');

  WalletSummary? _summary;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _upiError;
  String? _bank;
  String? _bankError;
  String? _holderError;

  // Withdrawal amount (in points) + wallet settings
  int _points = 0;
  double _pointsPerRupee = 13.33;
  int _step = 100;

  @override
  void initState() {
    super.initState();
    _loadWalletConfig();
    _loadSummary();
  }

  @override
  void dispose() {
    _upiController.dispose();
    _otherBankController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletConfig() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('wallet_config')
          .get();
      final d = snap.data();
      if (d == null) return;
      final ppr = d['pointsPerRupee'];
      final step = d['withdrawalStepPoints'];
      if (!mounted) return;
      setState(() {
        if (ppr is num && ppr > 0) _pointsPerRupee = ppr.toDouble();
        if (step is num && step >= 1) _step = step.toInt();
      });
    } catch (_) {}
  }

  Future<void> _loadSummary() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isLoading = true);
    final summary = await _summaryService.fetchSummary(uid);
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _isLoading = false;
    });
  }

  // Smallest allowed amount: the minimum rounded up to a multiple of the step
  int _minAllowed(WalletSummary s) =>
      ((s.minWithdrawalPoints + _step - 1) ~/ _step) * _step;

  // Largest allowed amount: balance rounded down to a multiple of the step
  int _maxAllowed(WalletSummary s) => (s.points ~/ _step) * _step;

  double _rupeesFor(int points, WalletSummary s) =>
      (points / _pointsPerRupee * 100).floorToDouble() / 100 +
      s.unlockedBonus;

  void _handleWithdrawTap() {
    final summary = _summary;
    if (summary == null) return;

    if (!summary.isEligible || _maxAllowed(summary) < _minAllowed(summary)) {
      AppDialog.show(
        context,
        title: 'Not Eligible Yet',
        message:
            'You need ${summary.pointsNeeded} more Earnkit Points to unlock withdrawal.\n\n'
            'Once you reach ${summary.minWithdrawalPoints} points, they\'ll convert to ₹, '
            'and any unlocked bonus (₹${summary.unlockedBonus}) will be added on top. Keep watching ads!',
        icon: Icons.hourglass_empty,
        iconColor: const Color(0xFFD99A00),
      );
      return;
    }

    _points = _minAllowed(summary);
    _showWithdrawForm(summary);
  }

  // ---------- Small UI helpers ----------

  InputDecoration _field({
    required String label,
    required IconData icon,
    String? hint,
    String? helper,
    String? error,
    Widget? suffix,
  }) {
    OutlineInputBorder b(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c, width: 1.4),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      errorText: error,
      prefixIcon: Icon(icon, color: UiColors.muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: UiColors.bg,
      border: b(Colors.transparent),
      enabledBorder: b(Colors.transparent),
      focusedBorder: b(UiColors.sand),
      errorBorder: b(UiColors.danger),
      focusedErrorBorder: b(UiColors.danger),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? UiColors.sand : UiColors.disabled,
      shape: const CircleBorder(),
      elevation: enabled ? 4 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon,
              color: enabled ? UiColors.onSand : Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _amountPicker(WalletSummary s, StateSetter setModalState) {
    final minP = _minAllowed(s);
    final maxP = _maxAllowed(s);
    final canMinus = _points - _step >= minP;
    final canPlus = _points + _step <= maxP;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UiColors.lilac,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Points to withdraw',
              style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF55555A),
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              _roundBtn(Icons.remove,
                  canMinus ? () => setModalState(() => _points -= _step) : null),
              Expanded(
                child: Center(
                  child: Text('$_points',
                      style: const TextStyle(
                          fontSize: 34,
                          color: UiColors.ink,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              _roundBtn(Icons.add,
                  canPlus ? () => setModalState(() => _points += _step) : null),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Multiples of $_step points. Minimum $minP.',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF55555A),
                      fontWeight: FontWeight.w500),
                ),
              ),
              TextButton(
                onPressed: _points == maxP
                    ? null
                    : () => setModalState(() => _points = maxP),
                child: const Text('Max',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const Divider(height: 18),
          const Text('You will receive',
              style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF55555A),
                  fontWeight: FontWeight.w700)),
          Text('₹${_rupeesFor(_points, s).toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 28,
                  color: UiColors.ink,
                  fontWeight: FontWeight.w800)),
          if (s.unlockedBonus > 0)
            Text('Includes ₹${s.unlockedBonus} unlocked bonus',
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF55555A),
                    fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showWithdrawForm(WalletSummary summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: UiColors.disabled,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Confirm withdrawal',
                          style: TextStyle(
                              fontSize: 22,
                              color: UiColors.ink,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      _amountPicker(summary, setModalState),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _upiController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        onChanged: (_) {
                          if (_upiError != null) {
                            setModalState(() => _upiError = null);
                          }
                        },
                        decoration: _field(
                          label: 'Your UPI ID',
                          hint: 'name@okaxis',
                          icon: Icons.account_balance_wallet_outlined,
                          error: _upiError,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () async {
                          FocusScope.of(context).unfocus();
                          final picked =
                              await showBankPicker(context, selected: _bank);
                          if (picked != null) {
                            setModalState(() {
                              _bank = picked;
                              _bankError = null;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: _field(
                            label: 'Bank name',
                            icon: Icons.account_balance_outlined,
                            error: _bankError,
                            suffix: const Icon(Icons.arrow_drop_down),
                          ),
                          child: Text(
                            _bank ?? 'Select your bank',
                            style: TextStyle(
                                fontSize: 15,
                                color: _bank == null
                                    ? UiColors.muted
                                    : UiColors.ink,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      if (_bank == kOtherBank) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _otherBankController,
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(60),
                          ],
                          onChanged: (_) {
                            if (_bankError != null) {
                              setModalState(() => _bankError = null);
                            }
                          },
                          decoration: _field(
                            label: 'Enter your bank name',
                            icon: Icons.edit_outlined,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: _holderController,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(60),
                        ],
                        onChanged: (_) {
                          if (_holderError != null) {
                            setModalState(() => _holderError = null);
                          }
                        },
                        decoration: _field(
                          label: 'Account holder name',
                          helper: 'Name as written on your bank account',
                          icon: Icons.person_outline,
                          error: _holderError,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Double-check your UPI ID. Payments sent to a wrong ID cannot be reversed.',
                        style: TextStyle(
                            fontSize: 12,
                            color: UiColors.muted,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      Material(
                        color: _isSubmitting ? UiColors.disabled : UiColors.sand,
                        borderRadius: BorderRadius.circular(40),
                        elevation: _isSubmitting ? 0 : 5,
                        shadowColor: Colors.black.withValues(alpha: 0.3),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(40),
                          onTap: _isSubmitting
                              ? null
                              : () async {
                                  final upiId = _upiController.text.trim();
                                  if (!_upiPattern.hasMatch(upiId)) {
                                    setModalState(() => _upiError =
                                        'Enter a valid UPI ID, e.g. name@okaxis');
                                    return;
                                  }
                                  final bankName = _bank == kOtherBank
                                      ? _otherBankController.text
                                          .trim()
                                          .replaceAll(RegExp(r'\s+'), ' ')
                                      : (_bank ?? '');
                                  if (bankName.length < 2) {
                                    setModalState(() => _bankError =
                                        _bank == null
                                            ? 'Select your bank'
                                            : 'Enter your bank name');
                                    return;
                                  }
                                  final holderName = _holderController.text
                                      .trim()
                                      .replaceAll(RegExp(r'\s+'), ' ');
                                  if (holderName.length < 2) {
                                    setModalState(() => _holderError =
                                        'Enter the account holder name');
                                    return;
                                  }

                                  setModalState(() => _isSubmitting = true);
                                  final allowed =
                                      await AdService().watchGateAd();
                                  if (!allowed) {
                                    setModalState(() => _isSubmitting = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Please watch the full ad to continue.')));
                                    }
                                    return;
                                  }
                                  final result = await _withdrawService.submit(
                                    upiId: upiId,
                                    bankName: bankName,
                                    holderName: holderName,
                                    points: _points,
                                  );
                                  setModalState(() => _isSubmitting = false);

                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();

                                  if (result['success'] == true) {
                                    AppDialog.showSuccess(context,
                                        'Withdrawal request submitted! It will be processed soon.');
                                    _loadSummary();
                                  } else {
                                    AppDialog.showError(context,
                                        result['error'] ?? 'Request failed');
                                  }
                                },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: UiColors.onSand),
                                    )
                                  : const Text('Watch Ad & Confirm',
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: UiColors.onSand,
                                          fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ---------- Page cards ----------

  /// One big slate card: balance, progress ring, status and the Withdraw button.
  Widget _heroCard(WalletSummary s) {
    final min = s.minWithdrawalPoints;
    final progress =
        min > 0 ? (s.points / min).clamp(0.0, 1.0).toDouble() : 1.0;
    final percent = (progress * 100).round();
    final rupees = (s.points / _pointsPerRupee * 100).floorToDouble() / 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: UiColors.sand,
        borderRadius: BorderRadius.circular(32),
        boxShadow: UiShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current balance',
                        style: TextStyle(
                            fontSize: 14,
                            color: UiColors.onSandSoft,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('${s.points}',
                        style: const TextStyle(
                            fontSize: 46,
                            height: 1,
                            color: UiColors.onSand,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Earnkit Points  ≈  ₹${rupees.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: UiColors.onSandSoft,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(UiColors.mint),
                      ),
                    ),
                    Text('$percent%',
                        style: const TextStyle(
                            fontSize: 17,
                            color: UiColors.onSand,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(
                  s.isEligible ? Icons.check_circle : Icons.info_outline,
                  size: 20,
                  color: s.isEligible ? UiColors.mint : UiColors.onSandSoft,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.isEligible
                        ? 'You can withdraw up to ₹${s.totalWithdrawable.toStringAsFixed(2)}'
                        : '${s.pointsNeeded} more points needed to unlock withdrawal',
                    style: const TextStyle(
                        fontSize: 13,
                        color: UiColors.onSand,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          if (s.unlockedBonus > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: UiColors.peach,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('+ ₹${s.unlockedBonus} bonus ready',
                  style: const TextStyle(
                      fontSize: 12,
                      color: UiColors.ink,
                      fontWeight: FontWeight.w800)),
            ),
          ],
          const SizedBox(height: 16),
          Material(
            color: s.isEligible
                ? Colors.white
                : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(40),
            elevation: s.isEligible ? 4 : 0,
            shadowColor: Colors.black.withValues(alpha: 0.25),
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: _handleWithdrawTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_upward_rounded,
                        size: 18,
                        color: s.isEligible
                            ? UiColors.sand
                            : UiColors.onSandSoft),
                    const SizedBox(width: 6),
                    Text('Withdraw Now',
                        style: TextStyle(
                            fontSize: 15,
                            color: s.isEligible
                                ? UiColors.sand
                                : UiColors.onSandSoft,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(Color color, IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: UiShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: Icon(icon, size: 17, color: UiColors.ink),
            ),
            const SizedBox(height: 12),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15.5,
                    color: UiColors.ink,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF55555A),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(WalletSummary s) {
    final rate = _pointsPerRupee == _pointsPerRupee.roundToDouble()
        ? _pointsPerRupee.toStringAsFixed(0)
        : _pointsPerRupee.toStringAsFixed(1);
    return Row(
      children: [
        _infoTile(UiColors.lilac, Icons.flag_outlined, 'Minimum',
            '${_minAllowed(s)} pts'),
        const SizedBox(width: 10),
        _infoTile(UiColors.peach, Icons.stairs_outlined, 'In steps of',
            '$_step pts'),
        const SizedBox(width: 10),
        _infoTile(UiColors.mint, Icons.currency_rupee, '₹1 equals',
            '$rate pts'),
      ],
    );
  }

  Widget _howItWorks() {
    Widget step(int n, Color c, String text, {bool last = false}) {
      return Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('$n',
                  style: const TextStyle(
                      fontSize: 14.5,
                      color: UiColors.ink,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(text,
                    style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.3,
                        color: Color(0xFF55555A),
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: UiShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How withdrawal works',
              style: TextStyle(
                  fontSize: 17,
                  color: UiColors.ink,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          step(1, UiColors.mint,
              'Earn points from ads and tasks until you reach the minimum.'),
          step(2, UiColors.lilac,
              'Choose how many points to withdraw, in multiples of $_step.'),
          step(3, UiColors.peach,
              'Enter your UPI ID, bank name and account holder name.'),
          step(4, UiColors.mint,
              'Each request is reviewed before the payment is sent.',
              last: true),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UiColors.bg,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const WithdrawSkeleton()
            : _summary == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Could not load wallet data'),
                        TextButton(
                            onPressed: _loadSummary,
                            child: const Text('Retry')),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadSummary,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                      children: [
                        const Text('Withdraw',
                            style: TextStyle(
                                fontSize: 30,
                                color: UiColors.ink,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 16),
                        _heroCard(_summary!),
                        const SizedBox(height: 14),
                        _infoRow(_summary!),
                        const SizedBox(height: 14),
                        _howItWorks(),
                      ],
                    ),
                  ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}