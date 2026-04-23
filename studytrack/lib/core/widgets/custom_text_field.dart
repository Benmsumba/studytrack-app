import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({super.key, this.controller, this.hintText});

  final TextEditingController? controller;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(controller: controller, decoration: InputDecoration(hintText: hintText));
  }
}
