import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//import 'package:flutter/gestures.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

String _activeDropdownValue = 'Cube';
List<String> _possibleDropdownValues = [
  'Cube',
  'Cylinder',
  'Sphere',
  'Earth',
  'None'
];
bool _showSliders = false;
bool _allowNewObjects = true;
List<vector.Vector3> _positions = [];
List<vector.Vector3> _sizes = [];
List<vector.Vector4> _rotations = [];
List<double> _metallic = [];
List<double> _roughness = [];
List<Color> _colors = [];
List<String> _objectNames = [];
List _objects = [];
int activeObject = 0;

class ObjectsOnTap extends StatefulWidget {
  @override
  _ObjectsOnTap createState() => _ObjectsOnTap();
}

class _ObjectsOnTap extends State<ObjectsOnTap> {
  final GlobalKey<_DropdownWidgetState> _key = GlobalKey();
  ArCoreController arCoreController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('ARCore in flutter'),
          ),
          body: Column(
            children: <Widget>[
              _showSliders
                  ? ObjectControl(
                      changed: childChange,
                      onColorChange: onColorChange,
                      onMetallicChange: onMetallicChange,
                      onRoughnessChange: onRoughnessChange,
                      onSizeChange: onSizeChange,
                      onPositionChange: onPositionChange,
                      deleteObject: deleteObject,
                    )
                  : Container(),
              Expanded(
                child: ArCoreView(
                  onArCoreViewCreated: _onArCoreViewCreated,
                  enableTapRecognizer: true,
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              setState(() {});
            },
            tooltip: 'Place object in AR world',
            backgroundColor: Colors.lightBlueAccent,
            label: DropdownWidget(
              key: _key,
              changed: childChange, //Icon(Icons.add),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat),
    );
  }

  ///region AR CORE STUFF
  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    arCoreController.onNodeTap = (name) => onTapHandler(name);
    if (_allowNewObjects) {
      arCoreController.onPlaneTap = _handleOnPlaneTap;
    }
  }

  Future _addCube(ArCoreHitTestResult plane) async {
    Color color = Colors.accents[Random().nextInt(14)];
    double metallic = 0.0;
    double roughness = 1.0;
    final material = ArCoreMaterial(
      color: color,
      metallic: metallic,
      roughness: roughness,
    );

    vector.Vector3 size = vector.Vector3(0.4, 0.4, 0.4);
    final cube = ArCoreCube(
      materials: [material],
      size: size,
    );

    vector.Vector3 position = vector.Vector3(0, (size.y / 2) - (size.y / 3), 0);
    vector.Vector3 finalPosition = plane.pose.translation + position;
    final node = ArCoreNode(
      shape: cube,
      position: finalPosition,
      rotation: plane.pose.rotation,
      scale: vector.Vector3(2, 2, 2),
    );

    setState(() {
      _objects.add(node);
      _objectNames.add(node.name);
      _colors.add(color);
      _metallic.add(metallic);
      _roughness.add(roughness);
      _sizes.add(size);
      _positions.add(finalPosition);
    });
    arCoreController.addArCoreNodeWithAnchor(node);
  }

  Future _addCylinder(ArCoreHitTestResult plane) async {
    Color color = Colors.accents[Random().nextInt(14)];
    double metallic = 0.0;
    double roughness = 1.0;
    final material = ArCoreMaterial(
      color: color,
      metallic: metallic,
      roughness: roughness,
    );

    vector.Vector3 size = vector.Vector3(0.35, 0.175, 0.35);
    final cylinder = ArCoreCylinder(
      materials: [material],
      radius: size.x,
      height: size.y,
    );

    vector.Vector3 position = vector.Vector3(0, size.y / 2, 0);
    vector.Vector3 finalPosition = plane.pose.translation + position;
    final node = ArCoreNode(
        shape: cylinder,
        position: finalPosition,
        rotation: plane.pose.rotation);

    setState(() {
      _objects.add(node);
      _objectNames.add(node.name);
      _colors.add(color);
      _metallic.add(metallic);
      _roughness.add(roughness);
      _sizes.add(size);
      _positions.add(finalPosition);
    });
    arCoreController.addArCoreNodeWithAnchor(node);
  }

  Future _addSphere(ArCoreHitTestResult plane) async {
    Color color = Colors.accents[Random().nextInt(14)];
    double metallic = 0.0;
    double roughness = 1.0;

    final material = ArCoreMaterial(
      color: color,
      metallic: metallic,
      roughness: roughness,
    );

    vector.Vector3 size = vector.Vector3(0.20, 0.20, 0.20);
    final shape = ArCoreSphere(
      materials: [material],
      radius: size.x,
    );

    vector.Vector3 position = vector.Vector3(0, size.x / 2, 0);
    vector.Vector3 finalPosition = plane.pose.translation + position;
    final node = ArCoreNode(
      shape: shape,
      position: finalPosition,
      rotation: plane.pose.rotation,
    );

    setState(() {
      _objects.add(node);
      _objectNames.add(node.name);
      _colors.add(color);
      _metallic.add(metallic);
      _roughness.add(roughness);
      _sizes.add(size);
      _positions.add(finalPosition);
    });
    arCoreController.addArCoreNodeWithAnchor(node);
  }

  Future _addEarth(ArCoreHitTestResult plane) async {
    Color color = Colors.accents[Random().nextInt(14)];
    double metallic = 0.0;
    double roughness = 1.0;

    final ByteData textureBytes = await rootBundle.load('assets/earth.jpg');

    final earthMaterial = ArCoreMaterial(
        color: Color.fromARGB(120, 66, 134, 244),
        textureBytes: textureBytes.buffer.asUint8List());

    vector.Vector3 size = vector.Vector3(0.15, 0.15, 0.15);
    final earthShape = ArCoreSphere(
      materials: [earthMaterial],
      radius: size.x,
    );

    vector.Vector3 position = vector.Vector3(0, size.x / 2, 0);
    vector.Vector3 finalPosition = plane.pose.translation + position;
    final node = ArCoreNode(
        shape: earthShape,
        position: finalPosition,
        rotation: plane.pose.rotation);

    setState(() {
      _objects.add(node);
      _objectNames.add(node.name);
      _colors.add(color);
      _metallic.add(metallic);
      _roughness.add(roughness);
      _sizes.add(size);
      _positions.add(finalPosition);
    });
    arCoreController.addArCoreNodeWithAnchor(node);
  }

  void _handleOnPlaneTap(List<ArCoreHitTestResult> hits) {
    final hit = hits.first;
    switch (_activeDropdownValue) {
      case 'Cube':
        _addCube(hit);
        break;
      case 'Cylinder':
        _addCylinder(hit);
        break;
      case 'Sphere':
        _addSphere(hit);
        break;
      case 'Earth':
        _addEarth(hit);
        break;
      case 'None':
      default:
        break;
    }

    setState(() {});
  }

  void onTapHandler(String name) {
    setState(() {
      _allowNewObjects = false;
    });

    if (_objectNames.contains(name)) {
      int position = _objectNames.indexOf(name);
//      var object = _objects[position];
      setState(() {
        _showSliders = true;
        activeObject = position;
      });
      childChange();
    } else {
      showDialog<void>(
        context: context,
        builder: (BuildContext context) =>
            AlertDialog(content: Text('Node with name: $name not found.')),
      );
    }

    setState(() {
      _allowNewObjects = true;
    });
  }

  @override
  void dispose() {
    arCoreController.dispose();
    super.dispose();
  }

  ///endregion

  /// region edit object

  onColorChange(Color newColor) {
    if (newColor != _colors[activeObject]) {
      _colors[activeObject] = newColor;
      updateMaterials();
    }
  }

  onMetallicChange(double newMetallic) {
    if (newMetallic != _metallic[activeObject]) {
      _metallic[activeObject] = newMetallic;
      updateMaterials();
    }
  }

  onRoughnessChange(double newRoughness) {
    if (newRoughness != _roughness[activeObject]) {
      _roughness[activeObject] = newRoughness;
      updateMaterials();
    }
  }

  onPositionChange(vector.Vector3 newPosition) {
    if (newPosition != _sizes[activeObject]) {
      _sizes[activeObject] = newPosition;
      updateMaterials();
    }
  }

  onSizeChange(vector.Vector3 newSize) {
    debugPrint("New size: $newSize for object $activeObject");
    if (newSize.x != _sizes[activeObject].x) {
      _sizes[activeObject] = newSize;
      debugPrint("Updating object");
      updateMaterials();
    }
    debugPrint("Not/done updating object");
  }

  deleteObject(int position) {
    String name = _objectNames[position];
    arCoreController.removeNode(nodeName: name);
  }

  updateMaterials() {
    debugPrint("updateMaterials");
    if (_objects[activeObject] == null) {
      return;
    }

    debugPrint("updateMaterials node not null");
    final material = ArCoreMaterial(
      color: _colors[activeObject],
      metallic: _metallic[activeObject],
      roughness: _roughness[activeObject],
    );

    _objects[activeObject].shape.materials.value = [material];
    switch (_activeDropdownValue) {
      case 'Cube':
        _objects[activeObject].shape.size.value = _sizes[activeObject];
        break;
      case 'Cylinder':
        _objects[activeObject].shape.radius = _sizes[activeObject].x;
        _objects[activeObject].shape.height = _sizes[activeObject].y;
        break;
      case 'Sphere':
        _objects[activeObject].shape.radius = _sizes[activeObject].x;
        break;
      case 'None':
      default:
        break;
    }

    _objects[activeObject].scale.value = _sizes[activeObject];
    setState(() {});
  }

  /// endregion

  childChange() => setState(() {});
}

