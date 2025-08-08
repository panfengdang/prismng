# PrismNg - 共生认知系统

![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![iOS](https://img.shields.io/badge/iOS-17.0+-blue)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green)
![Status](https://img.shields.io/badge/Status-MVP_Complete-success)

## 🌟 项目简介

PrismNg 是一款革命性的认知增强应用，通过 AI 技术增强而非替代人类思维。它实现了"共生认知"的理念，让 AI 成为思维的伙伴。

## ✨ 核心特性

### 🧠 思维画布
- 无限画布，自由创建和组织想法
- 节点连接可视化思维关系
- 支持多种节点类型（思想、问题、洞察等）

### 🎯 认知档位系统
- **Capture（速记）**：快速捕获想法
- **Muse（缪斯）**：创意孵化模式
- **Inquiry（审问）**：深度分析模式
- **Synthesis（综合）**：整合连接模式
- **Reflection（反思）**：回顾沉思模式

### 🌊 漂流模式（独创）
- 节点自动漂移，发现潜在关联
- 共鸣瞬现：相似想法自动高亮连接
- 将偶然发现转化为系统化过程

### 💭 情感计算
- 识别和追踪思维的情感维度
- 情感热力图可视化
- 情感趋势分析和洞察

### 🤖 AI 智能功能
- 智能联想：发现节点间的潜在关联
- 结构分析：理解思维网络的逻辑结构
- 主题提取：自动识别核心主题
- AI 洞察：生成深度思考建议

### 🎨 专业 UI/UX
- Miro 风格的现代设计
- 流畅的动画和过渡效果
- 双轨交互：同时支持新手和专家
- 渐进式功能展示

## 🚀 快速开始

### 环境要求
- macOS 14.0+
- Xcode 15.0+
- iOS 17.0+ 模拟器或设备

### 构建运行

#### 方法 1：使用脚本（推荐）
```bash
./run.sh
```

#### 方法 2：使用 Xcode
1. 打开项目
```bash
open prismNg.xcodeproj
```

2. 选择 iPhone 16 Pro 模拟器

3. 按 Command + R 运行

## 📱 功能测试指南

### 基础操作
- **创建节点**：双击画布空白处
- **编辑节点**：双击节点内容
- **移动节点**：拖拽节点
- **删除节点**：选中后点击删除按钮
- **缩放画布**：双指捏合手势
- **平移画布**：拖拽背景

### 高级功能
1. **创建连接**
   - 点击"连接模式"
   - 依次点击两个节点

2. **AI 分析**
   - 点击"AI 助手"
   - 选择分析类型

3. **漂流模式**
   - 切换到 Muse 档位
   - 观察节点自动漂移
   - 注意金色共鸣线

4. **情感分析**
   - AI 面板中选择"情感分析"
   - 查看节点的情感标记

## 🏗 技术架构

- **UI 框架**: SwiftUI 5.0
- **数据持久化**: SwiftData
- **动画引擎**: SpriteKit
- **AI/ML**: Core ML, Natural Language
- **并发**: Swift Concurrency
- **最低部署**: iOS 17.0

## 📂 项目结构

```
prismNg/
├── prismNg/                    # 主应用目录
│   ├── prismNgApp.swift       # 应用入口
│   ├── ContentView.swift      # 主界面
│   ├── Services/              # 服务层
│   │   ├── AIService.swift    # AI 服务
│   │   ├── DriftModeEngine.swift # 漂流模式引擎
│   │   ├── EmotionalComputingEngine.swift # 情感计算
│   │   └── StructuralAnalysisService.swift # 结构分析
│   ├── Views/                 # 视图层
│   │   ├── Canvas/           # 画布相关视图
│   │   │   ├── ModernCanvasView.swift # 主画布
│   │   │   └── SimpleCanvasView.swift # 简化画布
│   │   └── ...
│   └── Models/               # 数据模型
├── design/                   # 设计文档
└── docs/                    # 文档

```

## 🎯 开发状态

### ✅ 已完成（MVP）
- [x] 核心画布功能
- [x] 认知档位系统
- [x] 漂流模式
- [x] 情感计算
- [x] AI 基础功能
- [x] 专业 UI 设计
- [x] 数据持久化
- [x] 双轨交互系统
- [x] 记忆管理系统
- [x] 语义搜索

### 🚧 待开发（MVP2）
- [ ] Firebase 云同步
- [ ] 多用户协作
- [ ] 订阅系统
- [ ] 更多 AI 模型
- [ ] 数据导入导出
- [ ] 深色模式
- [ ] iPad 适配

## 🐛 已知问题

1. 某些情况下节点拖动可能不够流畅
2. 大量节点时性能需要优化
3. 部分动画在低性能设备上可能卡顿

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可

Copyright © 2025 PrismNg Team. All rights reserved.

## 🙏 致谢

- 设计灵感来源于 Miro、Notion、Obsidian
- 使用了 Apple 的 SwiftUI 和 Core ML 框架
- 特别感谢所有测试用户的反馈

## 📞 联系

- 项目主页：[GitHub](https://github.com/your-username/prismNg)
- 问题反馈：[Issues](https://github.com/your-username/prismNg/issues)

---

**"从思维的播种到智慧的收获，PrismNg 陪伴每一个思考的瞬间。"** ✨