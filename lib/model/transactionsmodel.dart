import 'dart:convert';

class ApiResponse {
  final bool success;
  final String message;
  final Data data;

  ApiResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'],
      message: json['message'],
      data: Data.fromJson(json['data']),
    );
  }
}

class Data {
  final bool requestSuccessful;
  final String responseMessage;
  final String responseCode;
  final ResponseBody responseBody;

  Data({
    required this.requestSuccessful,
    required this.responseMessage,
    required this.responseCode,
    required this.responseBody,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      requestSuccessful: json['requestSuccessful'],
      responseMessage: json['responseMessage'],
      responseCode: json['responseCode'],
      responseBody: ResponseBody.fromJson(json['responseBody']),
    );
  }
}

class ResponseBody {
  final List<Content> content;
  final Pageable pageable;
  final bool last;
  final int totalElements;
  final int totalPages;
  final bool first;
  final int numberOfElements;
  final int size;
  final int number;
  final bool empty;

  ResponseBody({
    required this.content,
    required this.pageable,
    required this.last,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.numberOfElements,
    required this.size,
    required this.number,
    required this.empty,
  });

  factory ResponseBody.fromJson(Map<String, dynamic> json) {
    return ResponseBody(
      content: List<Content>.from(json['content'].map((x) => Content.fromJson(x))),
      pageable: Pageable.fromJson(json['pageable']),
      last: json['last'],
      totalElements: json['totalElements'],
      totalPages: json['totalPages'],
      first: json['first'],
      numberOfElements: json['numberOfElements'],
      size: json['size'],
      number: json['number'],
      empty: json['empty'],
    );
  }
}

class Content {
  final String walletTransactionReference;
  final String monnifyTransactionReference;
  final dynamic availableBalanceBefore;
  final dynamic availableBalanceAfter;
  final double amount;
  final String transactionDate;
  final String transactionType;
  final dynamic message;
  final dynamic narration;
  final String status;

  Content({
    required this.walletTransactionReference,
    required this.monnifyTransactionReference,
    this.availableBalanceBefore,
    this.availableBalanceAfter,
    required this.amount,
    required this.transactionDate,
    required this.transactionType,
    this.message,
    this.narration,
    required this.status,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      walletTransactionReference: json['walletTransactionReference'],
      monnifyTransactionReference: json['monnifyTransactionReference'],
      availableBalanceBefore: json['availableBalanceBefore'],
      availableBalanceAfter: json['availableBalanceAfter'],
      amount: json['amount'].toDouble(),
      transactionDate: json['transactionDate'],
      transactionType: json['transactionType'],
      message: json['message'],
      narration: json['narration'],
      status: json['status'],
    );
  }
}

class Pageable {
  final Sort sort;
  final int pageSize;
  final int pageNumber;
  final int offset;
  final bool paged;
  final bool unpaged;

  Pageable({
    required this.sort,
    required this.pageSize,
    required this.pageNumber,
    required this.offset,
    required this.paged,
    required this.unpaged,
  });

  factory Pageable.fromJson(Map<String, dynamic> json) {
    return Pageable(
      sort: Sort.fromJson(json['sort']),
      pageSize: json['pageSize'],
      pageNumber: json['pageNumber'],
      offset: json['offset'],
      paged: json['paged'],
      unpaged: json['unpaged'],
    );
  }
}

class Sort {
  final bool sorted;
  final bool unsorted;
  final bool empty;

  Sort({
    required this.sorted,
    required this.unsorted,
    required this.empty,
  });

  factory Sort.fromJson(Map<String, dynamic> json) {
    return Sort(
      sorted: json['sorted'],
      unsorted: json['unsorted'],
      empty: json['empty'],
    );
  }
}
