enum BeneficiaryStatus { active, blocked }

class Beneficiary {
  const Beneficiary({
    required this.id,
    required this.displayName,
    required this.bankName,
    required this.maskedAccountNumber,
    required this.status,
  });

  final String id;
  final String displayName;
  final String bankName;
  final String maskedAccountNumber;
  final BeneficiaryStatus status;

  factory Beneficiary.fromMap(Map<String, dynamic> map) {
    if (map['id'] is! String ||
        map['displayName'] is! String ||
        map['bankName'] is! String ||
        map['maskedAccountNumber'] is! String ||
        map['status'] is! String) {
      throw const FormatException('Invalid beneficiary.');
    }
    return Beneficiary(
      id: map['id'] as String,
      displayName: map['displayName'] as String,
      bankName: map['bankName'] as String,
      maskedAccountNumber: map['maskedAccountNumber'] as String,
      status: switch (map['status'] as String) {
        'active' => BeneficiaryStatus.active,
        'blocked' => BeneficiaryStatus.blocked,
        _ => throw const FormatException('Invalid beneficiary status.'),
      },
    );
  }
}
