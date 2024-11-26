import 'package:flutter/material.dart';

class Words extends ChangeNotifier {
  String? _subject;

  final List<String> foodList = ["우거지국", "갈아만든 배"];
  final List<String> plantList = ["사시 나무", "오동 나무", "카카오 나무"];
  final List<String> animalList = ["개", "고양이"];

  String? get subject => _subject;

  set subject(String? value){
    _subject = value;

    notifyListeners();
  }

  List<String> returnSubjectList() {
    if (_subject == "food") {
      return foodList;
    } else if (_subject == "plant") {
      return plantList;
    } else{
      return animalList;
    }
  }



}
