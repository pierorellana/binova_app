import '../../../accounts/domain/entities/money.dart';
import '../entities/beneficiary.dart';
import '../entities/debt.dart';
import '../entities/financial_operation.dart';

abstract interface class OperationsRepository {
  Future<List<Beneficiary>> listBeneficiaries();
  Future<FinancialOperation> createTransfer({
    required String sourceAccountId,
    required String beneficiaryId,
    required Money amount,
    String? note,
    required String idempotencyKey,
  });
  Future<Debt> getDebt(
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
  Future<FinancialOperation> getOperation(String id);
}
