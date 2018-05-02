import 'dart:async';
import 'dart:html';

import 'package:firebase/firebase.dart' as firebase;

import 'package:hades_simulator/asteroid.dart';
import 'package:hades_simulator/common.dart';
import 'package:hades_simulator/jump_gate.dart';
import 'package:hades_simulator/sector.dart';
import 'package:hades_simulator/planet.dart';
import 'package:hades_simulator/star.dart';
import 'package:json_annotation/json_annotation.dart';

part 'star.g.dart';

@JsonLiteral('firebase.json')
Map<String, String> get firebaseData =>
    _$firebaseDataJsonLiteral.cast<String, String>();

main() async {
  var starId = window.location.search;
  if (starId.isNotEmpty) {
    starId = starId.substring(1);
  } else {
    window.alert('invalid star id!');
    return;
  }

  firebase.initializeApp(
      apiKey: firebaseData['apiKey'],
      authDomain: firebaseData['authDomain'],
      databaseURL: firebaseData['databaseURL'],
      projectId: firebaseData['projectId'],
      storageBucket: firebaseData['storageBucket'],
      messagingSenderId: firebaseData['messagingSenderId']);
  var database = firebase.database();
  var starRef = database.ref('stars').child(starId);
  var starJson = (await starRef.once('value')).snapshot.toJson() as Map;
  var star = new Star.fromJson(starJson.cast<String, dynamic>());

  var sectorsRef = database.ref('/sectors/$starId');
  var sectorsSnapshot = (await sectorsRef.once('value')).snapshot;
  var sectorsJson = (sectorsSnapshot.toJson() as Map).cast<String, dynamic>();
  assert(sectorsJson != null);
  var sectors = <Sector>[];
  sectorsJson.forEach((key, sectorJson) {
    sectors.add(new Sector.fromJson(
        _addFirebaseId((sectorJson as Map).cast<String, dynamic>(), key)));
  });
  star.sectors.addAll(sectors);

  var asteroidsRef = database.ref('/asteroids/$starId');
  var jumpGatesRef = database.ref('/jump_gates/$starId');
  var planetsRef = database.ref('/planets/$starId');

  var gameCtx = new GameContext(
    star: star,
    scale: 0.3, /*db: db*/
  );
  var canvas = document.body.querySelector('#game') as CanvasElement;

  var width = (star.width * gameCtx.scale).ceil();
  var height = (star.height * gameCtx.scale).ceil();
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
    var ref = planetsRef.push();
    var planet = new Planet(
        x: Sector.WIDTH / 2, y: Sector.HEIGHT / 2, firebaseId: ref.key);
    ref.set(planet.toJson());
  });

  var newAsteroidButton = document.body.querySelector('#add_asteroid');
  newAsteroidButton.onClick.listen((_) {
    if (star.isLocked) return;
    var ref = asteroidsRef.push();
    var asteroid = new Asteroid(
        x: Sector.WIDTH, y: Sector.HEIGHT / 2, firebaseId: ref.key);
    ref.set(asteroid.toJson());
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

    var ref = jumpGatesRef.push();
    var jG = new JumpGate(
        x: sector.x - JumpGate.SIZE / 2,
        y: sector.y - JumpGate.SIZE / 2,
        firebaseId: ref.key);
    ref.set(jG.toJson());
  });

  canvas.onMouseDown.listen((e) {
    e.preventDefault();
    var x = e.offset.x;
    var y = e.offset.y;

    if (!e.ctrlKey) {
      for (var object in star.selected) {
        object.deselect();
      }
      star.selected.clear();
    }
    for (var selectable in star.selectables) {
      if (rectCollide(x, y, selectable, gameCtx.scale)) {
        var alreadySelected = star.selected.contains(selectable);
        if (!alreadySelected) {
          star.selected.add(selectable);
          selectable.select();
        }
        void unselect() {
          star.selected.remove(selectable);
          selectable.deselect();
        }

        if (!star.isLocked && selectable is Draggable) {
          var draggable = selectable as Draggable;
          var wasDragged = false;
          draggable.startDrag(e, canvas, gameCtx).listen((_) {
            wasDragged = true;
            _drawStar(star, canvas, gameCtx);
            _updateObject(draggable, database, gameCtx);
          }).onDone(() {
            _updateObject(draggable, database, gameCtx);
            if (alreadySelected && !wasDragged) {
              unselect();
              _drawStar(star, canvas, gameCtx);
            }
          });
        } else if (alreadySelected) {
          unselect();
        }
        break;
      }
    }
    _drawStar(star, canvas, gameCtx);
  });

  document.onMouseDown.listen((e) {
    if (e.target != canvas) {
      for (var object in star.selected) {
        object.deselect();
      }
      star.selected.clear();
      _drawStar(star, canvas, gameCtx);
    }
  });

  document.onKeyDown.listen((KeyboardEvent e) {
    if (star.selected.isEmpty) return;
    if (star.isLocked) return;
    e.preventDefault();
    var last = star.selected.last;
    if (last is Draggable) {
      var modifier = e.shiftKey ? 10 : 1;
      switch (e.keyCode) {
        case KeyCode.UP:
          last.y -= 1 * modifier;
          break;
        case KeyCode.RIGHT:
          last.x += 1 * modifier;
          break;
        case KeyCode.DOWN:
          last.y += 1 * modifier;
          break;
        case KeyCode.LEFT:
          last.x -= 1 * modifier;
          break;
        default:
          return;
      }
      _updateObject(last, database, gameCtx);
    }
    _drawStar(star, canvas, gameCtx);
  });

  void _onAsteroidUpdate(firebase.QueryEvent event) {
    var id = event.snapshot.key;
    var existing = star.asteroids.firstWhere(
        (asteroid) => asteroid.firebaseId == id,
        orElse: () => null);
    var updated = new Asteroid.fromJson(_addFirebaseId(
        (event.snapshot.toJson() as Map).cast<String, dynamic>(), id));
    if (existing == null) {
      star.asteroids.add(updated);
    } else {
      existing
        ..x = updated.x
        ..y = updated.y;
    }
    _drawStar(star, canvas, gameCtx);
  }

  asteroidsRef.onChildChanged.listen(_onAsteroidUpdate);
  asteroidsRef.onChildAdded.listen(_onAsteroidUpdate);

  void _onPlanetUpdate(firebase.QueryEvent event) {
    var id = event.snapshot.key;
    var existing =
        star.planets.firstWhere((p) => p.firebaseId == id, orElse: () => null);
    var updated = new Planet.fromJson(_addFirebaseId(
        (event.snapshot.toJson() as Map).cast<String, dynamic>(), id));
    if (existing == null) {
      star.planets.add(updated);
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
    var id = event.snapshot.key;
    var existing = star.jumpGates
        .firstWhere((j) => j.firebaseId == id, orElse: () => null);
    var updated = new JumpGate.fromJson(_addFirebaseId(
        (event.snapshot.toJson() as Map).cast<String, dynamic>(), id));
    if (existing == null) {
      star.jumpGates.add(updated);
    } else {
      existing
        ..x = updated.x
        ..y = updated.y;
    }
    _drawStar(star, canvas, gameCtx);
  }

  jumpGatesRef.onChildChanged.listen(_updateJumpGate);
  jumpGatesRef.onChildAdded.listen(_updateJumpGate);
}

