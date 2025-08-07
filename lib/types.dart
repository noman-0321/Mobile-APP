// ignore_for_file: constant_identifier_names
class Val {
  final String name;
  final int value;

  Val({required this.name,required this.value});
}

enum ChestPain implements Val {
  NoPain(name: "No Pain", value: 0),
  Pain(name: "Pain", value: 1),
  MildPain(name: "Mild Pain", value: 2),
  SeverePain(name: "Severe Pain", value: 3);

  @override
  final String name;
  @override
  final int value;

  const ChestPain({required this.name, required this.value});
}



enum Gender implements Val {
  Male(name: "Male", value: 0),
  Female(name: "Female", value: 1);

  @override
  final String name;
  @override
  final int value;

  const Gender({required this.name, required this.value});
}


enum FastingBloodSugar implements Val {
  Normal(name: "Normal", value: 0),
  Abnormal(name: "Abnormal", value: 1);

  @override
  final String name;
  @override
  final int value;

  const FastingBloodSugar({required this.name, required this.value});
}


enum RestingECG implements Val {
  Normal(name: "Normal", value: 0),
  Abnormal(name: "Abnormal", value: 1),
  Mild(name: "Mild", value: 2),
  Severe(name: "Severe", value: 3);

  @override
  final String name;
  @override
  final int value;

  const RestingECG({required this.name, required this.value});
}


enum ExerciseInducedAngina implements Val {
  Yes(name: "Yes", value: 1),
  No(name: "No", value: 0);

  @override
  final String name;
  @override
  final int value;

  const ExerciseInducedAngina({required this.name, required this.value});
}
