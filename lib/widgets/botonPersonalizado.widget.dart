import 'package:app_p3topicos/main.dart';
import 'package:flutter/material.dart';

class BotonPersonalizado extends StatelessWidget {
  const BotonPersonalizado({
    super.key,
    required this.icono,
    required this.color,
    required this.onTap,
    required this.enabled,
    required this.size,
  });

  final IconData icono;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.035),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size.width * 0.025),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icono, color: colorPrimario, size: size.width * 0.06),
    );
  }
}
