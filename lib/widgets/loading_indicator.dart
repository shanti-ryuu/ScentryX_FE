import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final bool fullscreen;

  const LoadingIndicator({
    super.key,
    this.size = 32,
    this.fullscreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );

    if (!fullscreen) {
      return Center(child: indicator);
    }

    return Container(
      color: Colors.black.withOpacity(0.05),
      alignment: Alignment.center,
      child: indicator,
    );
  }
}