/// region Edit objects

class ObjectControl extends StatefulWidget {
  final Function changed;
  final ValueChanged<Color> onColorChange;
  final ValueChanged<double> onMetallicChange;
  final ValueChanged<double> onRoughnessChange;
  final ValueChanged<vector.Vector3> onPositionChange;
  final ValueChanged<vector.Vector3> onSizeChange;
  final ValueChanged<int> deleteObject;

  const ObjectControl({
    Key key,
    this.changed,
    this.onColorChange,
    this.onMetallicChange,
    this.onRoughnessChange,
    this.onPositionChange,
    this.onSizeChange,
    this.deleteObject,
  }) : super(key: key);

  @override
  _ObjectControlState createState() => _ObjectControlState();
}

class _ObjectControlState extends State<ObjectControl> {
  int _activeObject = activeObject;
  double metallicValue = _metallic[activeObject];
  double roughnessValue;
  Color color;
  vector.Vector3 position;
  vector.Vector3 size;

  @override
  void initState() {
    color = _colors[_activeObject];
//    metallicValue = _metallic[_activeObject];
    roughnessValue = _roughness[_activeObject];
    position = _positions[_activeObject];
    size = _sizes[_activeObject];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Updating object:'
            ' $activeObject',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
            textScaleFactor: 1.5,
          ),
          Row(
            children: <Widget>[
              RaisedButton(
                child: Text("Random Color"),
                onPressed: () {
                  final newColor = Colors.accents[Random().nextInt(14)];
                  setState(() {
                    color = newColor;
                  });
                  widget.onColorChange(newColor);
                },
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: CircleAvatar(
                  radius: 20.0,
                  backgroundColor: _colors[activeObject],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                child: RaisedButton(
                  child: Text("Remove object"),
                  onPressed: () {
                    setState(() {
                      _showSliders = false;
                    });
                    widget.deleteObject(activeObject);
                    widget.changed();
                  },
                ),
              ),
              RaisedButton(
                child: Text("Close"),
                onPressed: () {
                  setState(() {
                    _showSliders = false;
                  });
                  widget.changed();
                },
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Text("Metallic"),
              Checkbox(
                value: metallicValue == 1.0,
                onChanged: (value) {
                  metallicValue = value ? 1.0 : 0.0;
                  widget.onMetallicChange(metallicValue);
                  setState(() {});
                  widget.changed();
                },
              )
            ],
          ),
          Row(
            children: <Widget>[
              Text("Roughness"),
              Expanded(
                child: Slider(
                  value: roughnessValue,
                  divisions: 10,
                  onChangeEnd: (value) {
                    roughnessValue = value;
                    widget.onRoughnessChange(roughnessValue);
                  },
                  onChanged: (double value) {
                    setState(() {
                      roughnessValue = value;
                    });
                  },
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Text("Size"),
              Expanded(
                child: Slider(
                  value: size.x,
//                  divisions: 10,
                  min: 0.1,
                  max: 2,
                  onChangeEnd: (value) {
                    size.x = value;
                    size.y = (_activeDropdownValue == "Cylinder")
                        ? value / 2
                        : value;
                    size.z = value;
                    widget.onSizeChange(size);
                  },
                  onChanged: (double value) {
                    setState(() {
                      size.x = value;
                      size.y = (_activeDropdownValue == "Cylinder")
                          ? value / 2
                          : value;
                      size.z = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// endregion

///region DROPDOWN
class DropdownWidget extends StatefulWidget {
  final Function changed;

  DropdownWidget({Key key, this.changed}) : super(key: key);

  @override
  _DropdownWidgetState createState() => _DropdownWidgetState();
}

class _DropdownWidgetState extends State<DropdownWidget> {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _activeDropdownValue,
      icon: Icon(Icons.arrow_downward, color: Colors.black, size: 20),
      elevation: 1,
      underline: Container(
        height: 0,
      ),
      style: TextStyle(
        color: Colors.white,
      ),
      onChanged: (String newValue) {
        setState(() {
          _activeDropdownValue = newValue;
        });
        widget.changed();
      },
      items:
          _possibleDropdownValues.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: TextStyle(
              color: Colors.black,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// endregion
