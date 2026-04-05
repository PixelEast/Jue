import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class ViewToggle extends StatelessWidget {
  const ViewToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.grid_on_outlined,
            size: 20,
            color: AppColors.kleinBlue,
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.list_outlined, size: 20, color: AppColors.darkGray),
          onPressed: () {},
        ),
      ],
    );
  }
}
