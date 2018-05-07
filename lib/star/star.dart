import 'dart:async';
import 'dart:html';
import 'dart:math' as math;

import 'package:firebase/firebase.dart' as firebase;
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'asteroid.dart';
import 'common.dart';
import 'jump_gate.dart';
import 'planet.dart';
import 'sector.dart';
import 'waypoint.dart';

part 'star.g.dart';

@JsonSerializable()
class Star extends FirebaseObject with GameObject, _$StarSerializerMixin {
  @override
  final String name;

  @override
  String tableId(String starId) => '/stars';

  @override
  double x = 0.0;

  @override
  double y = 0.0;

  @override
  final double height;

  @override
  final double width;

  @override
  bool isLocked = false;

  @JsonKey(ignore: true)
  final List<Asteroid> asteroids;

  @JsonKey(ignore: true)
  final List<Planet> planets;

  @JsonKey(ignore: true)
  final List<Sector> sectors;

  @JsonKey(ignore: true)
  final List<JumpGate> jumpGates;

  @JsonKey(ignore: true)
  final List<Waypoint> waypoints;

  Iterable<Drawable> get drawables => <Drawable>[]
      .followedBy(sectors)
      .followedBy(asteroids)
      .followedBy(planets)
      .followedBy(jumpGates)
      .followedBy(waypoints);

  Iterable<Selectable> get selectables => <Selectable>[]
      .followedBy(asteroids)
      .followedBy(planets)
      .followedBy(jumpGates)
      .followedBy(waypoints);

  @JsonKey(ignore: true)
  final selected = <Selectable>[];

  Star._(
      {@required this.height,
      @required this.width,
      @required String firebaseId,
      @required this.name})
      : jumpGates = <JumpGate>[],
        asteroids = <Asteroid>[],
        planets = <Planet>[],
        sectors = <Sector>[],
        waypoints = <Waypoint>[],
        isLocked = false,
        super(firebaseId);

  Star(
      {List<JumpGate> jumpGates,
      List<Asteroid> asteroids,
      List<Planet> planets,
      List<Sector> sectors,
      bool isLocked,
      @required this.height,
      @required this.width,
      @required String firebaseId,
      @required this.name})
      : asteroids = asteroids ?? <Asteroid>[],
        planets = planets ?? <Planet>[],
        sectors = sectors ?? <Sector>[],
        waypoints = <Waypoint>[],
        jumpGates = jumpGates ?? <JumpGate>[],
        isLocked = isLocked ?? false,
        super(firebaseId);

  // Create a star with [numLayers] layers of hexes making up the overall hex.
  static Future<Star> createWithLayers(
      int numLayers, String name, firebase.Database db) async {
    var totalHeight = (Sector.HEIGHT * ((numLayers - 1) * 2 + 1));
    var totalWidth = (Sector.WIDTH * ((((numLayers - 1) ~/ 2) * 2) + 1) +
        Sector.WIDTH * 0.5 * (numLayers ~/ 2) * 2);
    if (totalWidth.floor() % 2 == 0) {
      totalWidth += (2 * Sector.WIDTH * .25).floor();
    }

    var starRef = db.ref('stars').push();
    var star = new Star._(
        height: totalHeight,
        width: totalWidth,
        firebaseId: starRef.key,
        name: name);
    // Wait to actually set the star until all the sectors are created.

    const letters = const ['a', 'b', 'c', 'd', 'e', 'f', 'g'];
    var sectorsRef = db.ref('/sectors/${star.firebaseId}');
    for (var q = -numLayers + 1; q < numLayers; q++) {
      for (var r = -numLayers + 1; r < numLayers; r++) {
        if (q + r < -(numLayers - 1)) continue;
        if (q + r > (numLayers - 1)) continue;

        var x = Sector.SIZE * 3 / 2 * q;
        var y = Sector.SIZE * math.sqrt(3) * (r + q / 2);
        var col = q + (numLayers / 2).floor() + 1;
        var row = col < numLayers ? r + col + 1 : r + numLayers;
        var sectorRef = sectorsRef.push();
        var sector = new Sector(
            x: x + star.centerX,
            y: y + star.centerY,
            name: '${letters[col]}$row',
            firebaseId: sectorRef.key);
        star.sectors.add(sector);
        await sector.updateFirebase(db, star.firebaseId);
      }
    }

    // Finally create the star object, its all set up.
    await starRef.set(star.toJson());
    return star;
  }

  factory Star.fromJson(Map<String, dynamic> json) => _$StarFromJson(json);

  @override
  void draw(CanvasRenderingContext2D renderCtx, GameContext gameCtx) {
    for (var drawable in drawables) {
      drawable.draw(renderCtx, gameCtx);
    }
    renderCtx.setStrokeColorRgb(0, 255, 0);
    renderCtx.font = '40px sans-serif';
    renderCtx.setFillColorRgb(255, 255, 255);
    var selectedObjects = selected.toList();
    if (selectedObjects.length == 1) {
      var toObjects = <GameObject>[]..addAll(planets)..addAll(jumpGates);
      for (var object in selectedObjects) {
        toObjects.remove(object);
        _drawDistances(object, toObjects, renderCtx);
      }
    } else if (selectedObjects.length > 1) {
      GameObject a = selectedObjects.removeAt(0);
      GameObject b;
      while (selectedObjects.isNotEmpty) {
        b = selectedObjects.removeAt(0);
        _drawDistance(a, b, renderCtx);
        a = b;
      }
    }
  }

  void _drawDistances(GameObject from, Iterable<GameObject> toObjects,
      CanvasRenderingContext2D renderCtx) {
    for (var to in toObjects) {
      _drawDistance(from, to, renderCtx);
    }
  }

  void _drawDistance(GameObject fromObj, GameObject toObj,
      CanvasRenderingContext2D renderCtx) {
    var from = fromObj is DockingPoint ? fromObj.dockingPoint : fromObj;
    var to = toObj is DockingPoint ? toObj.dockingPoint : toObj;
    var oldWidth = renderCtx.lineWidth;
    renderCtx.lineWidth = 4;
    renderCtx.setLineDash([8, 24]);
    renderCtx.moveTo(from.x, from.y);
    renderCtx.lineTo(to.x, to.y);
    renderCtx.stroke();
    renderCtx.setLineDash([]);
    renderCtx.lineWidth = oldWidth;

    var distance = computeDistance(from, to);
    var xDiff = from.x - to.x;
    var yDiff = from.y - to.y;
    renderCtx.fillText('${distance}au', from.x - xDiff / 2, from.y - yDiff / 2);
    renderCtx.lineWidth = oldWidth;
  }
}
