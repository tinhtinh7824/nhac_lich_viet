class ChatSuggestion {
  final String id;
  final String title;
  final String emoji;
  final String actionText;
  final String? description;
  final ChatSuggestionCategory category;

  ChatSuggestion({
    required this.id,
    required this.title,
    required this.emoji,
    required this.actionText,
    this.description,
    required this.category,
  });

  // Predefined suggestions matching the lunar calendar app
  static List<ChatSuggestion> getDefaultSuggestions() {
    return [
      ChatSuggestion(
        id: 'good_day',
        title: 'Hôm nay có phải ngày tốt của tôi?',
        emoji: '👋',
        actionText: 'Hỏi Lão Đại',
        category: ChatSuggestionCategory.dailyFortune,
      ),
      ChatSuggestion(
        id: 'color_compatibility',
        title: 'Tuổi của tôi hợp với màu gì?',
        emoji: '👉',
        actionText: 'Hỏi Lão Đại',
        category: ChatSuggestionCategory.personalInfo,
      ),
      ChatSuggestion(
        id: 'lucky_number',
        title: 'Số may mắn của tôi hôm nay?',
        emoji: '🍀',
        actionText: 'Hỏi Lão Đại',
        category: ChatSuggestionCategory.dailyFortune,
      ),
      ChatSuggestion(
        id: 'good_time',
        title: 'Giờ nào tốt nhất để làm việc?',
        emoji: '⏰',
        actionText: 'Hỏi Lão Đại',
        category: ChatSuggestionCategory.timing,
      ),
      ChatSuggestion(
        id: 'feng_shui',
        title: 'Phong thủy nhà ở của tôi thế nào?',
        emoji: '🏠',
        actionText: 'Hỏi Lão Đại',
        category: ChatSuggestionCategory.fengShui,
      ),
      ChatSuggestion(
        id: 'direction',
        title: 'Hướng nào tốt cho tôi hôm nay?',
        emoji: '🧭',
        actionText: 'Hỏi Lão Đại',
        category: ChatSuggestionCategory.direction,
      ),
    ];
  }
}

enum ChatSuggestionCategory {
  dailyFortune,
  personalInfo,
  timing,
  fengShui,
  direction,
  general,
}