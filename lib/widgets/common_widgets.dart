import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/producto.dart';

/// Tarjeta de indicador KPI para el Dashboard.
class KpiCard extends StatelessWidget {
  final String label;
  final String valor;
  final String detalle;
  final bool alerta;

  const KpiCard({
    super.key,
    required this.label,
    required this.valor,
    required this.detalle,
    this.alerta = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = alerta ? AppColors.amber : AppColors.accent;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.line),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 3, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 1,
                            color: AppColors.textFaint,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(valor,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: alerta ? AppColors.amber : AppColors.text)),
                    const SizedBox(height: 2),
                    Text(detalle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textDim)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Etiqueta visual del estado del stock.
class StockTag extends StatelessWidget {
  final StockEstado estado;
  const StockTag(this.estado, {super.key});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String texto;
    switch (estado) {
      case StockEstado.disponible:
        color = AppColors.green;
        texto = 'Disponible';
        break;
      case StockEstado.bajo:
        color = AppColors.amber;
        texto = 'Stock bajo';
        break;
      case StockEstado.agotado:
        color = AppColors.red;
        texto = 'Agotado';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text('● $texto',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

/// Estado vacio reutilizable para listas sin datos.
class EmptyState extends StatelessWidget {
  final IconData icono;
  final String mensaje;
  const EmptyState(
      {super.key, this.icono = Icons.inbox_outlined, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(46),
      child: Column(
        children: [
          Icon(icono, size: 42, color: AppColors.line),
          const SizedBox(height: 12),
          Text(mensaje,
              style: const TextStyle(color: AppColors.textFaint)),
        ],
      ),
    );
  }
}

/// Cabecera de panel con titulo.
class PanelHeader extends StatelessWidget {
  final String titulo;
  final String? hint;
  const PanelHeader(this.titulo, {super.key, this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          if (hint != null)
            Text(hint!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textFaint)),
        ],
      ),
    );
  }
}
