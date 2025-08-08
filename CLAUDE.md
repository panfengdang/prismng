# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⚠️ CRITICAL RULES
1. **THIS DOCUMENT MUST BE UPDATED IMMEDIATELY AFTER ANY CODE CHANGES**
   - Every time you modify, add, or remove any file, update the corresponding section in this document
   - This prevents knowledge drift and repetitive errors  
   - Always review this document before making changes to understand current state

2. **REFER TO PROJECT_FILES.md FOR COMPLETE FILE LISTING**
   - See `/Users/suntiger/Applications/Cursor_project/prismNg/PROJECT_FILES.md` for detailed file documentation
   - That document contains the complete inventory of all project files and their functions
   - Use it to check for duplicate definitions before creating new files

## Project Overview

PrismNg is an iOS SwiftUI application that implements a "Symbiotic Cognition" system - an AI-powered thought partner designed to augment human thinking rather than replace it. The project follows a "local-first" architecture with SwiftData for persistent storage.

## Development Commands

### Building and Testing
- **Build project**: Open `prismNg.xcodeproj` in Xcode and use Cmd+B
- **Run tests**: Use Cmd+U in Xcode or the Test Navigator
- **Run on simulator**: Use Cmd+R in Xcode after selecting a simulator
- **Clean build**: Product → Clean Build Folder (Shift+Cmd+K)
- **Build**: Use iPhone 16 Pro simulator
- **Command line build**: `xcodebuild -project prismNg.xcodeproj -scheme prismNg -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build`

## Project Structure

```
prismNg/
├── prismNg/                           # Main app target
│   ├── Core App Files/
│   │   ├── prismNgApp.swift          # App entry point with SwiftData configuration
│   │   ├── ContentView.swift         # Root view with onboarding logic
│   │   ├── MainAppView.swift         # Main navigation container with custom sidebar
│   │   └── Item.swift                # Core data models and enums
│   │
│   ├── Views/
│   │   ├── Canvas/                   # Canvas-related views
│   │   │   ├── Components/
│   │   │   │   ├── ModernCanvasMainView.swift     # Main modern canvas (ACTIVE)
│   │   │   │   ├── ModernCanvasContent.swift      # Canvas content with full gestures
│   │   │   │   ├── ModernCanvasOverlays.swift     # UI overlays (toolbar, minimap, AI panel)
│   │   │   │   ├── ModernCanvasBackground.swift   # Canvas background grid
│   │   │   │   ├── NodeFullEditorView.swift       # Full node editor with voice input
│   │   │   │   ├── VoiceInputComponents.swift     # Shared voice input components (SpeechRecognizer, VoiceInputSheet)
│   │   │   │   └── CognitiveGearSelector.swift    # Cognitive mode selector
│   │   │   ├── CanvasView.swift                   # Basic canvas implementation
│   │   │   ├── SimpleCanvasView.swift             # Simplified test canvas
│   │   │   ├── ModernCanvasNodes.swift            # Modern canvas node components
│   │   │   ├── ModernCanvasToolbar.swift          # Canvas toolbar
│   │   │   └── ModernCanvasViewSimplified.swift   # Simplified modern canvas
│   │   │
│   │   ├── Auth/
│   │   │   ├── AuthenticationView.swift           # Main auth view
│   │   │   ├── UnifiedAuthView.swift              # Unified auth UI
│   │   │   └── ChinaLoginView.swift               # China-specific login
│   │   │
│   │   ├── Settings & Management/
│   │   │   ├── SettingsView.swift                 # Settings (NO NavigationView in body)
│   │   │   ├── SubscriptionView.swift             # Subscription management
│   │   │   ├── MemoryManagementView.swift         # Memory management
│   │   │   └── EmotionalInsightsView.swift        # Emotional insights
│   │   │
│   │   ├── Onboarding/
│   │   │   ├── DualTrackWelcomeView.swift         # Dual-track welcome
│   │   │   ├── FreeTierOnboardingView.swift       # Free tier onboarding
│   │   │   └── InteractionOnboardingView.swift    # Interaction onboarding
│   │   │
│   │   ├── Components/
│   │   │   ├── NodeEditView.swift                 # Basic node editor (has EmotionalTagButton)
│   │   │   ├── FlowLayout.swift                   # Flow layout (DO NOT DUPLICATE)
│   │   │   ├── RadialMenuView.swift               # Radial menu
│   │   │   └── VoiceInputView.swift               # Voice input UI
│   │   │
│   │   └── Other Views...
│   │
│   ├── Services/
│   │   ├── AI/
│   │   │   ├── AIAgentCore.swift                  # AI agent orchestration
│   │   │   ├── AIService.swift                    # Main AI service
│   │   │   └── EmotionalComputingService.swift    # Emotional analysis
│   │   │
│   │   ├── Cloud & Sync/
│   │   │   ├── CloudSyncManager.swift             # Cloud sync orchestration
│   │   │   ├── iCloudSyncService.swift            # iCloud (optional container)
│   │   │   ├── FirebaseManager.swift              # Firebase authentication
│   │   │   └── FirestoreRealtimeSyncService.swift # Firestore sync
│   │   │
│   │   ├── User/
│   │   │   ├── QuotaManagementService.swift       # AI quota tracking
│   │   │   ├── InteractionPreferenceService.swift # User interaction preferences
│   │   │   ├── MemoryForgettingService.swift      # Memory management
│   │   │   └── AppleSignInService.swift           # Apple Sign In
│   │   │
│   │   └── Canvas/
│   │       ├── CanvasViewModel.swift              # Canvas state management
│   │       └── DriftModeEngine.swift              # Drift mode animation
│   │
│   ├── Extensions/
│   │   └── NodeTypeExtensions.swift               # NodeType color property
│   │
│   └── Assets.xcassets/                           # App icons and color assets
│
├── prismNgTests/                                   # Unit tests (Swift Testing framework)
├── prismNgUITests/                                 # UI tests
└── design/                                         # Design documentation (Chinese)
```

