import 'dart:async';
import 'dart:html';

import 'package:firebase/firebase.dart' as firebase;

import 'package:hades_simulator/common.dart';
import 'package:hades_simulator/jump_gate.dart';
import 'package:hades_simulator/sector.dart';
import 'package:hades_simulator/planet.dart';
import 'package:hades_simulator/star.dart';

final selected = <Planet>[];

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
  var starRef = database.ref('stars').child(starId);
  var starJson = (await starRef.once('value')).snapshot.toJson() as Map;
  var star = new Star.fromJson(starJson.cast<String, dynamic>());

  var sectorsRef = database.ref('/sectors/$starId');
  var sectorsJson = (await sectorsRef.once('value')).snapshot.toJson() as Map;
  assert(sectorsJson != null);
  var sectors = sectorsJson.values.map((sectorJson) =>
      new Sector.fromJson((sectorJson as Map).cast<String, dynamic>()));
  star.sectors.addAll(sectors);

  var planetsRef = database.ref('/planets/$starId');
  if (planetsRef == null) {
    planetsRef = database.ref('planets').push(starId);
    await planetsRef.set({});
  }
  var planetsJson = (await planetsRef.once('value')).snapshot.toJson() as Map;
  if (planetsJson != null) {
    var planets = planetsJson.values.map((planetJson) =>
        new Planet.fromJson((planetJson as Map).cast<String, dynamic>()));
    star.planets.addAll(planets);
  }

  var jumpGatesRef = database.ref('/jump_gates/$starId');
  if (jumpGatesRef == null) {
    jumpGatesRef = database.ref('jump_gates').push(starId);
    await jumpGatesRef.set({});
  }
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
  _drawStar(star, canvas, gameCtx);

  var lockStarBox =
      document.body.querySelector('#lock_star') as CheckboxInputElement;
  if (star.isLocked) {
    lockStarBox.checked = true;
  }
  lockStarBox.onChange.listen((e) {
    if (star.isLocked == lockStarBox.checked) return;
    star.isLocked = lockStarBox.checked;
    _updateStar(star, database);
  });
  starRef.child('isLocked').onValue.listen((e) {
    var locked = e.snapshot.toJson() as bool;
    if (star.isLocked == locked) return;
    star.isLocked = locked;
    lockStarBox.checked = locked;
  });

  var newPlanetButton = document.body.querySelector('#add_planet');
  newPlanetButton.onClick.listen((_) {
    if (star.isLocked) return;
    var planet = new Planet(x: Sector.WIDTH / 2, y: Sector.HEIGHT / 2);
    var ref = planetsRef.child(star.planets.length.toString());
    ref.set(planet.toJson());
  });

  var newJumpGateButton =
      document.body.querySelector('#add_jg') as ButtonElement;
  var newJumpGateSectorInput =
      document.body.querySelector('#jg_sector') as InputElement;
  newJumpGateButton.onClick.listen((_) {
    if (star.isLocked) return;
    var sectorName = newJumpGateSectorInput.value;
    var sector = star.sectors
        .firstWhere((s) => s.name == sectorName.toLowerCase(), orElse: () {
      window.alert('Unable to find a sector by the name "$sectorName');
      return null;
    });
    if (sector == null) return;

    var jG = new JumpGate(
        x: sector.x - JumpGate.SIZE / 2, y: sector.y - JumpGate.SIZE / 2);
    var ref = jumpGatesRef.child(star.jumpGates.length.toString());
    ref.set(jG.toJson());
  });

  canvas.onMouseDown.listen((e) {
    e.preventDefault();
    var x = e.client.x;
    var y = e.client.y;
    if (!e.ctrlKey) {
      for (var planet in selected) {
        planet.deselect();
      }
      selected.clear();
    }
    for (var planet in star.planets) {
      if (rectCollide(x, y, planet, gameCtx.scale)) {
        selected.add(planet);
        planet.select();
        if (!star.isLocked) {
          planet.startDrag(e, canvas, gameCtx).listen((_) {
            _drawStar(star, canvas, gameCtx);
            _updatePlanet(planet, database, gameCtx);
          }).onDone(() {
            _updatePlanet(planet, database, gameCtx);
          });
        }
        break;
      }
    }
    _drawStar(star, canvas, gameCtx);
  });

  document.onMouseDown.listen((e) {
    if (e.target != canvas) {
      for (var planet in selected) {
        planet.deselect();
      }
      selected.clear();
      _drawStar(star, canvas, gameCtx);
    }
  });

  document.onKeyDown.listen((KeyboardEvent e) {
    if (selected.isEmpty) return;
    if (star.isLocked) return;
    e.preventDefault();
    for (var planet in selected) {
      var modifier = e.shiftKey ? 10 : 1;
      switch (e.keyCode) {
        case KeyCode.UP:
          planet.y -= 1 * modifier;
          break;
        case KeyCode.RIGHT:
          planet.x += 1 * modifier;
          break;
        case KeyCode.DOWN:
          planet.y += 1 * modifier;
          break;
        case KeyCode.LEFT:
          planet.x -= 1 * modifier;
          break;
        default:
          return;
      }
      _updatePlanet(planet, database, gameCtx);
    }
    _drawStar(star, canvas, gameCtx);
  });

  void _onPlanetUpdate(firebase.QueryEvent event) {
    var position = int.parse(event.snapshot.key);
    if (position >= star.planets.length) star.planets.length = position + 1;
    var existing = star.planets[position];
    var updated = new Planet.fromJson(
        (event.snapshot.toJson() as Map).cast<String, dynamic>());
    if (existing == null) {
      star.planets[position] = updated;
    } else {
      existing
        ..x = updated.x
        ..y = updated.y;
    }
    _drawStar(star, canvas, gameCtx);
  }

  planetsRef.onChildChanged.listen(_onPlanetUpdate);
  planetsRef.onChildAdded.listen(_onPlanetUpdate);

  void _updateJumpGate(firebase.QueryEvent event) {
    var position = int.parse(event.snapshot.key);
    if (position >= star.jumpGates.length) star.jumpGates.length = position + 1;
    star.jumpGates[position] = new JumpGate.fromJson(
        (event.snapshot.toJson() as Map).cast<String, dynamic>());
    _drawStar(star, canvas, gameCtx);
  }

  jumpGatesRef.onChildChanged.listen(_updateJumpGate);
  jumpGatesRef.onChildAdded.listen(_updateJumpGate);
}

