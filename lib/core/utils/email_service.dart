import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailService {
  static final EmailService _instance = EmailService._();
  factory EmailService() => _instance;
  EmailService._();

  static const _recipient = 'Minecraft@Minemryf.net';

  Future<EmailResult> sendFeedback({
    required String type,
    required String title,
    required String content,
    String? contact,
    required String appVersion,
  }) async {
    final subject = '[决App反馈][$type] $title';
    final body = _buildBody(type, title, content, contact, appVersion);

    final uri = Uri(
      scheme: 'mailto',
      path: _recipient,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      debugPrint('EmailService: Trying mailto...');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        debugPrint('EmailService: mailto launched');
        return EmailResult.mailtoOpened;
      }
    } catch (e) {
      debugPrint('EmailService: mailto failed: $e');
    }

    return EmailResult.failed;
  }

  String _buildBody(
    String type,
    String title,
    String content,
    String? contact,
    String appVersion,
  ) {
    final buffer = StringBuffer()
      ..writeln('反馈类型：$type')
      ..writeln('标题：$title')
      ..writeln()
      ..writeln('---')
      ..writeln(content)
      ..writeln()
      ..writeln('---')
      ..writeln('App版本：$appVersion')
      ..writeln('反馈时间：${DateTime.now().toString().substring(0, 19)}');
    if (contact != null && contact.isNotEmpty) {
      buffer.writeln('联系方式：$contact');
    }
    return buffer.toString();
  }
}

enum EmailResult { mailtoOpened, failed }