## Critical Type Definitions (DO NOT REDEFINE)

### Core Enums (from Item.swift)
```swift
// Cognitive modes for AI interaction
enum CognitiveGear: String, CaseIterable {
    case capture    // 速记 - Quick capture, AI silent
    case muse       // 缪斯 - Inspiration drift
    case inquiry    // 审问 - Deep analysis
    case synthesis  // 综合 - Synthesis mode
    case reflection // 反思 - Reflection mode
}

// Node types
enum NodeType: String, Codable, CaseIterable {
    case thought
    case question
    case insight
    case conclusion
    case contradiction
    case structure
}

// Connection types
enum ConnectionType: String, Codable, CaseIterable {
    case strongSupport
    case weakAssociation
    case contradiction
    case similarity
    case causality
    case resonance
}

// Emotional tags (ONLY THESE 8 - DO NOT ADD OTHERS)
enum EmotionalTag: String, Codable, CaseIterable {
    case excited = "excited"
    case calm = "calm"
    case confused = "confused"
    case inspired = "inspired"
    case frustrated = "frustrated"
    case curious = "curious"
    case confident = "confident"
    case uncertain = "uncertain"
}

// Interaction modes
enum InteractionMode: String, CaseIterable {
    case traditional // 传统按钮
    case gesture     // 手势控制
    case adaptive    // 智能自适应
}

// Canvas tools (from ModernCanvasMainView.swift)
enum CanvasTool: String, CaseIterable {
    case select = "arrow.up.left"
    case pan = "hand.draw"
    case connect = "link"
    case text = "text.cursor"
    case sticky = "note"
}
```

## Components That Already Exist (DO NOT RECREATE)

### UI Components
- `EmotionalTagButton` - In NodeEditView.swift
- `FlowLayout` - In FlowLayout.swift (Layout protocol implementation)
- `SpeechRecognizer` - In VoiceInputComponents.swift (Mock implementation)
- `VoiceInputSheet` - In VoiceInputComponents.swift (Shared component)
- `TagButton` - Various implementations

### Services
- All services in Services/ directory are singletons or @StateObject
- Do not create duplicate service classes
- Check existing services before adding new functionality

## Recent Fixes (2025/8/7)

### 1. Settings Page Crash (FIXED)
- **Problem**: Settings page showed "prismNg crashed"
- **Solution**: Removed duplicate NavigationView wrapper from SettingsView body
- **Rule**: Never nest NavigationView inside sheets

