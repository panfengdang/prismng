# PrismNg 项目文件完整清单

此文档记录了项目中所有文件的主要功能，用于防止重复定义和便于项目审查。

**最后更新**: 2025/8/7

## 核心文件 (Core Files)

### prismNgApp.swift
- **功能**: SwiftUI应用程序入口点，配置SwiftData数据持久化容器和全局服务
- **关键定义**: `prismNgApp` (主应用), `sharedModelContainer` (数据容器)

### ContentView.swift  
- **功能**: 应用主视图容器，处理初始化配置、用户引导流程和数据迁移
- **关键定义**: `ContentView`, `OnboardingView`, `OnboardingStep`

### Item.swift
- **功能**: 定义核心数据模型和枚举，实现"共生认知"系统的数据结构
- **关键定义**: 
  - 模型: `ThoughtNode`, `NodeConnection`, `AITask`, `UserConfiguration`, `EmotionalMarker`, `Item`
  - 枚举: `NodeType`, `ConnectionType`, `EmotionalTag`, `InteractionMode`, `AITaskType`, `CognitiveGear`

### MainAppView.swift
- **功能**: 主应用界面容器，实现侧边栏导航、工作空间切换和多种功能视图
- **关键定义**: `MainAppView`, `AppView`, `MemorySeaView`, `InsightsViewDetail`, `CollaborationView`, `StructuralAnalysisViewDetail`

## 服务层 (Services)

### AI相关服务

#### AIService.swift
- **功能**: AI服务核心实现，提供思维节点的智能分析功能
- **关键定义**: `AIService`, `EmbeddingModel`

#### AILensService.swift
- **功能**: AI透镜分析服务，对思维节点进行多种类型的AI分析
- **关键定义**: `AILensService`, `AILensView`, `LensAnalysisView`

#### AICreditsService.swift
- **功能**: AI积分系统管理，处理积分消费、充值、订阅套餐管理
- **关键定义**: `AICreditsService`, `CreditTransaction`, `CreditUsageAnalytics`

#### RealLLMService.swift
- **功能**: 真实LLM API调用服务（OpenAI集成）
- **关键定义**: `RealLLMService`

#### HybridAIService.swift
- **功能**: 混合AI服务，整合本地和云端AI能力
- **关键定义**: `HybridAIService`

#### FirebaseFunctionsAIService.swift
- **功能**: Firebase云函数AI服务集成
- **关键定义**: `FirebaseFunctionsAIService`

### 用户交互服务

#### InteractionPreferenceService.swift
- **功能**: 用户交互偏好检测和自适应推荐系统
- **关键定义**: `InteractionPreferenceService`

#### AdaptiveModeService.swift
- **功能**: 自适应UI模式管理，智能切换UI模式
- **关键定义**: `AdaptiveModeService`, `UIMode`, `AdaptiveModeConfiguration`

#### CognitiveGearService.swift
- **功能**: 认知档位系统，管理五种思维模式
- **关键定义**: `CognitiveGearService`, `GearStatistics`, `GearRecommendation`

### 云同步服务

#### CloudSyncManager.swift
- **功能**: 云同步管理器，支持iCloud和Firebase双重同步
- **关键定义**: `CloudSyncManager`, `CloudProvider`

#### iCloudSyncService.swift
- **功能**: iCloud CloudKit集成服务
- **关键定义**: `iCloudSyncService`
- **注意**: CloudKit容器使用可选类型以防止崩溃

#### FirebaseSyncService.swift
- **功能**: Firebase Firestore同步服务
- **关键定义**: `FirebaseSyncService`

#### FirestoreRealtimeSyncService.swift
- **功能**: Firestore实时同步服务，双向同步管理
- **关键定义**: `FirestoreRealtimeSyncService`, `SyncStatus`

#### EnhancedCloudSyncService.swift
- **功能**: 增强云同步服务，支持增量同步
- **关键定义**: `EnhancedCloudSyncService`

### 数据管理服务

#### VectorDBService.swift
- **功能**: 向量数据库服务，提供向量存储、相似性搜索、聚类分析
- **关键定义**: `VectorDBService`, `VectorEntry`, `IndexType`
- **问题**: 余弦相似度计算存在错误（需修复）

#### MemoryForgettingService.swift
- **功能**: 智能记忆遗忘系统，基于多种策略管理节点生命周期
- **关键定义**: `MemoryForgettingService`, `ForgettingStrategy`, `MemoryScore`

#### PersistenceService.swift
- **功能**: 数据持久化服务，管理本地存储
- **关键定义**: `PersistenceService`

### 情感和认知服务

