class Staff {
  final String? id;
  final String? fullName;
  final String? email;
  final String? role;
  final bool? isActive;
  final String? lastActiveAt;

  Staff({
    this.id,
    this.fullName,
    this.email,
    this.role,
    this.isActive,
    this.lastActiveAt,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['_id'] ?? json['id'],
      fullName: json['fullName'],
      email: json['email'],
      role: json['role'],
      isActive: json['isActive'],
      lastActiveAt: json['lastActiveAt'],
    );
  }
}

class ChatThread {
  final String? id;
  final String? userId;
  final String? staffId;
  final String? status;

  ChatThread({
    this.id,
    this.userId,
    this.staffId,
    this.status,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['_id'] ?? json['id'],
      userId: json['userId'],
      staffId: json['staffId'],
      status: json['status'],
    );
  }
}

class ChatMessage {
  final String? id;
  final String? threadId;
  final String? senderType;
  final String? message;
  final String? createdAt;

  ChatMessage({
    this.id,
    this.threadId,
    this.senderType,
    this.message,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? json['id'],
      threadId: json['threadId'],
      senderType: json['senderType'],
      message: json['message'],
      createdAt: json['createdAt'] ?? json['created_at'] ?? json['sentAt'],
    );
  }
}

class StaffListResponse {
  final bool? success;
  final String? message;
  final List<Staff>? data;

  StaffListResponse({
    this.success,
    this.message,
    this.data,
  });

  factory StaffListResponse.fromJson(Map<String, dynamic> json) {
    return StaffListResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? List<Staff>.from(json['data'].map((item) => Staff.fromJson(item)))
          : null,
    );
  }
}

class ThreadListResponse {
  final bool? success;
  final String? message;
  final List<ChatThread>? data;

  ThreadListResponse({
    this.success,
    this.message,
    this.data,
  });

  factory ThreadListResponse.fromJson(Map<String, dynamic> json) {
    return ThreadListResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? List<ChatThread>.from(
              json['data'].map((item) => ChatThread.fromJson(item)))
          : null,
    );
  }
}

class MessageListResponse {
  final bool? success;
  final String? message;
  final List<ChatMessage>? data;

  MessageListResponse({
    this.success,
    this.message,
    this.data,
  });

  factory MessageListResponse.fromJson(Map<String, dynamic> json) {
    return MessageListResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? List<ChatMessage>.from(
              json['data'].map((item) => ChatMessage.fromJson(item)))
          : null,
    );
  }
}

class StartChatResponse {
  final bool? success;
  final String? message;
  final ChatThread? data;

  StartChatResponse({
    this.success,
    this.message,
    this.data,
  });

  factory StartChatResponse.fromJson(Map<String, dynamic> json) {
    return StartChatResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? ChatThread.fromJson(json['data']) : null,
    );
  }
}

class SendMessageResponse {
  final bool? success;
  final String? message;
  final ChatMessage? data;

  SendMessageResponse({
    this.success,
    this.message,
    this.data,
  });

  factory SendMessageResponse.fromJson(Map<String, dynamic> json) {
    return SendMessageResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? ChatMessage.fromJson(json['data']) : null,
    );
  }
}
