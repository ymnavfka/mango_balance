import 'package:flutter/material.dart';

/// В обычном портретном режиме сводка остаётся над списком.
/// В низком окне или при крупном тексте она прокручивается вместе с ним,
/// чтобы не закрывать доступ к операциям. Список остаётся ленивым.
class AdaptiveHeaderScrollView extends StatelessWidget {
  const AdaptiveHeaderScrollView({
    super.key,
    required this.header,
    required this.slivers,
  });

  final List<Widget> header;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scrollHeader =
            constraints.maxHeight < 420 ||
            MediaQuery.textScalerOf(context).scale(14) > 21;
        if (scrollHeader) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: Column(children: header)),
              ...slivers,
            ],
          );
        }
        return Column(
          children: [
            ...header,
            Expanded(child: CustomScrollView(slivers: slivers)),
          ],
        );
      },
    );
  }
}
