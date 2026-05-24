import 'package:firebase_auth/firebase_auth.dart';

/// Servicio de autenticacion con Firebase Authentication (Email/Password).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream que notifica cambios de sesion (login/logout).
  Stream<User?> get authState => _auth.authStateChanges();

  User? get usuarioActual => _auth.currentUser;

  /// Iniciar sesion. Devuelve null si va bien, o un mensaje de error.
  Future<String?> iniciarSesion(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mensajeError(e.code);
    } catch (_) {
      return 'Error inesperado. Intentalo de nuevo.';
    }
  }

  /// Registrar un nuevo negocio.
  Future<String?> registrar(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mensajeError(e.code);
    } catch (_) {
      return 'Error inesperado. Intentalo de nuevo.';
    }
  }

  Future<void> cerrarSesion() => _auth.signOut();

  /// Envía un email de recuperación de contraseña.
  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  String _mensajeError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe ninguna cuenta con ese correo.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contrasena incorrectos.';
      case 'email-already-in-use':
        return 'Ese correo ya esta registrado.';
      case 'weak-password':
        return 'La contrasena debe tener al menos 6 caracteres.';
      case 'invalid-email':
        return 'El formato del correo no es valido.';
      default:
        return 'Error de autenticacion ($code).';
    }
  }
}
