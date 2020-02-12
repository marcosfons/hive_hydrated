library hive_hydrated;

import 'dart:async';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:meta/meta.dart';

import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';


class HiveHydratedSubject<T> extends Subject<T> implements ValueStream<T> {

  String _boxName;
  _Wrapper _wrapper;
  T _seedValue;

  String get boxName => this._boxName;

  HiveHydratedSubject._(
    this._boxName,
    this._wrapper,
    String hivePath,
    StreamController<T> controller,
    Stream<T> observable,
  ) : super(controller, observable) {
    Hive.init(hivePath);
    _hydrateSubject();
  }

  factory HiveHydratedSubject({
    @required String boxName,
    T seedValue,
    String hivePath,
    bool sync = false
  }) {

    // ignore: close_sinks
    final controller = StreamController<T>.broadcast(
      sync: sync
    );

    final wrapper = _Wrapper<T>(seedValue);

    if(hivePath == null) 
      hivePath = Directory.current.path;

    return HiveHydratedSubject._(
      boxName,
      wrapper,
      hivePath,
      controller,
      Rx.defer<T>(
        () => wrapper.latestValue == null
            ? controller.stream
            : controller.stream
                .startWith(wrapper.latestValue),
        reusable: true),
    );
  }
  
  @override
  ValueStream<T> get stream => this;

  @override
  bool get hasValue => _wrapper.hasValue();

  @override
  T get value => _wrapper.latestValue;

  @override
  Future<dynamic> close() {
    Hive.box(_boxName).close();
    return super.close();
  }

  @override
  void onAdd(T event) { 
    _wrapper.latestValue = event;
    _persist(event);
  }

  void _hydrateSubject() {
    Hive.openBox(_boxName)
      .then((box) {
        final value = box.get(0);
        if(value != null && value != _seedValue)
          add(value);
      });
  }

  void _persist(T value) {
    Hive.box(_boxName).put(0, value);
  }
}


class _Wrapper<T> {
  T latestValue;

  _Wrapper(this.latestValue);

  bool hasValue() => latestValue != null;
}