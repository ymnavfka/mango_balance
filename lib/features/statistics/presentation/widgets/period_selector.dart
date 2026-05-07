import 'package:flutter/material.dart';

import '../../domain/entities/period_type.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PeriodType selected;
  final ValueChanged<PeriodType> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: PeriodType.values.map((type) {
          final isSelected = type == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(type.label),
              selected: isSelected,
              onSelected: (_) => onSelected(type),
            ),
          );
        }).toList(),
      ),
    );
  }
}
