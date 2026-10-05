import '../../../../core/network/authenticated_api_client.dart';
import '../../../accounts/domain/entities/money.dart';
import '../../domain/entities/beneficiary.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/financial_operation.dart';

abstract interface class OperationsRemoteDataSource {
  Future<List<Beneficiary>> fetchBeneficiaries();
  Future<FinancialOperation> createTransfer({
    required String sourceAccountId,
    required String beneficiaryId,
    required Money amount,
    String? note,
    required String idempotencyKey,
  });
  Future<Debt> fetchDebt(
      {required String providerId, required String accountReference});
  Future<FinancialOperation> createPayment({
    required String providerId,
    required String accountReference,
    required String sourceAccountId,
    required Money amount,
    required String debtReference,
    required String idempotencyKey,
  });
  Future<FinancialOperation> createTopup({
    required String operatorId,
    required String lineNumber,
    required String sourceAccountId,
    required Money amount,
    required String idempotencyKey,
  });
  Future<FinancialOperation> fetchOperation(String id);
}

class HttpOperationsRemoteDataSource implements OperationsRemoteDataSource {
  HttpOperationsRemoteDataSource(this._client);

  final AuthenticatedApiClient _client;

  @override
  Future<List<Beneficiary>> fetchBeneficiaries() async {
    final response = await _client.get('/beneficiaries');
    if (response.data is! List) {
      throw const FormatException('Invalid beneficiaries payload.');
    }
    return (response.data as List)
        .whereType<Map>()
        .map((item) => Beneficiary.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  @override
  Future<FinancialOperation> createTransfer({
    required String sourceAccountId,
    required String beneficiaryId,
    required Money amount,
    String? note,
    required String idempotencyKey,
  }) =>
      _operation(
        _client.post(
          '/transfers',
          body: <String, dynamic>{
            'sourceAccountId': sourceAccountId,
            'beneficiaryId': beneficiaryId,
            'amount': amount.toMap(),
            if (note != null && note.isNotEmpty) 'note': note,
          },
          idempotencyKey: idempotencyKey,
        ),
      );

  @override
  Future<Debt> fetchDebt(
      {required String providerId, required String accountReference}) async {
    final response = await _client.get(
      '/payments/debt',
      queryParameters: <String, String?>{
        'providerId': providerId,
        'accountReference': accountReference,
      },
    );
    if (response.data is! Map) {
      throw const FormatException('Invalid debt payload.');
    }
    return Debt.fromMap(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<FinancialOperation> createPayment({
    required String providerId,
    required String accountReference,
    required String sourceAccountId,
    required Money amount,
    required String debtReference,
    required String idempotencyKey,
  }) =>
      _operation(
        _client.post(
          '/payments',
          body: <String, dynamic>{
            'providerId': providerId,
            'accountReference': accountReference,
            'sourceAccountId': sourceAccountId,
            'amount': amount.toMap(),
            'debtReference': debtReference,
          },
          idempotencyKey: idempotencyKey,
        ),
      );

  @override
  Future<FinancialOperation> createTopup({
    required String operatorId,
    required String lineNumber,
    required String sourceAccountId,
    required Money amount,
    required String idempotencyKey,
  }) =>
      _operation(
        _client.post(
          '/topups',
          body: <String, dynamic>{
            'operatorId': operatorId,
            'lineNumber': lineNumber,
            'sourceAccountId': sourceAccountId,
            'amount': amount.toMap(),
          },
          idempotencyKey: idempotencyKey,
        ),
      );

  @override
  Future<FinancialOperation> fetchOperation(String id) =>
      _operation(_client.get('/operations/$id'));

  Future<FinancialOperation> _operation(Future<dynamic> request) async {
    final response = await request;
    if (response.data is! Map) {
      throw const FormatException('Invalid operation payload.');
    }
    return FinancialOperation.fromMap(
        Map<String, dynamic>.from(response.data as Map));
  }
}
