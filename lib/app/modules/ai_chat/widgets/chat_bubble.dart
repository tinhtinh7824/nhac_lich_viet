import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage? message;
  final bool isTyping;

  const ChatBubble({
    super.key,
    this.message,
    this.isTyping = false,
  });

  // Constructor for typing indicator
  const ChatBubble.typing({super.key})
      : message = null,
        isTyping = true;

  @override
  Widget build(BuildContext context) {
    if (isTyping) {
      return _buildTypingIndicator();
    }

    if (message == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment:
            message!.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message!.isUser) ...[
            // Lão Đại avatar
            _buildAvatar(),
            SizedBox(width: 8.w),
          ],
          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: message!.isUser
                    ? const Color(0xFF4DBA6E)
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                  bottomLeft: Radius.circular(message!.isUser ? 20.r : 4.r),
                  bottomRight: Radius.circular(message!.isUser ? 4.r : 20.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message!.content,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: message!.isUser ? Colors.white : const Color(0xFF2D3748),
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message!.isUser) ...[
            SizedBox(width: 8.w),
            // User avatar
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4DBA6E), Color(0xFF6BCF7F)],
                ),
              ),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF4DBA6E), width: 2),
        gradient: const LinearGradient(
          colors: [Color(0xFF4DBA6E), Color(0xFF6BCF7F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '🧙‍♂️',
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
                bottomLeft: Radius.circular(4.r),
                bottomRight: Radius.circular(20.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lão Đại đang suy nghĩ',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: const Color(0xFF2D3748),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(width: 8.w),
                SizedBox(
                  width: 24.w,
                  height: 16.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(3, (index) {
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 600 + (index * 200)),
                        curve: Curves.easeInOut,
                        width: 4.w,
                        height: 4.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF4DBA6E).withValues(alpha: 0.6),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
