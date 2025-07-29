# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FlexiEditor is a Flutter plugin that provides a flexible visual editor for creating interactive diagrams, flowcharts, and node-based interfaces. It's currently in early development (v0.0.1) by Scada Systems.

## Development Commands

Do not use print(), use debugPrint() instead.

```bash
# Get dependencies
flutter pub get

# Run static analysis
flutter analyze

# Format code
dart format .

# Build the plugin
flutter build
```

Note: There are currently no test files or test scripts configured in this project.

## Core Architecture

### Policy-Based Architecture
The plugin uses a sophisticated policy-based architecture that allows extensible behavior through mixins:

- **FlexiEditorContext**: Central orchestrator that manages canvas model, state, and events
- **PolicySet**: Aggregates behavior policies using mixins (BasePolicySet provides foundation)
- **Data Models**: ComponentData<T>, LinkData<T>, FlexiData with generic custom data support

### Key Directory Structure
- `lib/src/abstraction_layer/`: Policy system and base abstractions
- `lib/src/canvas_context/`: Core context, data models, and events
- `lib/src/widget/`: Main widgets (FlexiEditor, FlexiEditorCanvas, components)
- `lib/src/utils/`: Utilities, painters, and styling helpers

### Main Entry Points
- **Public API**: `lib/flexi_editor.dart` (exports 35+ classes)
- **Primary Widget**: `FlexiEditor` (requires FlexiEditorContext)
- **Canvas Implementation**: `FlexiEditorCanvas` (handles gestures and rendering)

## Architecture Patterns

### State Management
- Uses Provider pattern for state management
- Reader/Writer pattern for canvas operations through policy abstractions
- Context sharing through multiple constructor patterns

### Data Flow
1. FlexiEditorContext orchestrates model, state, and events
2. PolicySet defines extensible behaviors via mixins
3. Canvas widgets handle gestures and render components/links
4. Data models support JSON serialization for persistence

### Component System
- **ComponentData**: Positioned components with size, connections, custom data
- **LinkData**: Connections between components with styling and waypoints
- **Z-order rendering**: Components rendered based on selection state

## Key Dependencies
- `defer_pointer: ^0.0.2`: Advanced pointer event handling
- `provider: ^6.1.5`: State management
- `uuid: ^4.5.1`: Unique ID generation

## Development Notes
- No existing tests - testing framework needs to be established
- Example directory was recently removed
- Plugin is designed for enterprise-level extensibility
- Supports advanced gesture handling including pan, scale, tap, drag selection
- Keyboard shortcuts supported (space for panning mode)

## Response
- Always answer in Korean