library hive_hydrated;

import 'dart:async';

import 'package:hive/hive.dart';
import 'package:meta/meta.dart';

import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';


class HiveHydratedSubject<T> extends Subject<T> implements ValueStream<T> {

  String _boxName;
  _Wrapper _wrapper;

  // T Function(String value) _hydrate;
  // String Function(T value) _persist;
  
  T _seedValue;

  String get boxName => this._boxName;

  HiveHydratedSubject._(
    this._boxName,
    StreamController<T> controller,
    Stream<T> observable,
    this._wrapper,
  ) : super(controller, observable) {
    _hydrateSubject();
  }


  factory HiveHydratedSubject({
    @required String boxName,
    T seedValue,
    bool sync = false
  }) {

    // ignore: close_sinks
    final controller = StreamController<T>.broadcast(
      sync: sync
    );

    final wrapper = _Wrapper<T>(seedValue);

    return HiveHydratedSubject._(
      boxName,
      controller,
      Rx.defer<T>(
        () => wrapper.latestValue == null
            ? controller.stream
            : controller.stream
                .startWith(wrapper.latestValue),
        reusable: true),
      wrapper
    );
  }
  
  @override
  ValueStream<T> get stream => this;

  @override
  bool get hasValue => _wrapper.hasValue();

  @override
  T get value => _wrapper.latestValue;

  @override
  void onAdd(T event) { 
    _wrapper.latestValue = event;
    _persist(event);
  }

  void _hydrateSubject() {
    final box = Hive.box(_boxName);
    final value = box.getAt(0);

    if(value != null && value != _seedValue) {
      add(value);
    }

    box.close();
  }

  void _persist(T value) {
    final box = Hive.box(_boxName);
    box.putAt(0, value);
    box.close();
  }

}



class _Wrapper<T> {
  T latestValue;

  _Wrapper(this.latestValue);

  bool hasValue() => latestValue != null;
}