import 'dart:html';

import 'package:firebase/firebase.dart' as firebase;

import 'package:hades_simulator/star.dart';

main() async {
  firebase.initializeApp(
      apiKey: 'AIzaSyDSEG_xCVQrYrDiEbc9LI2zGFuAzhNMLMA',
      authDomain: 'hades-star-a1bff.firebaseapp.com',
      databaseURL: 'https://hades-star-a1bff.firebaseio.com',
      projectId: 'hades-star-a1bff',
      storageBucket: 'hades-star-a1bff.appspot.com',
      messagingSenderId: '927697248914');
  var database = firebase.database();

  var createStar = document.body.querySelector('#create_star') as ButtonElement;
  var starName = document.body.querySelector('#star_name') as InputElement;
  var creatingSpan = document.body.querySelector('#creating') as SpanElement;

  // ignore: unawaited_futures
  createStar.onClick.first.then((_) async {
    var name = starName.value;
    if (name.isEmpty) {
      window.alert('You must give the star a name first!');
      return;
    }
    starName.value = '';
    creatingSpan.text = 'creating...';
    await Star.createWithLayers(4, name, database);
  });

  var starList = document.body.querySelector('#existing_stars') as UListElement;
  database.ref('stars').onChildAdded.listen((event) {
    creatingSpan.text = '';
    var star = new Star.fromJson(
        (event.snapshot.toJson() as Map).cast<String, dynamic>());
    var href = 'star.html?${star.firebaseId}';
    starList.append(new LIElement()
      ..append(new AnchorElement()
        ..href = href
        ..text = star.name));
  });
}
