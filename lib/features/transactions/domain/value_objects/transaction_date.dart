class TransactionDate {
  TransactionDate(this.value) {
    if (value.isAfter(DateTime.now())) {
      throw Exception('Date cannot be in the future');
    }
  }
  final DateTime value;
}
