class Amount {
  Amount(this.value) {
    if (value <= 0) {
      throw Exception('Amount must be greater than zero');
    }
  }

  bool operator <=(Amount other) => value <= other.value;
  bool operator >(Amount other) => value > other.value;
  bool operator <(Amount other) => value < other.value;
  bool operator >=(Amount other) => value >= other.value;
  @override
  bool operator ==(Object other) => other is Amount && value == other.value;
  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();

  final double value;
}
