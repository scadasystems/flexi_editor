import 'dart:math' as math;

import 'package:flexi_editor/flexi_editor.dart';
import 'package:flutter/material.dart';

void main() => runApp(const DiagramApp());

class DiagramApp extends StatefulWidget {
  const DiagramApp({super.key});

  @override
  DiagramAppState createState() => DiagramAppState();
}

class DiagramAppState extends State<DiagramApp> {
  MyPolicySet myPolicySet = MyPolicySet();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              const ColoredBox(color: Colors.grey),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FlexiEditor(
                  flexiEditorContext: FlexiEditorContext(policySet: myPolicySet),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => myPolicySet.deleteAllComponents(),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('delete all'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => myPolicySet.serialize(),
                      child: const Text('serialize'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => myPolicySet.deserialize(),
                      child: const Text('deserialize'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom component Data which you can assign to a component to dynamic data property.
class MyComponentData {
  MyComponentData();

  bool isHighlightVisible = false;
  Color color = Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);

  void showHighlight() {
    isHighlightVisible = true;
  }

  void hideHighlight() {
    isHighlightVisible = false;
  }

  // Function used to deserialize the diagram. Must be passed to `canvasWriter.model.deserializeDiagram` for proper deserialization.
  MyComponentData.fromJson(Map<String, dynamic> json)
      : isHighlightVisible = json['highlight'],
        color = Color(int.parse(json['color'], radix: 16));

  // Function used to serialization of the diagram. E.g. to save to a file.
  Map<String, dynamic> toJson() => {
        'highlight': isHighlightVisible,
        'color': color.toString().split('(0x')[1].split(')')[0],
      };
}

// A set of policies compound of mixins. There are some custom policy implementations and some policies defined by diagram_editor library.
class MyPolicySet extends PolicySet
    with
        MyInitPolicy,
        MyComponentDesignPolicy,
        MyCanvasPolicy,
        MyComponentPolicy,
        CustomPolicy,
        //
        CanvasControlPolicy,
        LinkControlPolicy,
        LinkJointControlPolicy,
        LinkAttachmentRectPolicy {}

// A place where you can init the canvas or your diagram (eg. load an existing diagram).
mixin MyInitPolicy implements InitPolicy {
  @override
  void initializeDiagramEditor() {
    canvasWriter.state.setCanvasColor(Colors.grey[300]!);
  }
}

// This is the place where you can design a component.
// Use switch on componentData.type or componentData.data to define different component designs.
mixin MyComponentDesignPolicy implements ComponentDesignPolicy {
  @override
  Widget showComponentBody(ComponentData componentData) {
    return Container(
      decoration: BoxDecoration(
        color: (componentData.data as MyComponentData).color,
        border: Border.all(
          width: 2,
          color: (componentData.data as MyComponentData).isHighlightVisible ? Colors.pink : Colors.black,
        ),
      ),
      child: const Center(child: Text('component')),
    );
  }
}

// You can override the behavior of any gesture on canvas here.
// Note that it also implements CustomPolicy where own variables and functions can be defined and used here.
mixin MyCanvasPolicy implements CanvasPolicy, CustomPolicy {
  @override
  void onCanvasTapUp(TapUpDetails details) {
    canvasWriter.model.hideAllLinkJoints();
    if (selectedComponentId != null) {
      hideComponentHighlight(selectedComponentId);
    } else {
      canvasWriter.model.addComponent(
        ComponentData(
          size: const Size(96, 72),
          position: canvasReader.state.fromCanvasCoordinates(details.localPosition),
          data: MyComponentData(),
        ),
      );
    }
  }
}

// Mixin where component behaviour is defined. In this example it is the movement, highlight and connecting two components.
mixin MyComponentPolicy implements ComponentPolicy, CustomPolicy {
  // variable used to calculate delta offset to move the component.
  late Offset lastFocalPoint;

  @override
  void onComponentTap(String componentId) {
    canvasWriter.model.hideAllLinkJoints();

    bool connected = connectComponents(selectedComponentId, componentId);
    hideComponentHighlight(selectedComponentId);
    if (!connected) {
      highlightComponent(componentId);
    }
  }

  @override
  void onComponentLongPress(String componentId) {
    hideComponentHighlight(selectedComponentId);
    canvasWriter.model.hideAllLinkJoints();
    canvasWriter.model.removeComponent(componentId);
  }

  @override
  void onComponentScaleStart(componentId, details) {
    lastFocalPoint = details.localFocalPoint;
  }

  @override
  void onComponentScaleUpdate(componentId, details) {
    Offset positionDelta = details.localFocalPoint - lastFocalPoint;

    canvasWriter.model.moveComponent(componentId, positionDelta);
    lastFocalPoint = details.localFocalPoint;
  }

  // This function tests if it's possible to connect the components and if yes, connects them
  bool connectComponents(String? sourceComponentId, String? targetComponentId) {
    if (sourceComponentId == null || targetComponentId == null) {
      return false;
    }
    // tests if the ids are not same (the same component)
    if (sourceComponentId == targetComponentId) {
      return false;
    }
    // tests if the connection between two components already exists (one way)
    if (canvasReader.model.getComponent(sourceComponentId).connections.any(
          (connection) => (connection is ConnectionOut) && (connection.otherComponentId == targetComponentId),
        )) {
      return false;
    }

    // This connects two components (creates a link between), you can define the design of the link with LinkStyle.
    canvasWriter.model.connectTwoComponents(
      sourceComponentId: sourceComponentId,
      targetComponentId: targetComponentId,
      linkStyle: LinkStyle(
        arrowType: ArrowType.pointedArrow,
        lineWidth: 1.5,
        backArrowType: ArrowType.centerCircle,
      ),
    );

    return true;
  }
}

// You can create your own Policy to define own variables and functions with canvasReader and canvasWriter.
mixin CustomPolicy implements PolicySet {
  String? selectedComponentId;
  String serializedDiagram = '{"components": [], "links": []}';

  void highlightComponent(String componentId) {
    canvasReader.model.getComponent(componentId).data.showHighlight();
    canvasReader.model.getComponent(componentId).updateComponent();
    selectedComponentId = componentId;
  }

  void hideComponentHighlight(String? componentId) {
    if (componentId != null) {
      canvasReader.model.getComponent(componentId).data.hideHighlight();
      canvasReader.model.getComponent(componentId).updateComponent();
      selectedComponentId = null;
    }
  }

  void deleteAllComponents() {
    selectedComponentId = null;
    canvasWriter.model.removeAllComponents();
  }

  // Save the diagram to String in json format.
  void serialize() {
    serializedDiagram = canvasReader.model.serializeFlexi();
  }

  // Load the diagram from json format. Do it cautiously, to prevent unstable state remove the previous diagram (id collision can happen).
  void deserialize() {
    canvasWriter.model.removeAllComponents();
    canvasWriter.model.deserializeFlexi(
      serializedDiagram,
      decodeCustomComponentData: MyComponentData.fromJson,
      decodeCustomLinkData: null,
    );
  }
}