void _drawStar(Star star, CanvasElement canvas, GameContext gameCtx) {
  var renderCtx = canvas.context2D;
  renderCtx.setFillColorRgb(0, 0, 0);
  renderCtx.fillRect(0, 0, canvas.width, canvas.height);
  gameCtx.star.draw(renderCtx, gameCtx);
}

bool _updating = false;
final _planetsToUpdate = <Planet>[];

Future _updatePlanet(
    Planet planet, firebase.Database db, GameContext ctx) async {
  if (_updating) {
    if (!_planetsToUpdate.contains(planet)) {
      _planetsToUpdate.add(planet);
    }
    return;
  }
  var savingSpan = document.body.querySelector('#saving');
  savingSpan.text = 'saving...';
  _updating = true;

  var star = ctx.star;
  var index = star.planets.indexOf(planet);
  if (index == -1) {
    print('Unable to find $planet');
    return;
  }
  var planetRef = db.ref('/planets/${star.firebaseId}/$index');
  await planetRef.set(planet.toJson());

  savingSpan.text = 'done!';
  new Future.delayed(new Duration(milliseconds: 250), () {
    savingSpan.text = '';
    _updating = false;
    if (_planetsToUpdate.isNotEmpty) {
      var next = _planetsToUpdate.first;
      _planetsToUpdate.remove(next);
      // ignore: unawaited_futures
      _updatePlanet(next, db, ctx);
    }
  });
}

void _updateStar(Star star, firebase.Database db) {
  var starRef = db.ref('stars').child(star.firebaseId);
  starRef.set(star.toJson());
}
