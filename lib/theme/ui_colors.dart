import 'package:flutter/material.dart';

/// Colours for the redesigned UI (soft grey + slate + pastel cards).
class UiColors {
  static const bg = Color(0xFFF2F2F4);
  static const ink = Color(0xFF111111);
  static const white = Colors.white;

  // Slate (replaces the old black surfaces)
  static const sand = Color(0xFF4A5C6A);
  static const onSand = Color(0xFFFFFFFF); // text/icons on slate
  static const onSandSoft = Color(0xFFC9D3DB); // secondary text on slate

  static const mint = Color(0xFFCDE8DF);
  static const mintDeep = Color(0xFF8FCDB8);
  static const lilac = Color(0xFFE6DAF7);
  static const lilacDeep = Color(0xFFB9A3E8);
  static const peach = Color(0xFFFCE4BE);

  static const muted = Color(0xFF8A8A8E);
  static const disabled = Color(0xFFCFCFD2);
  static const danger = Color(0xFFE5484D);
}

class UiShadows {
  static const card = <BoxShadow>[
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 5,
      offset: Offset(0, 2),
    ),
  ];
}