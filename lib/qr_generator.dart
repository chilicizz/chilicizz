import 'package:flutter/material.dart';

class QRGenerator extends StatefulWidget {
  final String initialValue;

  const QRGenerator({Key? key, this.initialValue = ""}) : super(key: key);

  @override
  State<QRGenerator> createState() => _QRGeneratorState();
}

class _QRGeneratorState extends State<QRGenerator> {
  final qrController = TextEditingController();

  _QRGeneratorState() {
    qrController.text = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