#### EmotionalComputingService.swift
- **功能**: 情感计算和情绪模式分析系统
- **关键定义**: `EmotionalComputingService`, `EmotionChip`, `EmotionPickerView`

#### EmotionalComputingEngine.swift
- **功能**: 情感计算引擎，深度情感分析
- **关键定义**: `EmotionalComputingEngine`, `EmotionPoint`, `EmotionalTrajectory`

#### CognitiveFlowStateEngine.swift
- **功能**: 认知流状态引擎，检测和维持心流状态
- **关键定义**: `CognitiveFlowStateEngine`, `FlowState`

#### DriftModeEngine.swift
- **功能**: 漂移模式引擎，实现思维节点的物理模拟漂移
- **关键定义**: `DriftModeEngine`, `DriftingNode`, `ResonanceConnection`

#### DriftModeService.swift
- **功能**: 漂移模式服务，管理漂移行为
- **关键定义**: `DriftModeService`

### 搜索和推荐服务

#### AssociationRecommendationService.swift
- **功能**: 智能关联推荐系统，多维度分析节点关联
- **关键定义**: `AssociationRecommendationService`, `AssociationRecommendation`

#### DeepSearchService.swift
- **功能**: 深度搜索服务，语义搜索能力
- **关键定义**: `DeepSearchService`

#### LocalEmbeddingService.swift
- **功能**: 本地文本嵌入生成服务
- **关键定义**: `LocalEmbeddingService`

#### CoreMLEmbeddingService.swift
- **功能**: Core ML嵌入服务，本地机器学习
- **关键定义**: `CoreMLEmbeddingService`

### 认证和用户服务

#### AppleSignInService.swift
- **功能**: Apple Sign-In集成服务
- **关键定义**: `AppleSignInService`, `SignInWithAppleButton`

#### FirebaseManager.swift
- **功能**: Firebase模拟服务（Mock实现）
- **关键定义**: `FirebaseManager`, `User`, `DocumentSnapshot`
- **注意**: 这是完全的mock实现

#### ChinaAuthService.swift
- **功能**: 中国特定认证服务（微信、手机号）
- **关键定义**: `ChinaAuthService`

### 商业化服务

#### QuotaManagementService.swift
- **功能**: AI调用额度管理和订阅层级控制
- **关键定义**: `QuotaManagementService`, `SubscriptionTier`

#### StoreKitService.swift
- **功能**: StoreKit集成，应用内购买管理
- **关键定义**: `StoreKitService`

#### GrowthOptimizationService.swift
- **功能**: 用户增长优化服务，分析用户参与度
- **关键定义**: `GrowthOptimizationService`, `ConversionRecommendation`

### 其他服务

#### StructuralAnalysisService.swift
- **功能**: 结构分析服务，分析思维网络结构
- **关键定义**: `StructuralAnalysisService`

#### CollaborativeSpaceService.swift
- **功能**: 协作空间服务，多用户协作支持
- **关键定义**: `CollaborativeSpaceService`

#### VisualEffectsService.swift
- **功能**: 视觉效果服务，管理动画和特效
- **关键定义**: `VisualEffectsService`

#### SpeechRecognitionService.swift
- **功能**: 语音识别服务，语音转文字
- **关键定义**: `SpeechRecognitionService`

#### AutoSyncTrigger.swift
- **功能**: 自动同步触发器，管理同步时机
- **关键定义**: `AutoSyncTrigger`

## 视图层 (Views)

### Canvas相关视图

#### Canvas/Components/ModernCanvasMainView.swift
- **功能**: Canvas系统的主入口视图（当前活跃版本）
- **关键定义**: `ModernCanvasMainView`, `ModernCanvasState`, `CanvasTool`, `AISuggestion`

#### Canvas/Components/ModernCanvasContent.swift
- **功能**: 画布内容渲染，包括节点和连接线
- **关键定义**: `ModernCanvasContent`, `ModernNodeViewComplete`, `ModernConnectionView`, `SelectionRectangle`

#### Canvas/Components/ModernCanvasOverlays.swift
- **功能**: 画布UI覆盖层（工具栏、小地图、AI面板等）
- **关键定义**: `ModernCanvasOverlays`, `ModernCanvasFullToolbar`, `MinimapView`, `ZoomControlsView`, `AIAssistantPanelView`

#### Canvas/Components/ModernCanvasBackground.swift
- **功能**: 画布网格背景
- **关键定义**: `ModernCanvasBackground`

#### Canvas/Components/NodeFullEditorView.swift
- **功能**: 节点全功能编辑器
- **关键定义**: `NodeFullEditorView`

