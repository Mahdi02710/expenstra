import 'package:intl/intl.dart';

enum WalletType { bank, savings, credit, cash, investment }

class Wallet {
  final String id;
  final String name;
  final double balance;
  final WalletType type;
  final String icon;
  final String color;
  final String accountNumber;
  final String? bankName;
  final double? creditLimit;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastTransactionDate;

  const Wallet({
    required this.id,
    required this.name,
    required this.balance,
    required this.type,
    required this.icon,
    required this.color,
    required this.accountNumber,
    this.bankName,
    this.creditLimit,
    this.isActive = true,
    required this.createdAt,
    this.lastTransactionDate,
  });

  // Helper getters
  bool get isCredit => type == WalletType.credit;
  bool get isCash => type == WalletType.cash;
  bool get isBank => type == WalletType.bank || type == WalletType.savings;
  bool get isInvestment => type == WalletType.investment;

  String get typeLabel {
    switch (type) {
      case WalletType.bank:
        return 'Bank Account';
      case WalletType.savings:
        return 'Savings Account';
      case WalletType.credit:
        return 'Credit Card';
      case WalletType.cash:
        return 'Cash';
      case WalletType.investment:
        return 'Investment Account';
    }
  }

  String get balanceStatus {
    if (isCredit) {
      return balance < 0 ? 'Balance Due' : 'Credit Available';
    }
    return 'Current Balance';
  }

  String get formattedBalance {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(balance.abs());
  }

  String get formattedBalanceWithSign {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    if (isCredit && balance < 0) {
      return '-${formatter.format(balance.abs())}';
    }
    return formatter.format(balance);
  }

  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    return '•••• ${accountNumber.substring(accountNumber.length - 4)}';
  }

  double get creditUtilization {
    if (!isCredit || creditLimit == null || creditLimit == 0) return 0.0;
    return (balance.abs() / creditLimit!).clamp(0.0, 1.0);
  }

  String get creditUtilizationPercentage {
    return '${(creditUtilization * 100).toStringAsFixed(1)}%';
  }

  String get lastActivityText {
    if (lastTransactionDate == null) return 'No recent activity';
    
    final now = DateTime.now();
    final difference = now.difference(lastTransactionDate!);
    
    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Last activity yesterday';
      } else if (difference.inDays < 30) {
        return 'Last activity ${difference.inDays} days ago';
      } else {
        return 'Last activity ${DateFormat('MMM dd').format(lastTransactionDate!)}';
      }
    } else if (difference.inHours > 0) {
      return 'Last activity ${difference.inHours}h ago';
    } else {
      return 'Active recently';
    }
  }

  // Factory methods
  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'],
      name: json['name'],
      balance: json['balance'].toDouble(),
      type: WalletType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      icon: json['icon'],
      color: json['color'],
      accountNumber: json['accountNumber'],
      bankName: json['bankName'],
      creditLimit: json['creditLimit']?.toDouble(),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      lastTransactionDate: json['lastTransactionDate'] != null
          ? DateTime.parse(json['lastTransactionDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'type': type.toString(),
      'icon': icon,
      'color': color,
      'accountNumber': accountNumber,
      'bankName': bankName,
      'creditLimit': creditLimit,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastTransactionDate': lastTransactionDate?.toIso8601String(),
    };
  }

  // Copy with method
  Wallet copyWith({
    String? id,
    String? name,
    double? balance,
    WalletType? type,
    String? icon,
    String? color,
    String? accountNumber,
    String? bankName,
    double? creditLimit,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastTransactionDate,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      creditLimit: creditLimit ?? this.creditLimit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Wallet && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Wallet(id: $id, name: $name, type: $type, balance: $balance)';
  }
}