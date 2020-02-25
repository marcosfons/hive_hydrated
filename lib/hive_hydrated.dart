library hive_hydrated;

import 'dart:async';

import 'package:hive/hive.dart';
import 'package:meta/meta.dart';

import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';


class HiveHydratedSubject<T> extends Subject<T> implements ValueStream<T> {

  String _boxName;
  _Wrapper _wrapper;
  Box<T> _box;
  StreamSubscription _boxSubscription;

  String get boxName => this._boxName;

  HiveHydratedSubject._(
    this._boxName,
    this._wrapper,
    T firstValue,
    StreamController<T> controller,
    Stream<T> observable,
    String hivePath,
    Future<String> Function() hivePathAsync,
    bool hiveAlreadyInitiated
  ) : super(controller, observable) {
    
    if(hiveAlreadyInitiated)
      _boxInitialize(boxName, firstValue);
    else if(hivePath != null) {
      Hive.init(hivePath);
      _boxInitialize(boxName, firstValue);
    } else {
      hivePathAsync()
      .then((path) async {
        Hive.init(path);
        _boxInitialize(boxName, firstValue);
      })
      .catchError((e) => throw(e));
    }
  }

  factory HiveHydratedSubject({
    @required String boxName,
    T seedValue,
    T firstValue,
    bool alreadyOpen = false,
    String hivePath,
    Future<String> Function() hivePathAsync,
    bool sync = false,
    TypeAdapter<T> adapter
  }) {
    assert(hivePath != null || hivePathAsync != null);

    // ignore: close_sinks
    final controller = StreamController<T>.broadcast(sync: sync);
    
    final wrapper = _Wrapper<T>(seedValue);
    
    if(adapter != null) Hive.registerAdapter(adapter);
    
    return HiveHydratedSubject._(
      boxName,
      wrapper,
      firstValue,
      controller,
      Rx.defer<T>(
        () => wrapper.latestValue == null
            ? controller.stream
            : controller.stream
                .startWith(wrapper.latestValue),
        reusable: true),
      hivePath,
      hivePathAsync,
      alreadyOpen
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
    if(_boxSubscription != null)
      _boxSubscription.cancel();
    _box.close();
    return super.close();
  }

  @override
  void onAdd(T event) {
    if(_wrapper.latestValue != event) {
      _wrapper.latestValue = event;
      _persist(event);
    }
  }

  void _boxInitialize(String boxName, T firstValue) {
    Hive.openBox<T>(_boxName)
      .then((Box<T> box) {
        final T value = box.get(0);
        if (value != null)
          addFirst(value);
        else if(firstValue != null)
          addFirst(firstValue);
        _box = box;

        _boxSubscription = _box.watch()
          .map<T>((BoxEvent event) => event.value)
          .listen((T value) => add(value));
      }).catchError((e) => throw(e));
  }

  void addFirst(T value) {
    _wrapper.latestValue = value;
    add(value);
  }

  void _persist(T value) {
    _box.put(0, value);
    // Hive.box<T>(_boxName).put(0, value);
  }
}


class _Wrapper<T> {
  T latestValue;

  _Wrapper(this.latestValue);

  bool hasValue() => latestValue != null;
}