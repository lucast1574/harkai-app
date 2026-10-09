import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<String> googleIdentityToken() async {
  if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  await GoogleSignIn.instance.initialize();
  final google = await GoogleSignIn.instance.authenticate();
  final token = google.authentication.idToken;
  if (token == null) {
    throw Exception('No se pudo obtener la identidad de Google.');
  }
  final result = await FirebaseAuth.instance.signInWithCredential(
    GoogleAuthProvider.credential(idToken: token),
  );
  try {
    final identity = await result.user!.getIdToken(true);
    if (identity == null) throw Exception('Identidad no disponible.');
    return identity;
  } finally {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.signOut();
  }
}