Map<String, dynamic> _addFirebaseId(Map<String, dynamic> json, String id) {
  if (json.containsKey('firebaseId')) return json;
  json['firebaseId'] = id;
  return json;
}

void _drawStar(Star star, CanvasElement canvas, GameContext gameCtx) {
  var renderCtx = canvas.context2D;
  renderCtx.setFillColorRgb(0, 0, 0);
  renderCtx.fillRect(
      0, 0, canvas.width / gameCtx.scale, canvas.height / gameCtx.scale);
  gameCtx.star.draw(renderCtx, gameCtx);
}

bool _updating = false;
final _objectsToUpdate = <GameObject>[];

Future _updateObject(
    GameObject object, firebase.Database db, GameContext ctx) async {
  if (_updating) {
    if (!_objectsToUpdate.contains(object)) {
      _objectsToUpdate.add(object);
    }
    return;
  }
  var savingSpan = document.body.querySelector('#saving');
  savingSpan.text = 'saving...';
  _updating = true;

  var star = ctx.star;
  if (object is Planet) {
    await _updatePlanet(object, star, db);
  } else if (object is Asteroid) {
    await _updateAsteroid(object, star, db);
  } else {
    throw new UnsupportedError('Tried to update $object but didn\'t know how');
  }

  savingSpan.text = 'done!';
  await new Future.delayed(new Duration(milliseconds: 250));

  savingSpan.text = '';
  _updating = false;
  if (_objectsToUpdate.isNotEmpty) {
    var next = _objectsToUpdate.first;
    _objectsToUpdate.remove(next);
    // ignore: unawaited_futures
    _updateObject(next, db, ctx);
  }
}

Future _updateAsteroid(Asteroid asteroid, Star star, firebase.Database db) {
  var asteroidRef =
      db.ref('/asteroids/${star.firebaseId}/${asteroid.firebaseId}');
  return asteroidRef.set(asteroid.toJson());
}

Future _updatePlanet(Planet planet, Star star, firebase.Database db) {
  var planetRef = db.ref('/planets/${star.firebaseId}/${planet.firebaseId}');
  return planetRef.set(planet.toJson());
}

Future _updateStar(Star star, firebase.Database db) {
  var starRef = db.ref('stars').child(star.firebaseId);
  return starRef.set(star.toJson());
}
