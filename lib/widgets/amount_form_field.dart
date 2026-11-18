import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/form_validators.dart';

class AmountFormField extends StatelessWidget {
  const AmountFormField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText = 'Örn. 1.234,56',
    this.requiredField = true,
    this.allowNegative = false,
    this.emptyMessage = 'Tutar gerekli',
    this.negativeMessage = 'Tutar negatif olamaz',
    this.invalidMessage = 'Geçerli bir tutar girin',
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool requiredField;
  final bool allowNegative;
  final String emptyMessage;
  final String negativeMessage;
  final String invalidMessage;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: allowNegative,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(allowNegative ? r'[0-9.,-]' : r'[0-9.,]'),
        ),
      ],
      decoration: InputDecoration(labelText: label, hintText: hintText),
      validator: (value) => validateAmount(
        value,
        requiredField: requiredField,
        allowNegative: allowNegative,
        emptyMessage: emptyMessage,
        invalidMessage: invalidMessage,
        negativeMessage: negativeMessage,
      ),
    );
  }
}

class DayFormField extends StatelessWidget {
  const DayFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.emptyMessage,
  });

  final TextEditingController controller;
  final String label;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      decoration:
          const InputDecoration(hintText: '1-31').copyWith(labelText: label),
      validator: (value) => validateDay(value, emptyMessage: emptyMessage),
    );
  }
}
