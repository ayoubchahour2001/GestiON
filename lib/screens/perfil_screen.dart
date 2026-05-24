import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../providers/inventario_provider.dart';
import '../providers/clientes_provider.dart';
import '../providers/ventas_provider.dart';
import '../services/auth_service.dart';

/// Pantalla de perfil del negocio y configuración de cuenta.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _auth = AuthService();
  final _ctrlNombre = TextEditingController();
  bool _editando = false;
  bool _enviandoReset = false;

  @override
  void initState() {
    super.initState();
    _cargarNombre();
  }

  @override
  void dispose() {
    _ctrlNombre.dispose();
    super.dispose();
  }

  Future<void> _cargarNombre() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString('nombre_negocio') ?? '';
    if (mounted) setState(() => _ctrlNombre.text = nombre);
  }

  Future<void> _guardarNombre() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre_negocio', _ctrlNombre.text.trim());
    if (mounted) setState(() => _editando = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre del negocio guardado')),
      );
    }
  }

  Future<void> _enviarResetPassword() async {
    final email = _auth.usuarioActual?.email;
    if (email == null) return;
    setState(() => _enviandoReset = true);
    await _auth.resetPassword(email);
    if (mounted) {
      setState(() => _enviandoReset = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email de recuperación enviado a $email'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  Future<void> _confirmarCerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmar == true) await _auth.cerrarSesion();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.usuarioActual;
    final inv = context.watch<InventarioProvider>();
    final cli = context.watch<ClientesProvider>();
    final vp = context.watch<VentasProvider>();
    final inicial = (user?.email ?? '?')[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil y ajustes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
        children: [
          // ── Avatar + email ───────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, Color(0xFF5BB8F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    inicial,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.email ?? '—',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text('Cuenta activa',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.green,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Nombre del negocio ───────────────────────────────────────
          _Seccion(
            titulo: 'Negocio',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrlNombre,
                        enabled: _editando,
                        decoration: InputDecoration(
                          labelText: 'Nombre del negocio',
                          hintText: 'Ej: Mi Tienda',
                          fillColor: _editando
                              ? AppColors.bg
                              : AppColors.panel2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _editando
                          ? ElevatedButton(
                              key: const ValueKey('guardar'),
                              onPressed: _guardarNombre,
                              style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14)),
                              child: const Text('Guardar'),
                            )
                          : OutlinedButton(
                              key: const ValueKey('editar'),
                              onPressed: () =>
                                  setState(() => _editando = true),
                              style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14)),
                              child: const Text('Editar'),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Estadísticas del negocio ─────────────────────────────────
          _Seccion(
            titulo: 'Estadísticas',
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.3,
              children: [
                _MiniKpi(
                  icon: Icons.inventory_2_outlined,
                  valor: '${inv.productos.length}',
                  label: 'Productos',
                  color: AppColors.amber,
                ),
                _MiniKpi(
                  icon: Icons.people_outline,
                  valor: '${cli.clientes.length}',
                  label: 'Clientes',
                  color: AppColors.accentBright,
                ),
                _MiniKpi(
                  icon: Icons.receipt_long_outlined,
                  valor: '${vp.historial.length}',
                  label: 'Ventas',
                  color: AppColors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Seguridad ────────────────────────────────────────────────
          _Seccion(
            titulo: 'Seguridad',
            child: Column(
              children: [
                _BotonOpcion(
                  icon: Icons.lock_reset_outlined,
                  label: 'Cambiar contraseña',
                  sublabel: 'Recibirás un email con el enlace',
                  cargando: _enviandoReset,
                  onTap: _enviarResetPassword,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Info de la app ───────────────────────────────────────────
          const _Seccion(
            titulo: 'Aplicación',
            child: Column(
              children: [
                _FilaInfo(
                    icon: Icons.info_outline,
                    label: 'Versión',
                    valor: '1.0.0'),
                Divider(color: AppColors.line, height: 20),
                _FilaInfo(
                    icon: Icons.storage_outlined,
                    label: 'Base de datos',
                    valor: 'Firebase + SQLite'),
                Divider(color: AppColors.line, height: 20),
                _FilaInfo(
                    icon: Icons.cloud_outlined,
                    label: 'Proyecto Firebase',
                    valor: 'gestion-b8736'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Cerrar sesión ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmarCerrarSesion,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                side: const BorderSide(color: AppColors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Cerrar sesión'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────

class _Seccion extends StatelessWidget {
  final String titulo;
  final Widget child;
  const _Seccion({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  color: AppColors.textFaint,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  final IconData icon;
  final String valor;
  final String label;
  final Color color;
  const _MiniKpi(
      {required this.icon,
      required this.valor,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 5),
          Text(valor,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textFaint)),
        ],
      ),
    );
  }
}

class _BotonOpcion extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool cargando;
  final VoidCallback onTap;
  const _BotonOpcion(
      {required this.icon,
      required this.label,
      required this.sublabel,
      required this.onTap,
      this.cargando = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: cargando ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.panel2,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 18, color: AppColors.textDim),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(sublabel,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textFaint)),
                ],
              ),
            ),
            cargando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right,
                    color: AppColors.line, size: 20),
          ],
        ),
      ),
    );
  }
}

class _FilaInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;
  const _FilaInfo(
      {required this.icon, required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textFaint),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textDim)),
        const Spacer(),
        Text(valor,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