### 2. CloudKit Initialization Crash (FIXED)
- **Problem**: App crashed with EXC_BREAKPOINT in iCloudSyncService
- **Solution**: Made CloudKit container and database optional
- **Rule**: Always handle CloudKit failures gracefully

### 3. Navigation Not Responding (FIXED)
- **Problem**: NavigationSplitView buttons not working on iOS
- **Solution**: Replaced with custom sidebar overlay using ZStack
- **Files Changed**: MainAppView.swift completely rewritten

### 4. Canvas Features Implementation (FIXED)
- **Problem**: Canvas missing text input, voice input, node interactions
- **Solution**: Enhanced ModernCanvasContent with full gesture support
- **Features Added**:
  - Text input (tap with text tool)
  - Voice input (double-tap)
  - Node editing (double-tap node)
  - Node dragging
  - Canvas panning and zooming
  - Full node editor with emotional tags

## Files Recently Cleaned Up (2025/8/7)

### Removed Files
- [x] `InteractiveCanvasView.swift` - Simplified test version, removed
- [x] `TestPanelView` in ContentView.swift - Test component, removed
- [x] Duplicate SpeechRecognizer and VoiceInputSheet definitions - Consolidated to VoiceInputComponents.swift

## Active Implementation Status

### Canvas System (ModernCanvasMainView)
- ✅ Node creation (text input) - Tap with text tool
- ✅ Node creation (voice input) - Double-tap canvas
- ✅ Node selection - Single tap
- ✅ Node editing - Double-tap node
- ✅ Node dragging - Drag gesture
- ✅ Canvas panning - Pan tool or gesture
- ✅ Canvas zooming - Pinch gesture
- ✅ Connection visualization
- ✅ AI panel with suggestions
- ✅ Minimap view
- ✅ Search overlay
- ✅ Multiple tool modes
- ✅ Emotional tags (8 types only)
- ✅ Cognitive gear modes

### Navigation System
- ✅ Custom sidebar overlay (not NavigationSplitView)
- ✅ Fixed navigation bar at top (60pt height)
- ✅ Sheet presentations for modals
- ✅ Proper environment object propagation

## Development Rules

### ALWAYS
1. Check this document before creating any file
2. Use existing components/services
3. Update this document after changes
4. Test build after major changes
5. Remove test/temporary files after use

### NEVER
1. Create duplicate type definitions
2. Nest NavigationViews
3. Add new EmotionalTag cases (only use the 8 defined)
4. Create files that already exist
5. Use force unwrapping with CloudKit/Firebase

### SwiftData Best Practices
- Use `@Environment(\.modelContext)` in views
- Always use `try? modelContext.save()` after changes
- Use `@Query` for reactive updates
- Wrap UI updates in `withAnimation`

## Next Steps & TODOs

### Immediate Cleanup
1. Remove InteractiveCanvasView.swift
2. Clean up test components
3. Remove duplicate implementations

### Feature Implementation
1. Implement real speech recognition (replace mock)
2. Add node connection creation tool
3. Implement AI-powered suggestions
4. Add export functionality
5. Implement collaboration features
6. Add vector database for semantic search

### Performance Optimization
1. Optimize canvas rendering for large graphs
2. Implement node clustering for zoom levels
3. Add canvas viewport culling
4. Optimize SwiftData queries

## Testing

### Framework
- Uses Swift Testing (NOT XCTest)
- Import: `import Testing`
- Test attribute: `@Test`
- Assertions: `#expect(...)`

### Build Testing
```bash
xcodebuild -project prismNg.xcodeproj -scheme prismNg -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

## Important Notes

### Thread Safety
- Services with @MainActor must be initialized on main thread
- Use lazy properties for expensive initializations
- CloudSyncManager uses lazy initialization pattern

### Asset Management
- Check asset existence before using Color("name")
- Use system colors as fallback
- Current background: Color(UIColor.systemGroupedBackground)

### Memory Management
- Large datasets should use lazy loading
- Canvas nodes should implement viewport culling
- Background tasks for AI processing

---

**Last Updated**: 2025/8/7
**Last Change**: Cleaned up test files, consolidated voice input components, updated complete project structure documentation