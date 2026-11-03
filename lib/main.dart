import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'firebase_options.dart';

/// Optional: run against the local Firestore emulator with
/// `flutter run --dart-define=USE_FIRESTORE_EMULATOR=true`.
const bool kUseEmulator = bool.fromEnvironment('USE_FIRESTORE_EMULATOR');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final db = FirebaseFirestore.instance;
  if (kUseEmulator) {
    final host = defaultTargetPlatform == TargetPlatform.android && !kIsWeb
        ? '10.0.2.2'
        : 'localhost';
    db.useFirestoreEmulator(host, 8080);
  }
  await _preloadFonts();
  runApp(StockInventoryApp(firestore: db));
}

/// Loads every font weight used by the UI before the first frame so chips
/// and buttons are measured with the real font (prevents clipped labels).
/// Never blocks for long: offline, the app falls back to system fonts.
Future<void> _preloadFonts() async {
  try {
    GoogleFonts.inter();
    for (final w in [
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700,
      FontWeight.w800,
    ]) {
      GoogleFonts.inter(fontWeight: w);
      GoogleFonts.poppins(fontWeight: w);
    }
    await GoogleFonts.pendingFonts().timeout(const Duration(seconds: 4));
  } catch (_) {
    // Fonts are cosmetic; continue with fallbacks.
  }
}
