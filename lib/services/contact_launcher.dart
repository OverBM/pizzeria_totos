import 'package:url_launcher/url_launcher.dart';

/// Acciones de contacto del dispositivo.
class ContactLauncher {
  const ContactLauncher._();

  /// Abre WhatsApp con un mensaje ya construido.
  static Future<bool> whatsapp({
    required String phone,
    required String message,
  }) async {
    final uri = Uri.https('wa.me', '/$phone', {'text': message});
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    final fallback = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );
    return launchUrl(fallback, mode: LaunchMode.externalApplication);
  }

  static Future<bool> call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    return launchUrl(uri);
  }

  static Future<bool> openMap(double lat, double lng, {String? label}) async {
    final query = label == null ? '$lat,$lng' : Uri.encodeComponent(label);
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '$lat,$lng',
    });
    if (await canLaunchUrl(uri)) return launchUrl(uri);
    return launchUrl(Uri.parse('geo:$lat,$lng?q=$lat,$lng($query)'));
  }
}
