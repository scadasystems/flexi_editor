import 'package:example/policy/custom_component_control.dart';
import 'package:flexi_editor/flexi_editor.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flexi Editor Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const EditorPage(),
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late final FlexiEditorContext _flexiEditorContext;

  @override
  void initState() {
    super.initState();
    _flexiEditorContext = FlexiEditorContext(MyPolicySet());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flexi Editor Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box),
            onPressed: _addComponent,
            tooltip: 'Add Component',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearCanvas,
            tooltip: 'Clear Canvas',
          ),
          IconButton(
            icon: const Icon(Icons.group_work),
            onPressed: _groupSelected,
            tooltip: 'Group Selected',
          ),
          IconButton(
            icon: const Icon(Icons.work_off),
            onPressed: _ungroupSelected,
            tooltip: 'Ungroup',
          ),
        ],
      ),
      body: FlexiEditor(
        flexiEditorContext: _flexiEditorContext,
        onSelectionRectStart: () {},
        onSelectionRectUpdate: (selectionRect) {},
        onSelectionRectEnd: () {},
      ),
    );
  }

  void _addComponent() {
    // Add a random component
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _flexiEditorContext.policySet.canvasWriter.model.addComponent(
      Component(
        id: id,
        type: 'custom',
        position: const Offset(600, 300),
        size: const Size(100, 100),
        data: NodeData(label: 'Node $id'),
      ),
    );
  }

  void _clearCanvas() {
    _flexiEditorContext.policySet.canvasWriter.model.removeAllComponents();
  }

  void _groupSelected() {
    final selectedIds = _flexiEditorContext.canvasState.selectedComponentIds;
    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No components selected')));
      return;
    }
    (_flexiEditorContext.policySet as MyPolicySet).groupSelectedComponents(
      selectedIds.toList(),
    );
  }

  void _ungroupSelected() {
    final selectedIds = _flexiEditorContext.canvasState.selectedComponentIds;
    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No group selected')));
      return;
    }

    // 선택된 컴포넌트 중 그룹인 것만 해제
    for (var id in selectedIds) {
      (_flexiEditorContext.policySet as MyPolicySet).ungroupComponent(id);
    }
  }
}

class NodeData {
  final String label;

  NodeData({required this.label});

  Map<String, dynamic> toJson() => {'label': label};

  factory NodeData.fromJson(Map<String, dynamic> json) {
    return NodeData(label: json['label']);
  }
}

// Custom Policy Set
class MyPolicySet extends PolicySet
    with
        CanvasControlPolicy,
        CustomComponentControlPolicy,
        GroupPolicy {
  @override
  Widget buildComponentOverWidget(
    BuildContext context,
    Component componentData,
  ) {
    return const SizedBox.shrink();
  }

  @override
  Widget showComponentBody(Component componentData) {
    if (componentData.type == 'group') {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          border: Border.all(color: Colors.blueAccent, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.all(8.0),
        child: const Text(
          'Group',
          style: TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: canvasReader.state.isComponentSelected(componentData.id)
            ? Colors.yellow.shade100
            : Colors.white,
        border: Border.all(
          color: canvasReader.state.isComponentSelected(componentData.id)
              ? Colors.orange
              : Colors.black,
          width: canvasReader.state.isComponentSelected(componentData.id)
              ? 2
              : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text('${componentData.position}', textAlign: TextAlign.center),
    );
  }
}
