import 'dart:html';
// import 'dart:math' as math;

import 'package:hades_simulator/common.dart';
import 'package:hades_simulator/sector.dart';
import 'package:hades_simulator/planet.dart';
import 'package:hades_simulator/star.dart';

main() {
  var star = new Star(4);

  var gameCtx = new GameContext(star: star, scale: 0.25);
  var canvas = document.body.querySelector('#game') as CanvasElement;

  var width = star.width.floor();
  var height = star.height.floor();
  canvas.style
    ..width = '${width}px'
    ..height = '${height}px';
  canvas.width = width;
  canvas.height = height;

  canvas.context2D.scale(gameCtx.scale, gameCtx.scale);
  _drawStar(canvas, gameCtx);

  var newPlanetButton = document.body.querySelector('#add_planet');
  newPlanetButton.onClick.listen((_) {
    var planet = new Planet(x: Sector.WIDTH / 2, y: Sector.HEIGHT / 2);
    star.planets.add(planet);
    _drawStar(canvas, gameCtx);
  });

  canvas.onMouseDown.listen((e) {
    var x = e.client.x;
    var y = e.client.y;
    for (var planet in star.planets) {
      if (_rectCollide(x, y, planet, gameCtx.scale)) {
        planet.startDrag(e, canvas, gameCtx).listen((_) {
          _drawStar(canvas, gameCtx);
        });
        break;
      }
    }
  });
}

void _drawStar(CanvasElement canvas, GameContext gameCtx) {
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
