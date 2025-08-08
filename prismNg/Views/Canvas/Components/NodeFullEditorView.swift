//
//  NodeFullEditorView.swift
//  prismNg
//
//  Full-featured node editor with all options
//

import SwiftUI
import SwiftData

struct NodeFullEditorView: View {
    let node: ThoughtNode
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var content: String = ""
    @State private var nodeType: NodeType = .thought
    @State private var emotionalTags: Set<EmotionalTag> = []
    @State private var showingVoiceInput = false
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    var body: some View {
        NavigationView {
            Form {
                // Content Section
                Section("内容") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextEditor(text: $content)
                            .frame(minHeight: 150)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        
                        HStack {
                            Button(action: { showingVoiceInput = true }) {
                                Label("语音输入", systemImage: "mic.fill")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                            
                            Text("\(content.count) 字符")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Node Type Section
                Section("节点类型") {
                    Picker("类型", selection: $nodeType) {
                        ForEach(NodeType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Emotional Tags Section
                Section("情感标签") {
                    FlowLayout(spacing: 8) {
                        ForEach(EmotionalTag.allCases, id: \.self) { tag in
                            EmotionalTagButton(
                                tag: tag,
                                isSelected: emotionalTags.contains(tag),
                                action: {
                                    if emotionalTags.contains(tag) {
                                        emotionalTags.remove(tag)
                                    } else {
                                        emotionalTags.insert(tag)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Metadata Section
                Section("元数据") {
                    HStack {
                        Label("创建时间", systemImage: "clock")
                        Spacer()
                        Text(node.createdAt.formatted())
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("最后修改", systemImage: "clock.arrow.circlepath")
                        Spacer()
                        Text(node.updatedAt.formatted())
                            .foregroundColor(.secondary)
                    }
                    
                    if node.isAIGenerated {
                        HStack {
                            Label("AI 生成", systemImage: "sparkles")
                                .foregroundColor(.purple)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.purple)
                        }
                    }
                }
                
                // Actions Section
                Section {
                    Button(action: duplicateNode) {
                        Label("复制节点", systemImage: "doc.on.doc")
                    }
                    
                    Button(action: deleteNode) {
                        Label("删除节点", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("编辑节点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            content = node.content
            nodeType = node.nodeType
            emotionalTags = Set(node.emotionalTags)
        }
        .sheet(isPresented: $showingVoiceInput) {
            VoiceInputSheet(
                recognizer: speechRecognizer,
                onComplete: { text in
                    content += "\n" + text
                    showingVoiceInput = false
                }
            )
        }
    }
    
    private func saveChanges() {
        node.content = content
        node.nodeType = nodeType
        node.emotionalTags = Array(emotionalTags)
        node.updatedAt = Date()
        try? modelContext.save()
    }
    
    private func duplicateNode() {
        let newNode = ThoughtNode(
            content: content,
            nodeType: nodeType,
            position: Position(
                x: node.position.x + 50,
                y: node.position.y + 50
            )
        )
        newNode.emotionalTags = Array(emotionalTags)
        modelContext.insert(newNode)
        try? modelContext.save()
        dismiss()
    }
    
    private func deleteNode() {
        modelContext.delete(node)
        try? modelContext.save()
        dismiss()
    }
}


