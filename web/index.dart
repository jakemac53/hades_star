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
    var starRef = database.ref('stars').push();
    var star = new Star.withLayers(4, starRef.key, name);

    // Push the sectors before the star, we need to push them individually which takes a minute.
    var sectorsRef = database.ref('sectors').child(star.firebaseId);
    await sectorsRef.set({});
    for (var i = 0; i < star.sectors.length; i++) {
      var sectorRef = sectorsRef.child('$i');
      await sectorRef.set(star.sectors[i].toJson());
    }

    await starRef.set(star.toJson());
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
