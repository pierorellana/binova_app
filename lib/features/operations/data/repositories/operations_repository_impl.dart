import '../../../accounts/domain/entities/money.dart';
import '../../domain/entities/beneficiary.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/financial_operation.dart';
import '../../domain/repositories/operations_repository.dart';
import '../datasources/operations_remote_data_source.dart';

class OperationsRepositoryImpl implements OperationsRepository {
  OperationsRepositoryImpl(this._remote);

  final OperationsRemoteDataSource _remote;

  @override
  Future<List<Beneficiary>> listBeneficiaries() => _remote.fetchBeneficiaries();

  @override
  Future<FinancialOperation> createTransfer({
    required String sourceAccountId,
    required String beneficiaryId,
    required Money amount,
    String? note,
    required String idempotencyKey,
  }) =>
      _remote.createTransfer(
        sourceAccountId: sourceAccountId,
        beneficiaryId: beneficiaryId,
        amount: amount,
        note: note,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<Debt> getDebt(
          {required String providerId, required String accountReference}) =>
      _remote.fetchDebt(
          providerId: providerId, accountReference: accountReference);

  @override
  Future<FinancialOperation> createPayment({
    required String providerId,
    required String accountReference,
    required String sourceAccountId,
    required Money amount,
    required String debtReference,
    required String idempotencyKey,
  }) =>
      _remote.createPayment(
        providerId: providerId,
        accountReference: accountReference,
        sourceAccountId: sourceAccountId,
        amount: amount,
        debtReference: debtReference,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<FinancialOperation> createTopup({
    required String operatorId,
    required String lineNumber,
    required String sourceAccountId,
    required Money amount,
    required String idempotencyKey,
  }) =>
      _remote.createTopup(
        operatorId: operatorId,
        lineNumber: lineNumber,
        sourceAccountId: sourceAccountId,
        amount: amount,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<FinancialOperation> getOperation(String id) =>
      _remote.fetchOperation(id);
}
