import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors_helper.dart';
import '../../../core/utils/email_service.dart';
import '../../widgets/frosted_back_button.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  String _selectedType = '建议';
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _contactController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();
  final _contactFocusNode = FocusNode();
  bool _isSending = false;

  static const _feedbackTypes = ['建议', 'Bug', '其他'];
  static const _maxTitleLength = 50;
  static const _maxContentLength = 500;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contactController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _contactFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final contact = _contactController.text.trim();

    if (title.isEmpty) {
      _showSnackBar('请输入标题');
      return;
    }
    if (content.isEmpty) {
      _showSnackBar('请输入反馈内容');
      return;
    }

    setState(() => _isSending = true);

    final result = await EmailService().sendFeedback(
      type: _selectedType,
      title: title,
      content: content,
      contact: contact.isNotEmpty ? contact : null,
      appVersion: AppConstants.appVersion,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (result == EmailResult.mailtoOpened) {
        _showSnackBar('正在打开邮件客户端...');
        _titleController.clear();
        _contentController.clear();
        _contactController.clear();
      } else {
        _showFeedbackFallbackDialog(title, content, contact);
      }
    }
  }

  void _showFeedbackFallbackDialog(String title, String content, String contact) {
    final isDark = AppColorsHelper.isDark(context);
    final emailBody = '反馈类型：$_selectedType\n标题：$title\n\n---\n$content\n\n---\nApp版本：${AppConstants.appVersion}\n反馈时间：${DateTime.now().toString().substring(0, 19)}${contact.isNotEmpty ? '\n联系方式：$contact' : ''}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '无法打开邮件客户端',
          style: TextStyle(
            color: AppColorsHelper.primaryText(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '请将以下内容手动发送至 Minecraft@Minemryf.net：',
                style: TextStyle(
                  color: AppColorsHelper.secondaryText(context),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
                  ),
                ),
                child: SelectableText(
                  emailBody,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColorsHelper.primaryText(context),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: emailBody));
              Navigator.pop(context);
              _showSnackBar('已复制到剪贴板');
            },
            child: Text(
              '复制内容',
              style: TextStyle(
                color: isDark ? AppColorsHelper.executeButtonEdge(context) : const Color(0xFF2D5BFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '关闭',
              style: TextStyle(
                color: AppColorsHelper.tertiaryText(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColorsHelper.isDark(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColorsHelper.scaffoldBackground(context),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 100, 32, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    '反馈与建议',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: AppColorsHelper.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '帮助我们变得更好',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColorsHelper.secondaryText(context),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildTypeSelector(isDark),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    label: '标题',
                    hint: '简要描述你的反馈',
                    maxLength: _maxTitleLength,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _contentController,
                    focusNode: _contentFocusNode,
                    label: '详细内容',
                    hint: '请详细描述你的建议、遇到的问题或任何想法...',
                    maxLength: _maxContentLength,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _contactController,
                    focusNode: _contactFocusNode,
                    label: '联系方式（可选）',
                    hint: '邮箱或微信号，方便我们回复你',
                    maxLength: 50,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 32),
                  _buildSubmitButton(isDark),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '反馈将直接发送至开发者邮箱',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColorsHelper.tertiaryText(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: FrostedBackButton(
                onTap: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '反馈类型',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColorsHelper.primaryText(context),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _feedbackTypes.map((type) {
            final isSelected = _selectedType == type;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type != _feedbackTypes.last ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: _isSending ? null : () => setState(() => _selectedType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppColorsHelper.executeButtonEdge(context) : Colors.black)
                          : AppColorsHelper.cardBackground(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? AppColorsHelper.executeButtonEdge(context) : Colors.black)
                            : AppColorsHelper.cardBorder(context),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppColorsHelper.primaryText(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required int maxLength,
    required int maxLines,
  }) {
    final isDark = AppColorsHelper.isDark(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColorsHelper.primaryText(context),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          maxLength: maxLength,
          maxLines: maxLines,
          enabled: !_isSending,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF4A4A4A) : const Color(0xFFD0D0D0),
            ),
            counterText: '',
            filled: true,
            fillColor: AppColorsHelper.cardBackground(context),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColorsHelper.cardBorder(context),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColorsHelper.cardBorder(context),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColorsHelper.executeButtonEdge(context) : const Color(0xFF2D5BFF),
                width: 2,
              ),
            ),
          ),
          style: TextStyle(
            fontSize: 14,
            color: AppColorsHelper.primaryText(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: _isSending
              ? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0))
              : (isDark ? AppColorsHelper.executeButtonEdge(context) : Colors.black),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: _isSending ? null : _submitFeedback,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isSending
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  )
                : Text(
                    '提交反馈',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
