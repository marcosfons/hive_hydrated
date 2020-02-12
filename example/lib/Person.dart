import 'package:hive/hive.dart';

part 'Person.g.dart';

@HiveType(typeId: 0)
class Person {
  @HiveField(0)
  String name;

  @HiveField(1)
  int age;

  @HiveField(2)
  List<Person> friends;
}