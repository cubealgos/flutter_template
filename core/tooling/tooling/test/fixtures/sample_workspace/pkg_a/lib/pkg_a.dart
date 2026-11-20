/// A tiny fixture library exercising every declaration kind map_generator
/// should report, plus one private declaration it should skip.
library;

class Greeter {
  const Greeter(this.name);
  final String name;
}

class _PrivateHelper {
  void hush() {}
}

enum Color { red, green, blue }

mixin Loud {
  void shout();
}

extension StringShout on String {
  String shout() => '$this!';
}

String greet(String name) => 'hi $name';
