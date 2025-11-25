import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final bool isEnabled;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.isEnabled = true,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleSend() {
    if (!widget.isEnabled || !_hasText) return;

    final message = widget.controller.text.trim();
    if (message.isNotEmpty) {
      widget.onSend(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          // Text input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: const Color(0xFFE0E8E0),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: widget.controller,
                enabled: widget.isEnabled,
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                style: TextStyle(
                  fontSize: 16.sp,
                  color: const Color(0xFF2D3748),
                ),
                decoration: InputDecoration(
                  hintText: 'Hỏi Lão Đại bất cứ điều gì...',
                  hintStyle: TextStyle(
                    fontSize: 16.sp,
                    color: const Color(0xFF9CA3AF),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: 8.w),

          // Send button
          GestureDetector(
            onTap: _handleSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                gradient: _hasText && widget.isEnabled
                    ? const LinearGradient(
                        colors: [Color(0xFF4DBA6E), Color(0xFF6BCF7F)],
                      )
                    : LinearGradient(
                        colors: [
                          const Color(0xFF9CA3AF).withValues(alpha: 0.5),
                          const Color(0xFF9CA3AF).withValues(alpha: 0.3),
                        ],
                      ),
                shape: BoxShape.circle,
                boxShadow: _hasText && widget.isEnabled
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4DBA6E).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}