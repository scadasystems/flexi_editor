import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/abstraction_layer/policy/base_policy_set.dart';

class PolicySet extends BasePolicySet
    with
        InitPolicy,
        CanvasPolicy,
        ComponentPolicy,
        ComponentDesignPolicy,
        LinkPolicy,
        LinkJointPolicy,
        LinkAttachmentPolicy,
        LinkWidgetsPolicy,
        CanvasWidgetsPolicy,
        ComponentWidgetsPolicy {}
