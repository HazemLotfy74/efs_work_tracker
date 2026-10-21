import 'package:flutter/material.dart';

import '../../../../../core/widgets/custom_container.dart';

class CustomStatusContainer extends StatelessWidget {
  const CustomStatusContainer({super.key, required this.mainContainerColor, required this.statusContainerColor, required this.txtColor, required this.text});

  final Color mainContainerColor;
  final Color statusContainerColor;
  final Color txtColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      borderWidth: 1,
      borderRadius: 12.5,
      containerColor: mainContainerColor,
      child: Row(
        spacing: 5,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusContainerColor,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            text,
            style: TextTheme.of(context).bodyMedium!.copyWith(
              fontWeight: FontWeight.w800,
              color: txtColor,
            ),
          ),
        ],
      ),
    );
  }
}
