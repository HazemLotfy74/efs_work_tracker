import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/widgets/custom_container.dart';

class NoChekoutRecordWarningWidget extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      borderWidth: 1,
      containerColor: ColorScheme.of(context).secondaryContainer,
      child: Row(
        spacing: 10,
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: ColorScheme.of(context).onSecondaryContainer,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 5,
            children: [
              Text(
                context.l10n.noEmployee,
                style: TextTheme.of(context).bodyMedium!.copyWith(
                  color: ColorScheme.of(context).onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              Text(
                context.l10n.noCheckout,
                style: TextTheme.of(context).bodyMedium!.copyWith(
                  color: ColorScheme.of(context).onSecondaryContainer,
                  fontWeight: FontWeight.w400,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