#### Canvas/Components/VoiceInputComponents.swift
- **功能**: 语音输入相关组件
- **关键定义**: `SpeechRecognizer`, `VoiceInputSheet`

#### Canvas/Components/CognitiveGearSelector.swift
- **功能**: 认知齿轮选择器
- **关键定义**: `CognitiveGearSelector`, `DriftToggleStyle`

#### Canvas/ModernCanvasNodes.swift
- **功能**: Canvas节点组件定义
- **关键定义**: `CanvasNodeView`, `EmotionalIndicator`

#### Canvas/ModernCanvasToolbar.swift
- **功能**: Canvas工具栏组件
- **关键定义**: `ModernCanvasToolbar`, `ToolButton`, `CognitiveGearCompact`

#### Canvas/ModernCanvasViewSimplified.swift
- **功能**: 简化版Canvas视图（备用）
- **关键定义**: `ModernCanvasViewSimplified`

#### CanvasView.swift
- **功能**: 主Canvas视图（使用SpriteKit，旧版本）
- **关键定义**: `CanvasView`, `CanvasOverlayView`, `BottomToolbarView`

#### SimpleCanvasView.swift
- **功能**: 简化的Canvas实现（测试用）
- **关键定义**: `SimpleCanvasView`, `NodeView`, `ConnectionLine`

#### Canvas/AdvancedAnimationSystem.swift
- **功能**: 高级动画系统
- **关键定义**: `AdvancedAnimationSystem`

#### Canvas/InfiniteCanvasScene.swift
- **功能**: SpriteKit无限画布场景
- **关键定义**: `InfiniteCanvasScene`

#### Canvas/ConnectionSprite.swift
- **功能**: SpriteKit连接线精灵
- **关键定义**: `ConnectionSprite`

#### Canvas/EnhancedNodeSprite.swift
- **功能**: SpriteKit增强节点精灵
- **关键定义**: `EnhancedNodeSprite`

#### Canvas/QuotaIndicatorView.swift
- **功能**: 配额指示器视图
- **关键定义**: `QuotaIndicatorView`

### 设置和管理视图

#### SettingsView.swift
- **功能**: 应用主设置界面
- **关键定义**: `SettingsView`, `InteractionModeRow`, `CognitiveGearPicker`, `DataExportView`, `AboutView`
- **注意**: 不包含NavigationView以避免嵌套

#### SubscriptionView.swift
- **功能**: 订阅管理界面，支持StoreKit集成
- **关键定义**: `SubscriptionView`, `StoreKitTierCard`, `TierCard`, `FeatureComparisonRow`

#### MemoryManagementView.swift
- **功能**: 记忆管理系统界面
- **关键定义**: `MemoryManagementView`, `MemoryHealthView`, `NodeScoreListView`, `ForgottenNodesView`
- **问题**: 文件过大（800+行），建议拆分

#### EmotionalInsightsView.swift
- **功能**: 情感洞察分析界面
- **关键定义**: `EmotionalInsightsView`, `EmotionalLandscapeChart`, `EmotionCard`

### 节点编辑视图

#### NodeEditView.swift
- **功能**: 思想节点编辑界面
- **关键定义**: `NodeEditView`, `EmotionalTagButton`, `NodeEditTrigger`

#### NodeContextMenu.swift
- **功能**: 节点上下文菜单
- **关键定义**: `NodeContextMenu`

### 认证视图

#### AuthenticationView.swift
- **功能**: 用户认证界面
- **关键定义**: `AuthenticationView`, `AuthenticationRequiredView`

#### Auth/UnifiedAuthView.swift
- **功能**: 统一认证视图
- **关键定义**: `UnifiedAuthView`

#### Auth/ChinaLoginView.swift
- **功能**: 中国特定登录界面
- **关键定义**: `ChinaLoginView`

### 引导视图

#### DualTrackWelcomeView.swift
- **功能**: 双轨交互欢迎引导界面
- **关键定义**: `DualTrackWelcomeView`, `InteractionDetectionView`, `DetectionCanvasView`

#### FreeTierOnboardingView.swift
- **功能**: 免费版引导流程
- **关键定义**: `FreeTierOnboardingView`, `WelcomePage`, `FreeFeaturesPage`

#### InteractionOnboardingView.swift
- **功能**: 交互方式引导
- **关键定义**: `InteractionOnboardingView`

### 搜索和推荐视图

#### Search/GlobalSearchView.swift
- **功能**: 全局搜索界面
- **关键定义**: `GlobalSearchView`

#### SemanticSearchView.swift
- **功能**: 语义搜索界面
- **关键定义**: `SemanticSearchView`

#### AssociationRecommendationView.swift
- **功能**: 关联推荐界面
- **关键定义**: `AssociationRecommendationView`

