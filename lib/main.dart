import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'providers/inventario_provider.dart';
import 'providers/clientes_provider.dart';
import 'providers/ventas_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializacion de Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Formato de fechas en espanol
  await initializeDateFormatting('es', null);

  runApp(const GestionApp());
}

class GestionApp extends StatelessWidget {
  const GestionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InventarioProvider()),
        ChangeNotifierProvider(create: (_) => ClientesProvider()),
        ChangeNotifierProvider(create: (_) => VentasProvider()),
      ],
      child: MaterialApp(
        title: 'GestiON',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _PuntoEntrada(),
      ),
    );
  }
}

/// Decide que pantalla mostrar segun el estado de autenticacion.
class _PuntoEntrada extends StatelessWidget {
  const _PuntoEntrada();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Si hay usuario autenticado -> Home, si no -> Login
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
