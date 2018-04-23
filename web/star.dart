import 'dart:async';
import 'dart:html';

import 'package:firebase/firebase.dart' as firebase;

import 'package:hades_simulator/common.dart';
import 'package:hades_simulator/jump_gate.dart';
import 'package:hades_simulator/sector.dart';
import 'package:hades_simulator/planet.dart';
import 'package:hades_simulator/star.dart';

main() async {
  var starId = window.location.search;
  if (starId.isNotEmpty) {
    starId = starId.substring(1);
  } else {
    window.alert('invalid star id!');
    return;
  }

  firebase.initializeApp(
      apiKey: 'AIzaSyDSEG_xCVQrYrDiEbc9LI2zGFuAzhNMLMA',
      authDomain: 'hades-star-a1bff.firebaseapp.com',
      databaseURL: 'https://hades-star-a1bff.firebaseio.com',
      projectId: 'hades-star-a1bff',
      storageBucket: 'hades-star-a1bff.appspot.com',
      messagingSenderId: '927697248914');
  var database = firebase.database();
  var starJson = (await database.ref('stars').child(starId).once('value'))
      .snapshot
      .toJson() as Map;
  var star = new Star.fromJson(starJson.cast<String, dynamic>());

  var sectorsRef = database.ref('/sectors/$starId');
  var sectorsJson = (await sectorsRef.once('value')).snapshot.toJson() as Map;
  assert(sectorsJson != null);
  var sectors = sectorsJson.values.map((sectorJson) =>
      new Sector.fromJson((sectorJson as Map).cast<String, dynamic>()));
  star.sectors.addAll(sectors);

  var planetsRef = database.ref('/planets/$starId');
  var planetsJson = (await planetsRef.once('value')).snapshot.toJson() as Map;
  if (planetsJson != null) {
    var planets = planetsJson.values.map((planetJson) =>
        new Planet.fromJson((planetJson as Map).cast<String, dynamic>()));
    star.planets.addAll(planets);
  }

  var jumpGatesRef = database.ref('/jump_gates/$starId');
  var jumpGatesJson =
      (await jumpGatesRef.once('value')).snapshot.toJson() as Map;
  if (jumpGatesJson != null) {
    var jumpGates = jumpGatesJson.values.map((jumpGateJson) =>
        new JumpGate.fromJson((jumpGateJson as Map).cast<String, dynamic>()));
    star.jumpGates.addAll(jumpGates);
  }

  var gameCtx = new GameContext(
    star: star,
    scale: 0.3, /*db: db*/
  );
  var canvas = document.body.querySelector('#game') as CanvasElement;

  var width = star.width.floor();
  var height = star.height.floor();
  canvas.style
    ..width = '${width}px'
    ..height = '${height}px';
  canvas.width = width;
  canvas.height = height;

  canvas.context2D.scale(gameCtx.scale, gameCtx.scale);
  _updateStar(star, canvas, gameCtx);

  var newPlanetButton = document.body.querySelector('#add_planet');
  newPlanetButton.onClick.listen((_) {
    var planet = new Planet(x: Sector.WIDTH / 2, y: Sector.HEIGHT / 2);
    star.planets.add(planet);
    _updateStar(star, canvas, gameCtx);
  });

  var newJumpGateButton =
      document.body.querySelector('#add_jg') as ButtonElement;
  var newJumpGateSectorInput =
      document.body.querySelector('#jg_sector') as InputElement;
  newJumpGateButton.onClick.listen((_) {
    var sectorName = newJumpGateSectorInput.value;
    var sector = star.sectors
        .firstWhere((s) => s.name == sectorName.toLowerCase(), orElse: () {
      window.alert('Unable to find a sector by the name "$sectorName');
      return null;
    });
    if (sector == null) return;
    var jG = new JumpGate(
        x: sector.x - JumpGate.SIZE / 2, y: sector.y - JumpGate.SIZE / 2);
    star.jumpGates.add(jG);
    _updateStar(star, canvas, gameCtx);
  });

  var saveButton = document.body.querySelector('#save') as ButtonElement;
  saveButton.onClick.listen((_) {
    _updateDb(star, database);
  });

  canvas.onMouseDown.listen((e) {
    var x = e.client.x;
    var y = e.client.y;
    for (var planet in star.planets) {
      if (_rectCollide(x, y, planet, gameCtx.scale)) {
        planet.startDrag(e, canvas, gameCtx).listen((_) {
          _updateStar(star, canvas, gameCtx);
        });
        break;
      }
    }
  });
}

void _updateStar(Star star, CanvasElement canvas, GameContext gameCtx) {
  var renderCtx = canvas.context2D;
  renderCtx.setFillColorRgb(0, 0, 0);
  renderCtx.fillRect(0, 0, canvas.width, canvas.height);
  gameCtx.star.draw(renderCtx, gameCtx);
}

bool _rectCollide(num x, num y, GameObject object, num scale) {
  x = x / scale;
  y = y / scale;
  var width = object.width / scale;
  var height = object.height / scale;
  if (x < object.x || x > object.x + width) return false;
  if (y < object.y || y > object.y + height) return false;
  return true;
}

bool _updating = false;
Star _nextUpdate;

Future _updateDb(Star star, firebase.Database db) async {
  var savingSpan = document.body.querySelector('#saving');
  if (_updating) {
    _nextUpdate = star;
    return;
  }
  savingSpan.text = 'saving...';
  _updating = true;

  var starRef = db.ref('/stars/${star.firebaseId}');
  await starRef.set(star.toJson());

  var sectorsRef = db.ref('/sectors/${star.firebaseId}');
  await sectorsRef.set(star.sectors.map((sector) => sector.toJson()).toList());

  var planetsRef = db.ref('/planets/${star.firebaseId}');
  await planetsRef.set(star.planets.map((planet) => planet.toJson()).toList());

  var jumpGatesRef = db.ref('/jump_gates/${star.firebaseId}');
  await jumpGatesRef
      .set(star.jumpGates.map((jumpGate) => jumpGate.toJson()).toList());

  savingSpan.text = 'done!';
  _updating = false;
  if (_nextUpdate != null) {
    _nextUpdate = null;
    // ignore: unawaited_futures
    _updateDb(_nextUpdate, db);
  }
}