#### CognitiveRecommendationView.swift
- **功能**: 认知推荐界面
- **关键定义**: `CognitiveRecommendationView`

### 其他UI组件

#### FlowLayout.swift
- **功能**: 自定义SwiftUI布局，实现流式布局
- **关键定义**: `FlowLayout`

#### VoiceInputView.swift
- **功能**: 语音输入界面
- **关键定义**: `VoiceInputView`

#### RadialMenuView.swift
- **功能**: 径向菜单视图
- **关键定义**: `RadialMenuView`

#### FloatingAssociationPanel.swift
- **功能**: 浮动关联面板
- **关键定义**: `FloatingAssociationPanel`

#### AdaptiveModeToast.swift
- **功能**: 自适应模式提示
- **关键定义**: `AdaptiveModeToast`

#### AIFeatureButton.swift
- **功能**: AI功能按钮
- **关键定义**: `AIFeatureButton`

#### SyncStatusView.swift
- **功能**: 同步状态显示
- **关键定义**: `SyncStatusView`

### 特殊功能视图

#### Memory/ForgettingBoatView.swift
- **功能**: 遗忘之舟界面
- **关键定义**: `ForgettingBoatView`

#### DriftMode/ResonanceInsightsView.swift
- **功能**: 共鸣洞察界面
- **关键定义**: `ResonanceInsightsView`

#### CloudSync/CloudSyncView.swift
- **功能**: 云同步管理界面
- **关键定义**: `CloudSyncView`

#### Credits/AICreditsView.swift
- **功能**: AI积分管理界面
- **关键定义**: `AICreditsView`

#### CognitiveGear/CognitiveGearView.swift
- **功能**: 认知档位界面
- **关键定义**: `CognitiveGearView`

#### Collaboration/CollaborativeSpaceView.swift
- **功能**: 协作空间界面
- **关键定义**: `CollaborativeSpaceView`

#### GestureHandlers/CanvasGestureHandler.swift
- **功能**: 画布手势处理器
- **关键定义**: `CanvasGestureHandler`

#### GestureTutorial/GestureTutorialView.swift
- **功能**: 手势教程界面
- **关键定义**: `GestureTutorialView`

### 测试视图

#### TestView.swift
- **功能**: 测试工具视图
- **关键定义**: `TestView`

#### CognitiveFlowTestView.swift
- **功能**: 认知流测试视图
- **关键定义**: `CognitiveFlowTestView`

## 视图模型 (ViewModels)

#### CanvasViewModel.swift
- **功能**: Canvas视图模型，管理画布状态
- **关键定义**: `CanvasViewModel`

## 扩展 (Extensions)

#### NodeTypeExtensions.swift
- **功能**: NodeType枚举扩展，添加图标和颜色属性
- **关键定义**: NodeType扩展（icon, color属性）

## 工具类 (Utils)

#### AnimationManager.swift
- **功能**: 动画管理工具
- **关键定义**: `AnimationManager`

## 同步模型 (Sync Models)

#### CloudSync/SyncModels.swift
- **功能**: 云同步数据模型
- **关键定义**: 同步相关数据结构

## 重复定义问题汇总

### Canvas相关重复
1. **节点视图重复**:
   - `ModernNodeViewComplete` (ModernCanvasContent.swift)
   - `CanvasNodeView` (ModernCanvasNodes.swift)
   - `NodeView` (SimpleCanvasView.swift)

2. **工具栏重复**:
   - `ModernCanvasFullToolbar` (ModernCanvasOverlays.swift)
   - `ModernCanvasToolbar` (ModernCanvasToolbar.swift)
   - `BottomToolbarView` (CanvasView.swift)

3. **Canvas主视图重复**:
   - `ModernCanvasMainView` - 当前活跃版本
   - `CanvasView` - 旧版本（SpriteKit）
   - `SimpleCanvasView` - 测试版本

### 订阅视图重复
- `StoreKitTierCard` vs `TierCard` (SubscriptionView.swift)

## 需要修复的问题

1. **VectorDBService.swift** - 余弦相似度计算错误（多处）
2. **MemoryManagementView.swift** - 文件过大，需要拆分
3. **FirebaseManager.swift** - 完全是mock实现，生产环境需要替换

## 架构总结

项目采用了清晰的MVVM架构：
- **Models**: 定义在Item.swift中
- **Views**: 组织良好的视图层
- **ViewModels**: 管理视图状态
- **Services**: 业务逻辑和外部集成
- **Utils**: 通用工具类

项目展现了完整的"共生认知"系统实现，包含了AI辅助、情感计算、认知档位、漂移模式等创新功能。