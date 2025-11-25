import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/ai_chat_controller.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/suggestion_buttons.dart';
import '../widgets/chat_input.dart';

class AiChatView extends GetView<AiChatController> {
  const AiChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.7, 1.0],
              colors: [
                Color(0xFF2E7D4E), // xanh lá đậm hơn
                Color(0xFF4DBA6E), // xanh lá chính
                Color(0xFF6BCF7F), // xanh lá nhạt
              ],
            ),
          ),
          child: AppBar(
            title: Row(
              children: [
                _buildAvatar(),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'THẦY AI - LÃO ĐẠI',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Thầy bói AI số 1 thiên hạ! 😉',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, size: 28.sp),
              onPressed: () => Get.back(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, size: 24.sp),
                onPressed: controller.clearChat,
                tooltip: 'Làm mới cuộc trò chuyện',
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF7F9F7),
                    Color(0xFFEEF5EE),
                  ],
                ),
              ),
              child: Obx(() {
                return ListView.builder(
                  controller: controller.scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  itemCount: controller.messages.length + (controller.isTyping.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show typing indicator
                    if (index == controller.messages.length && controller.isTyping.value) {
                      return ChatBubble.typing();
                    }

                    final message = controller.messages[index];
                    return ChatBubble(message: message);
                  },
                );
              }),
            ),
          ),

          // Suggestion buttons area (only show when no typing and not too many messages)
          Obx(() {
            if (controller.isTyping.value || controller.messages.length > 4) {
              return const SizedBox.shrink();
            }
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F8F0),
                border: Border(
                  top: BorderSide(color: Color(0xFFE0E8E0), width: 1),
                ),
              ),
              child: SuggestionButtons(
                suggestions: controller.getSuggestions().take(2).toList(),
                onSuggestionTap: controller.handleSuggestionTap,
              ),
            );
          }),

          // Chat input area
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE0E8E0), width: 1),
              ),
            ),
            child: SafeArea(
              child: ChatInput(
                controller: controller.textController,
                onSend: controller.sendMessage,
                isEnabled: !controller.isTyping.value,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildAvatar() {
  return Container(
    width: 40.w,
    height: 40.w,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
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
        style: TextStyle(fontSize: 20.sp),
      ),
    ),
  );
}
