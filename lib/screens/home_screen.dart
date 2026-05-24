import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'dashboard_screen.dart';
import 'inventario_screen.dart';
import 'tpv_screen.dart';
import 'historial_screen.dart';
import 'clientes_screen.dart';
import 'perfil_screen.dart';

/// Contenedor principal con navegacion entre los 5 modulos.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indice = 0;

  static const _titulos = [
    'Dashboard',
    'Inventario',
    'TPV',
    'Historial',
    'Clientes',
  ];

  final _pantallas = const [
    DashboardScreen(),
    InventarioScreen(),
    TpvScreen(),
    HistorialScreen(),
    ClientesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 9),
            Text(_titulos[_indice]),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Perfil y ajustes',
            icon: const Icon(Icons.person_outline, size: 22),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PerfilScreen()),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _indice, children: _pantallas),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.bgSoft,
        indicatorColor: AppColors.accent.withValues(alpha: 0.25),
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'TPV',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Clientes',
          ),
        ],
      ),
    );
  }
}
