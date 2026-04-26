import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Formatea un número como moneda RD$
/// Ejemplo: 1250.0 → "RD$ 1,250.00"
String formatRD(double amount) {
  final formatter = NumberFormat.currency(
    symbol: 'RD\$ ',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}

/// Formatea un timestamp como fecha relativa
/// Ejemplo: hace 3 min → "hace 3 min"
String formatFechaRelativa(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return timeago.format(date, locale: 'es');
}

/// Formatea un teléfono en formato visual
/// Ejemplo: "18095551234" → "+1 (809) 555-1234"
String formatTelefono(String tel) {
  // Limpiar el número
  final cleaned = tel.replaceAll(RegExp(r'[^\d]'), '');

  if (cleaned.length == 10) {
    return '+1 (${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
  } else if (cleaned.length == 11 && cleaned.startsWith('1')) {
    return '+1 (${cleaned.substring(1, 4)}) ${cleaned.substring(4, 7)}-${cleaned.substring(7)}';
  }

  // Si no tiene el formato esperado, retornar el original
  return tel;
}

/// Formatea un timestamp como fecha corta
/// Ejemplo: 1714130700000 → "26 abr 2026, 10:45 AM"
String formatFechaCorta(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final formatter = DateFormat('d MMM yyyy, h:mm a', 'es_ES');
  return formatter.format(date);
}

/// Formatea un timestamp como solo hora
/// Ejemplo: 1714130700000 → "10:45 AM"
String formatHora(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final formatter = DateFormat('h:mm a', 'es_ES');
  return formatter.format(date);
}

/// Formatea un timestamp como fecha larga
/// Ejemplo: 1714130700000 → "26 de abril de 2026"
String formatFechaLarga(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final formatter = DateFormat('d MMMM yyyy', 'es_ES');
  return formatter.format(date);
}