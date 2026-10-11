import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../recurring/domain/entities/recurring_payment.dart';
import '../data/goal_repository.dart';
import 'goal_cubit.dart';
import 'goal_form_dialog.dart';

class GoalPaymentAction extends StatelessWidget {
  const GoalPaymentAction({super.key, required this.payment});
  final RecurringPaymentEntity payment;
  @override
  Widget build(BuildContext context) => BlocBuilder<GoalCubit, GoalSnapshot>(
    builder: (context, state) {
      final linked = state.goals.where((g) => g.sourcePaymentId == payment.id);
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextButton.icon(
            icon: const Icon(Icons.flag_outlined),
            label: Text(linked.isEmpty ? 'Создать цель' : 'Открыть цель'),
            onPressed: () {
              if (linked.isEmpty) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => GoalFormDialog(source: payment),
                );
              } else {
                Navigator.of(
                  context,
                ).pushNamed('/goals', arguments: linked.first.id);
              }
            },
          ),
        ),
      );
    },
  );
}
