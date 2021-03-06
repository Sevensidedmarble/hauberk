import 'dart:html' as html;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/engine.dart';
import 'package:hauberk/src/content/tiles.dart';

import 'histogram.dart';

html.CanvasElement canvas;
html.CanvasRenderingContext2D context;

var content = createContent();
var heroClass = new Warrior();
var save = new HeroSave("Hero", heroClass);

int get depth {
  var depthSelect = html.querySelector("#depth") as html.SelectElement;
  return int.parse(depthSelect.value);
}

main() {
  canvas = html.querySelector("canvas") as html.CanvasElement;
  context = canvas.context2D;

  var depthSelect = html.querySelector("#depth") as html.SelectElement;
  for (var i = 1; i <= Option.maxDepth; i++) {
    depthSelect.append(
      new html.OptionElement(data: i.toString(), value: i.toString(),
          selected: i == 1));
  }

  depthSelect.onChange.listen((event) {
    generate();
  });

  canvas.onClick.listen((_) {
    generate();
  });

  generate();
}

void generate() {
  var game = new Game(content, save, depth);

  context.fillStyle = '#000';
  context.fillRect(0, 0, canvas.width, canvas.height);

  var size = 6;
  var stage = game.stage;
  canvas.width = stage.width * size;
  canvas.height = stage.height * size;

  for (var y = 0; y < stage.height; y++) {
    for (var x = 0; x < stage.width; x++) {
      var fill = '#f00';
      var type = stage.get(x, y).type;
      if (type == Tiles.floor) {
        fill = '#000';
      } else if (type == Tiles.grass) {
        fill = 'rgb(0, 40, 0)';
      } else if (type == Tiles.wall) {
        fill = '#aaa';
      } else if (type == Tiles.table) {
        fill = 'rgb(80, 55, 30)';
      } else if (type == Tiles.lowWall) {
        fill = '#666';
      } else if (type == Tiles.openDoor) {
        fill = 'rgb(160, 110, 60)';
      } else if (type == Tiles.closedDoor) {
        fill = 'rgb(160, 110, 60)';
      } else if (type == Tiles.water) {
        fill = 'hsl(220, 100%, 40%)';
      } else if (type == Tiles.tree) {
        fill = 'rgb(0, 100, 0)';
      } else if (type == Tiles.treeAlt1) {
        fill = 'rgb(0, 120, 0)';
      } else if (type == Tiles.treeAlt2) {
        fill = 'rgb(0, 140, 0)';
      }

      context.fillStyle = fill;
      context.fillRect(x * size, y * size, size - 0.25, size - 0.25);

      var hasItem = stage.isItemAt(new Vec(x, y));
      if (hasItem) {
        context.fillStyle = 'rgb(240, 240, 0)';
        context.fillRect(x * size + 2, y * size + 2, size - 4, size - 4);
      }

      var actor = stage.actorAt(new Vec(x, y));
      if (actor != null) {
        if (actor is Hero) {
          context.fillStyle = 'rgb(0, 100, 240)';
        } else {
          context.fillStyle = 'rgb(160, 0, 0)';
        }
        context.fillRect(x * size + 1, y * size + 1, size - 2, size - 2);
      }
    }
  }

  var monsters = new Histogram<Breed>();
  for (var actor in stage.actors) {
    if (actor is Monster) {
      var breed = actor.breed;
      monsters.add(breed);
    }
  }

  var tableContents = new StringBuffer();
  tableContents.write('''
    <thead>
    <tr>
      <td>Count</td>
      <td colspan="2">Breed</td>
      <td>Depth</td>
      <td colspan="2">Health</td>
      <td>Exp.</td>
      <!--<td>Drops</td>-->
    </tr>
    </thead>
    <tbody>
    ''');

  for (var breed in monsters.descending()) {
    var glyph = breed.appearance as Glyph;
    tableContents.write('''
      <tr>
        <td>${monsters.count(breed)}</td>
        <td>
          <pre><span style="color: ${glyph.fore.cssColor}">${new String.fromCharCodes([glyph.char])}</span></pre>
        </td>
        <td>${breed.name}</td>
        <td>${breed.depth}</td>
        <td class="r">${breed.maxHealth}</td>
        <td><span class="bar" style="width: ${breed.maxHealth}px;"></span></td>
        <td class="r">${(breed.experienceCents / 100).toStringAsFixed(2)}</td>
        <td>
      ''');

    var attacks = breed.attacks.map(
        (attack) => '${Log.conjugate(attack.verb, breed.pronoun)} (${attack.damage})');
    tableContents.write(attacks.join(', '));

    tableContents.write('</td><td>');

    for (var flag in breed.flags) {
      tableContents.write('$flag ');
    }

    tableContents.write('</td></tr>');
  }
  tableContents.write('</tbody>');

  var validator = new html.NodeValidatorBuilder.common();
  validator.allowInlineStyles();

  html.querySelector('table[id=monsters]').setInnerHtml(tableContents.toString(),
      validator: validator);

  tableContents.clear();
  tableContents.write('''
    <thead>
    <tr>
      <td colspan="2">Item</td>
      <td>Depth</td>
      <td>Tags</td>
      <td>Equip.</td>
      <td>Attack</td>
      <td>Armor</td>
    </tr>
    </thead>
    <tbody>
    ''');

  var items = new Histogram<String>();
  for (var item in stage.allItems) {
    items.add(item.toString());
  }

  tableContents.clear();
  tableContents.write('''
    <thead>
    <tr>
      <td>Count</td>
      <td width="300px">Item</td>
    </tr>
    </thead>
    <tbody>
    ''');

  for (var item in items.descending()) {
    tableContents.write('''
    <tr>
      <td>${items.count(item)}</td>
      <td>$item</td>
    </tr>
    ''');
  }
  html.querySelector('table[id=items]').setInnerHtml(tableContents.toString(),
      validator: validator);
}