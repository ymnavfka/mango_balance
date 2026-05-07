import 'dart:async';

class ActiveProfileHolder {
  ActiveProfileHolder({required int initialId}) : _id = initialId;

  int _id;
  final StreamController<int> _controller = StreamController<int>.broadcast();

  int get id => _id;
  Stream<int> get stream => _controller.stream;

  void update(int id) {
    if (_id == id) return;
    _id = id;
    _controller.add(id);
  }

  Future<void> close() => _controller.close();
}
