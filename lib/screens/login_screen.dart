import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';

/// Pantalla de inicio de sesion / registro con Firebase Auth.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _emailCtrl = TextEditingController(text: 'demo@gestion.app');
  final _passCtrl = TextEditingController(text: 'demo1234');

  bool _esRegistro = false;
  bool _cargando = false;
  bool _enviandoReset = false;
  String? _error;
  String? _mensajeExito;

  Future<void> _enviar() async {
    setState(() {
      _cargando = true;
      _error = null;
      _mensajeExito = null;
    });
    final error = _esRegistro
        ? await _auth.registrar(_emailCtrl.text, _passCtrl.text)
        : await _auth.iniciarSesion(_emailCtrl.text, _passCtrl.text);
    if (mounted) {
      setState(() {
        _cargando = false;
        _error = error;
      });
    }
  }

  Future<void> _olvidoPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Escribe tu correo para recuperar la contraseña.');
      return;
    }
    setState(() {
      _enviandoReset = true;
      _error = null;
      _mensajeExito = null;
    });
    try {
      await _auth.resetPassword(email);
      if (mounted) {
        setState(() {
          _enviandoReset = false;
          _mensajeExito = 'Email de recuperación enviado a $email';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _enviandoReset = false;
          _error = 'No se pudo enviar el email. Verifica el correo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -0.8),
            radius: 1.4,
            colors: [Color(0xFF14233A), AppColors.bg],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 380,
              padding: const EdgeInsets.all(34),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 11),
                      const Text('GestiON',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _esRegistro
                        ? 'Crea la cuenta de tu negocio'
                        : 'Sistema de gestion para pequenos negocios',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textDim),
                  ),
                  const SizedBox(height: 26),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'Correo electronico',
                        hintText: 'tu@negocio.com'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    onSubmitted: (_) => _enviar(),
                    decoration: const InputDecoration(
                        labelText: 'Contrasena', hintText: '••••••••'),
                  ),
                  // ── Enlace "Olvidé mi contraseña" ───────────────────
                  if (!_esRegistro) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _enviandoReset ? null : _olvidoPassword,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: _enviandoReset
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : const Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textDim),
                              ),
                      ),
                    ),
                  ],
                  // ── Mensaje de error ────────────────────────────────
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                            color: AppColors.red.withValues(alpha: 0.3)),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(
                              color: AppColors.red, fontSize: 13)),
                    ),
                  ],
                  // ── Mensaje de éxito (reset enviado) ────────────────
                  if (_mensajeExito != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                            color: AppColors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 16, color: AppColors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_mensajeExito!,
                                style: const TextStyle(
                                    color: AppColors.green, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _cargando ? null : _enviar,
                      child: _cargando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(_esRegistro ? 'Crear cuenta' : 'Entrar'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() {
                        _esRegistro = !_esRegistro;
                        _error = null;
                        _mensajeExito = null;
                      }),
                      child: Text(
                        _esRegistro
                            ? '¿Ya tienes cuenta? Inicia sesion'
                            : '¿No tienes cuenta? Registrate',
                        style: const TextStyle(
                            color: AppColors.accentBright, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
