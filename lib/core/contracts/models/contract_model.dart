import '../../utils/data_utils.dart';

class ContractModel {
  ContractModel({
    required this.id,
    required this.companyId,
    required this.title,
    required this.contractNumber,
    required this.vendor,
    required this.value,
    this.currency = 'LE',
    required this.startDateMs,
    required this.endDateMs,
    required this.status, // 'Active' | 'Pending' | 'Expired' | 'Terminated'
    required this.createdAtMs,
  });

  String id;
  String companyId;
  String title;
  String contractNumber;
  String vendor;
  String value;
  String currency;
  int startDateMs;
  int endDateMs;
  String status;
  int createdAtMs;

  factory ContractModel.fromMap(Map<String, dynamic> data, String docId) {
    return ContractModel(
      id: docId,
      companyId: DataUtils.asString(data['companyId']),
      title: DataUtils.asString(data['title'], 'Untitled'),
      contractNumber: DataUtils.asString(data['contractNumber'], 'N/A'),
      vendor: DataUtils.asString(data['vendor'], 'Unknown Vendor'),
      value: DataUtils.asString(data['value'], '0'),
      currency: DataUtils.asString(data['currency'], 'LE'),
      startDateMs: DataUtils.asInt(data['startDateMs']),
      endDateMs: DataUtils.asInt(data['endDateMs']),
      status: DataUtils.asString(data['status'], 'Pending'),
      createdAtMs: DataUtils.asInt(data['createdAtMs']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'title': title,
      'contractNumber': contractNumber,
      'vendor': vendor,
      'value': value,
      'currency': currency,
      'startDateMs': startDateMs,
      'endDateMs': endDateMs,
      'status': status,
      'createdAtMs': createdAtMs,
    };
  }
}
