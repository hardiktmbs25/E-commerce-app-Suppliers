import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class WhatsappService {
  Future<void> sendInvoice(String phone, String message, File? pdfFile) async {
    // If PDF is provided, we use share_plus because direct WhatsApp API doesn't support file attachment easily without Business API
    if (pdfFile != null) {
      await Share.shareXFiles([XFile(pdfFile.path)], text: message);
    } else {
      final whatsappUrl = "whatsapp://send?phone=+91$phone&text=${Uri.encodeComponent(message)}";
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
      } else {
        // Fallback to web link
        final webUrl = "https://wa.me/91$phone?text=${Uri.encodeComponent(message)}";
        await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> sendPaymentReminder(String phone, double amount) async {
    final message = "Hello, this is a reminder regarding your pending payment of ₹$amount. Please clear it at your earliest convenience. Thank you!";
    final whatsappUrl = "whatsapp://send?phone=+91$phone&text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    }
  }
}