import 'package:flutter/material.dart';
import '../core/utils/currency.dart';

class CurrencyText extends StatelessWidget {
  final int amount;
  final TextStyle? style;
  const CurrencyText(this.amount, {super.key, this.style});

  @override
  Widget build(BuildContext context) => Text(formatUgx(amount), style: style);
}