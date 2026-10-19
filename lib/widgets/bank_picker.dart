import 'package:flutter/material.dart';
import '../data/indian_banks.dart';
import '../theme/ui_colors.dart';

const String kOtherBank = 'Other bank';

/// Opens a searchable bank list. Returns the chosen bank name,
/// or [kOtherBank] when the user picks "Other bank".
Future<String?> showBankPicker(BuildContext context, {String? selected}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BankPickerSheet(selected: selected),
  );
}

class _BankPickerSheet extends StatefulWidget {
  final String? selected;
  const _BankPickerSheet({this.selected});

  @override
  State<_BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<_BankPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final banks = kIndianBanks
        .where((b) => q.isEmpty || b.toLowerCase().contains(q))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: UiColors.disabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Select your bank',
                style: TextStyle(
                    fontSize: 21,
                    color: UiColors.ink,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search bank',
                prefixIcon: const Icon(Icons.search, color: UiColors.muted),
                filled: true,
                fillColor: UiColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  for (final b in banks)
                    ListTile(
                      dense: true,
                      title: Text(b,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: UiColors.ink)),
                      trailing: b == widget.selected
                          ? const Icon(Icons.check_circle,
                              color: UiColors.sand)
                          : null,
                      onTap: () => Navigator.of(context).pop(b),
                    ),
                  if (banks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No bank found. Choose "Other bank" below.',
                          style: TextStyle(
                              fontSize: 13,
                              color: UiColors.muted,
                              fontWeight: FontWeight.w500)),
                    ),
                  const Divider(),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.edit_outlined,
                        color: UiColors.ink),
                    title: const Text(kOtherBank,
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('My bank is not in the list'),
                    trailing: widget.selected == kOtherBank
                        ? const Icon(Icons.check_circle, color: UiColors.sand)
                        : null,
                    onTap: () => Navigator.of(context).pop(kOtherBank),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}