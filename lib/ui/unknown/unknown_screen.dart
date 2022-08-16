import 'package:flutter/material.dart';

class UnknownScreen extends StatelessWidget {
  const UnknownScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Text(
        'Unknown !!!!!',
        style: Theme.of(context).textTheme.headline5,
        textAlign: TextAlign.center,
      )),
    );
  }
}