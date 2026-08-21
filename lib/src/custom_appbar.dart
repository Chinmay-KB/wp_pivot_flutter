import 'package:flutter/material.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final Color textColor;
  final FontWeight fontWeight;
  final double fontSize;
  const CustomAppBar(
      {super.key,
      required this.title,
      required this.textColor,
      required this.fontSize,
      required this.fontWeight})
      : preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  final Size preferredSize; // default is 56.0

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.black,
        padding: EdgeInsets.only(top: 16, left: 16),
        child: Text(
          widget.title,
          style: TextStyle(
              color: widget.textColor,
              fontWeight: widget.fontWeight,
              fontSize: widget.fontSize),
        ),
      ),
    );
  }
}
