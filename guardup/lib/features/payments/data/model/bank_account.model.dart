/// Model representing a user's or company's saved bank account.
class BankAccount {
  final String id;
  final String accountNumber;
  final String accountHolder;
  final String bankName;
  final String branch;
  final String ifscCode;
  final String? branchAddress;

  const BankAccount({
    required this.id,
    required this.accountNumber,
    required this.accountHolder,
    required this.bankName,
    required this.branch,
    required this.ifscCode,
    this.branchAddress,
  });


  BankAccount copyWith({
    String? id,
    String? accountNumber,
    String? accountHolder,
    String? bankName,
    String? branch,
    String? ifscCode,
    String? branchAddress,
  }) {
    return BankAccount(
      id: id ?? this.id,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolder: accountHolder ?? this.accountHolder,
      bankName: bankName ?? this.bankName,
      branch: branch ?? this.branch,
      ifscCode: ifscCode ?? this.ifscCode,
      branchAddress: branchAddress ?? this.branchAddress,
    );
  }
}

