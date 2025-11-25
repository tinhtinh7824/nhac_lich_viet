import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/chat_suggestion.dart';
import '../../../data/models/event_model.dart';
import '../../../services/event_services.dart';
import '../../../utils/logger_utils.dart';
import '../../../utils/vietnamese_text_utils.dart';

class AiChatController extends GetxController {
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isTyping = false.obs;
  final RxBool isLoading = false.obs;
  final scrollController = ScrollController();
  final textController = TextEditingController();
  EventServices? _eventServices;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<EventServices>()) {
      _eventServices = Get.find<EventServices>();
    } else {
      LoggerUtils.warning('AiChatController could not find EventServices');
    }
    _initializeChat();
  }

  @override
  void onClose() {
    scrollController.dispose();
    textController.dispose();
    super.onClose();
  }

  /// Initialize chat with greeting message from Lão Đại
  void _initializeChat() {
    final greetingMessage = ChatMessage.ai(
      content: 'Xin chào! Ta là Lão Đại - thầy bói AI số một thiên hạ! Cần xem tử vi, phong thủy hay chọn ngày đẹp? Hỏi ngay, đừng ngại!',
      type: ChatMessageType.greeting,
    );
    messages.add(greetingMessage);
  }

  /// Get suggestion buttons for user interaction
  List<ChatSuggestion> getSuggestions() {
    return ChatSuggestion.getDefaultSuggestions();
  }

  /// Handle user message input
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    try {
      // Add user message
      final userMessage = ChatMessage.user(content: message.trim());
      messages.add(userMessage);
      textController.clear();

      // Scroll to bottom
      _scrollToBottom();

      // Show typing indicator
      isTyping.value = true;

      // Simulate AI thinking time
      await Future.delayed(const Duration(milliseconds: 1500));

      // Generate AI response
      final aiResponse = await _generateAIResponse(message);
      final aiMessage = ChatMessage.ai(content: aiResponse);

      messages.add(aiMessage);
      isTyping.value = false;

      // Scroll to bottom after AI response
      _scrollToBottom();

    } catch (e) {
      LoggerUtils.error('Error sending message', e);
      isTyping.value = false;

      // Add error message
      final errorMessage = ChatMessage.ai(
        content: 'Xin lỗi, Lão Đại đang bận tính toán vũ trụ. Hãy thử lại sau nhé! 😅',
      );
      messages.add(errorMessage);
    }
  }

  /// Handle suggestion button tap
  Future<void> handleSuggestionTap(ChatSuggestion suggestion) async {
    await sendMessage(suggestion.title);
  }

  /// Generate AI response based on user input
  Future<String> _generateAIResponse(String userMessage) async {
    final normalized = VietnameseTextUtils.normalize(userMessage);

    final greetingResponse = _handleGreeting(normalized);
    if (greetingResponse != null) {
      return greetingResponse;
    }

    final ParsedDate? parsedDate = _extractDate(userMessage);
    if (parsedDate != null) {
      final dateResponse = await _buildDateResponse(parsedDate);
      if (dateResponse != null) {
        return dateResponse;
      }
    }

    final countdownResponse =
        await _buildCountdownResponse(userMessage, normalized);
    if (countdownResponse != null) {
      return countdownResponse;
    }

    final eventInfoResponse =
        await _buildEventInfoResponse(userMessage, normalized);
    if (eventInfoResponse != null) {
      return eventInfoResponse;
    }

    // Default themed responses when nothing specific is matched
    return _getGeneralResponse();
  }

  String _getGeneralResponse() {
    final responses = [
      'Câu hỏi thú vị đấy! Theo kinh nghiệm của ta, mọi việc đều có nguyên do của nó. Hãy kiên nhẫn và quan sát! 🔮',
      'Hmm... ta thấy có điều gì đó đặc biệt quanh bạn. Hãy kể rõ hơn để ta tư vấn chính xác nhé! 🤨',
      'Đây là vấn đề cần cân nhắc kỹ. Ta khuyên bạn nên theo trực giác của mình. 💭',
      'Theo quan điểm của ta, bạn đang trên đúng con đường. Hãy tin tưởng vào bản thân! 💪',
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  /// Scroll to bottom of chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Clear chat history
  void clearChat() {
    messages.clear();
    _initializeChat();
  }

  String? _handleGreeting(String normalizedMessage) {
    const greetings = [
      'chao',
      'xin chao',
      'hello',
      'hi',
      'alo',
      'ciao',
    ];
    for (final greeting in greetings) {
      if (normalizedMessage.startsWith(greeting)) {
        return 'Chào bạn! Ta là Lão Đại, sẵn sàng hỗ trợ bạn tra cứu lịch, chọn ngày đẹp và trả lời các thắc mắc về ngày tháng.';
      }
    }
    return null;
  }

  ParsedDate? _extractDate(String message) {
    final RegExp pattern =
        RegExp(r'(\d{1,2})[\/\-\.\s](\d{1,2})(?:[\/\-\.\s](\d{2,4}))?');
    final match = pattern.firstMatch(message);
    if (match == null) return null;

    final int? day = int.tryParse(match.group(1)!);
    final int? month = int.tryParse(match.group(2)!);
    final String? yearRaw = match.group(3);
    int? year;
    if (yearRaw != null) {
      year = int.tryParse(yearRaw.length == 2 ? '20$yearRaw' : yearRaw);
    }
    if (day == null || month == null) return null;

    return ParsedDate(day: day, month: month, year: year);
  }

  Future<String?> _buildDateResponse(ParsedDate parsedDate) async {
    if (_eventServices == null) return null;
    final List<Event> allEvents = _eventServices!.getAllEvents();
    if (allEvents.isEmpty) return null;

    final List<Event> matches = [];
    for (final event in allEvents) {
      if (_matchEventToDate(event, parsedDate)) {
        matches.add(event);
      }
    }

    if (matches.isEmpty) {
      final String dateLabel = parsedDate.format();
      return 'Ta chưa thấy sự kiện đặc biệt nào rơi vào ngày $dateLabel trong dữ liệu hiện tại. Bạn có thể hỏi ta về sự kiện khác hoặc kiểm tra lại ngày nhé.';
    }

    matches.sort((a, b) => a.title.compareTo(b.title));
    final Event primaryEvent =
        _pickClosestEvent(matches) ?? matches.first;

    final DateTime? nextOccurrence = _findNextOccurrence(primaryEvent);
    final String countdownText =
        nextOccurrence != null ? _buildCountdownPhrase(nextOccurrence) : '';

    final String descriptionPart =
        primaryEvent.description.isNotEmpty ? ' – ${primaryEvent.description}' : '';
    final String lunarNote = primaryEvent.isLunar ? ' (âm lịch)' : '';

    final String dateLabel = parsedDate.format();
    final StringBuffer response = StringBuffer(
        'Ngày $dateLabel là "${primaryEvent.title}"$lunarNote$descriptionPart.');

    if (matches.length > 1) {
      response.write(
          '\nNgoài ra còn ${matches.length - 1} sự kiện khác cũng diễn ra trong ngày này.');
    }
    if (countdownText.isNotEmpty) {
      response.write('\n$countdownText');
    }
    return response.toString();
  }

  bool _matchEventToDate(Event event, ParsedDate parsedDate) {
    final DateTime eventDate = event.eventDate;

    if (parsedDate.year != null) {
      return eventDate.day == parsedDate.day &&
          eventDate.month == parsedDate.month &&
          eventDate.year == parsedDate.year;
    }

    if (event.repeatType == 'yearly' ||
        event.repeatType == 'Hằng năm' ||
        event.repeatType == 'year' ||
        event.repeatType == 'Hàng năm') {
      return eventDate.day == parsedDate.day &&
          eventDate.month == parsedDate.month;
    }

    return eventDate.day == parsedDate.day &&
        eventDate.month == parsedDate.month;
  }

  Future<String?> _buildCountdownResponse(
      String originalMessage, String normalizedMessage) async {
    if (_eventServices == null) return null;

    final RegExp pattern = RegExp(
        r'(?:bao|con)\s*(?:bao)?\s*nhieu\s*(?:ngay)?\s*(?:nua)?\s*(?:den|toi|ve|cho)\s+(.+)',
        caseSensitive: false);
    final match = pattern.firstMatch(normalizedMessage);
    if (match == null) return null;

    final targetRaw = match.group(1)?.trim();
    if (targetRaw == null || targetRaw.isEmpty) return null;

    final sanitizedKeyword = _sanitizeKeyword(targetRaw);
    if (sanitizedKeyword.isEmpty) return null;

    final events = await _searchEvents(sanitizedKeyword);
    if (events.isEmpty) {
      return 'Ta chưa tìm thấy sự kiện nào phù hợp với "$targetRaw". Bạn có thể mô tả rõ hơn tên sự kiện giúp ta nhé!';
    }

    final Event? bestMatch = _pickBestMatch(events, sanitizedKeyword);
    if (bestMatch == null) {
      return null;
    }

    final DateTime? nextOccurrence = _findNextOccurrence(bestMatch);
    if (nextOccurrence == null) {
      return 'Ta chưa có lịch cho "${bestMatch.title}". Có thể sự kiện này đã qua hoặc chưa được cập nhật.';
    }

    final String countdownText = _buildCountdownPhrase(nextOccurrence);
    final String dateLabel = DateFormat('dd/MM/yyyy').format(nextOccurrence);

    final StringBuffer response = StringBuffer();
    response.write(
        '"${bestMatch.title}" sẽ diễn ra vào $dateLabel${bestMatch.isLunar ? ' (âm lịch quy đổi)' : ''}.');
    response.write(' $countdownText');
    return response.toString();
  }

  Future<String?> _buildEventInfoResponse(
      String originalMessage, String normalizedMessage) async {
    if (_eventServices == null) return null;

    final RegExp pattern =
        RegExp(r'(.+?)\s+la\s+ngay\s+(?:gi|nao|bao gio)', caseSensitive: false);
    final match = pattern.firstMatch(normalizedMessage);
    if (match == null) return null;

    final keyword = match.group(1)?.trim();
    if (keyword == null || keyword.isEmpty) return null;

    final sanitizedKeyword = _sanitizeKeyword(keyword);
    if (sanitizedKeyword.isEmpty) return null;

    final ParsedDate? maybeDate = _extractDate(sanitizedKeyword);
    if (maybeDate != null) {
      return null; // Đã xử lý trong _buildDateResponse
    }

    final events = await _searchEvents(sanitizedKeyword);
    if (events.isEmpty) {
      return 'Ta chưa tìm thấy sự kiện nào phù hợp với "$keyword". Bạn thử mô tả lại giúp ta nhé!';
    }

    final Event? bestMatch = _pickBestMatch(events, sanitizedKeyword);
    if (bestMatch == null) {
      return null;
    }

    final DateTime eventDate = bestMatch.eventDate;
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    final String dateLabel = formatter.format(eventDate);

    final DateTime? nextOccurrence = _findNextOccurrence(bestMatch);
    final String countdown =
        nextOccurrence != null ? _buildCountdownPhrase(nextOccurrence) : '';

    final StringBuffer response = StringBuffer();
    response.write(
        '"${bestMatch.title}" diễn ra vào ngày $dateLabel${bestMatch.isLunar ? ' (sự kiện âm lịch)' : ''}.');
    if (bestMatch.description.isNotEmpty) {
      response.write(' ${bestMatch.description}');
    }
    if (countdown.isNotEmpty) {
      response.write(' $countdown');
    }
    return response.toString();
  }

  Future<List<Event>> _searchEvents(String keyword) async {
    if (_eventServices == null) return [];
    try {
      return await _eventServices!.searchEventsByKeyword(keyword);
    } catch (e, stackTrace) {
      LoggerUtils.error('Error searching events for "$keyword"', e, stackTrace);
      return [];
    }
  }

  Event? _pickBestMatch(List<Event> events, String keyword) {
    if (events.isEmpty) return null;
    double bestScore = -1;
    Event? bestEvent;
    for (final event in events) {
      final score =
          VietnameseTextUtils.calculateSimilarity(keyword, event.title);
      if (score > bestScore) {
        bestScore = score;
        bestEvent = event;
      }
    }
    return bestEvent;
  }

  Event? _pickClosestEvent(List<Event> events) {
    if (events.isEmpty) return null;
    DateTime now = DateTime.now();
    Event? best;
    int bestDistance = 999999;

    for (final event in events) {
      final DateTime? next = _findNextOccurrence(event);
      if (next == null) continue;
      final int distance = next.difference(now).inDays.abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = event;
      }
    }
    return best;
  }

  DateTime? _findNextOccurrence(Event event) {
    if (_eventServices == null) return null;
    final DateTime now = DateTime.now();
    final DateTime start = DateTime(now.year, now.month, now.day);

    const int maxLookaheadDays = 366 * 3;
    for (int offset = 0; offset < maxLookaheadDays; offset++) {
      final DateTime candidate = start.add(Duration(days: offset));
      if (EventServices.staticDoesEventOccurOnDate(event, candidate)) {
        return DateTime(candidate.year, candidate.month, candidate.day,
            event.eventDate.hour, event.eventDate.minute);
      }
    }
    return null;
  }

  String _sanitizeKeyword(String keyword) {
    final cleaned = keyword.replaceAll(RegExp(r'[^a-z0-9\s/]', caseSensitive: false), ' ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _buildCountdownPhrase(DateTime targetDate) {
    final DateTime today = DateTime.now();
    final Duration difference =
        targetDate.difference(DateTime(today.year, today.month, today.day));
    final int days = difference.inDays;

    if (days <= 0) {
      return 'Sự kiện diễn ra ngay hôm nay! Hãy chuẩn bị thật tốt nhé!';
    } else if (days == 1) {
      return 'Còn đúng 1 ngày nữa là tới!';
    } else if (days < 7) {
      return 'Còn $days ngày nữa. Thời gian không còn nhiều, nhớ sắp xếp kế hoạch nhé!';
    } else {
      return 'Còn $days ngày nữa. Bạn có thể bắt đầu chuẩn bị dần rồi!';
    }
  }
}

class ParsedDate {
  final int day;
  final int month;
  final int? year;

  ParsedDate({
    required this.day,
    required this.month,
    this.year,
  });

  String format() {
    if (year != null) {
      return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
    }
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}';
  }
}
