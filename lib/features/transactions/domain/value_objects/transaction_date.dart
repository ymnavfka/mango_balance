class TransactionDate {
  TransactionDate(this.value) {
    if (value.isAfter(DateTime.now())) {
      throw Exception('Дата не может быть в будущем');
    }
  }
  final DateTime value;
}
