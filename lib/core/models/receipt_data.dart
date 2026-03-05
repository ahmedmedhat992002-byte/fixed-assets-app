class ReceiptData {
  final String senderName;
  final String senderPhone;
  final String senderEmail;
  final String senderAddress;
  final String receiverName;
  final String receiverPhone;
  final String receiverEmail;
  final String receiverAddress;
  final double total;
  final String currency;
  final String paymentMethod;
  final String transactionId;
  final String status;
  final String barcodeValue;

  ReceiptData({
    required this.senderName,
    required this.senderPhone,
    required this.senderEmail,
    required this.senderAddress,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverEmail,
    required this.receiverAddress,
    required this.total,
    this.currency = 'LE ',
    required this.paymentMethod,
    required this.transactionId,
    required this.status,
    required this.barcodeValue,
  });

  static ReceiptData mock() {
    return ReceiptData(
      senderName: 'Jack spow',
      senderPhone: '+01296498979',
      senderEmail: 'Jack.spow019@gmail.com',
      senderAddress: 'Egypt / Cairo / Maadi',
      receiverName: 'Jack spow',
      receiverPhone: '+01296498979',
      receiverEmail: 'Jack.spow019@gmail.com',
      receiverAddress: 'Egypt / Cairo / Maadi',
      total: 40.00,
      paymentMethod: 'Paypal',
      transactionId: 'NB145618X8S',
      status: 'In review',
      barcodeValue: '(01)75842361594750    (01)75842361594750',
    );
  }
}
