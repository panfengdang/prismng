//
//  DriftModeEngine.swift
//  prismNg
//
//  Drift mode engine for serendipitous discovery
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Drift Mode Types

struct DriftConfiguration {
    var isEnabled: Bool = false
    var driftSpeed: Double = 1.0 // 0.5 to 2.0
    var resonanceThreshold: Double = 0.6 // Similarity threshold for resonance
    var maxDriftDistance: Double = 50.0
    var brownianIntensity: Double = 0.5
    var attractionStrength: Double = 0.3
    var repulsionStrength: Double = 0.2
}

struct DriftResonanceEvent {
    let id = UUID()
    let timestamp = Date()
    let node1: ThoughtNode
    let node2: ThoughtNode
    let similarity: Double
    let insight: String?
    let duration: TimeInterval = 3.0 // How long the resonance visual lasts
}

struct DriftVector {
    var dx: Double
    var dy: Double
    
    mutating func apply(brownian: Double) {
        // Add Brownian motion
        dx += Double.random(in: -brownian...brownian)
        dy += Double.random(in: -brownian...brownian)
        
        // Apply friction
        dx *= 0.98
        dy *= 0.98
    }
    
    mutating func limit(to maxSpeed: Double) {
        let magnitude = sqrt(dx * dx + dy * dy)
        if magnitude > maxSpeed {
            dx = (dx / magnitude) * maxSpeed
            dy = (dy / magnitude) * maxSpeed
        }
    }
}

// MARK: - Drift Mode Engine

@MainActor
class DriftModeEngine: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var configuration = DriftConfiguration()
    @Published var activeResonances: [DriftResonanceEvent] = []
    @Published var discoveredAssociations: [(ThoughtNode, ThoughtNode, String)] = []
    @Published var driftVectors: [UUID: DriftVector] = [:]
    @Published var nodeProximities: [UUID: [UUID: Double]] = [:] // Distance matrix
    
    // MARK: - Private Properties
    
    private var driftTimer: Timer?
    private var resonanceCheckTimer: Timer?
    private var embeddingCache: [UUID: [Float]] = [:]
    private let embeddingService = LocalEmbeddingService()
    private var cancellables = Set<AnyCancellable>()
    
    // Physics parameters
    private let frameRate: Double = 60.0 // 60 FPS
    private let resonanceCheckInterval: Double = 0.5 // Check every 0.5 seconds
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    func startDriftMode(for nodes: [ThoughtNode]) {
        guard configuration.isEnabled else { return }
        
        print("🌊 Starting Drift Mode for \(nodes.count) nodes")
        
        // Initialize drift vectors for each node
        for node in nodes {
            if driftVectors[node.id] == nil {
                driftVectors[node.id] = DriftVector(
                    dx: Double.random(in: -0.5...0.5),
                    dy: Double.random(in: -0.5...0.5)
                )
            }
        }
        
        // Pre-generate embeddings
        Task {
            await generateEmbeddings(for: nodes)
        }
        
        // Start physics simulation
        startPhysicsSimulation(nodes: nodes)
        
        // Start resonance detection
        startResonanceDetection(nodes: nodes)
    }
    
    func stopDriftMode() {
        print("🛑 Stopping Drift Mode")
        
        driftTimer?.invalidate()
        driftTimer = nil
        
        resonanceCheckTimer?.invalidate()
        resonanceCheckTimer = nil
        
        // Clear active resonances with animation
        withAnimation(.easeOut(duration: 0.5)) {
            activeResonances.removeAll()
        }
    }
    
    func pauseDriftMode() {
        driftTimer?.invalidate()
        resonanceCheckTimer?.invalidate()
    }
    
    func resumeDriftMode(for nodes: [ThoughtNode]) {
        guard configuration.isEnabled else { return }
        startPhysicsSimulation(nodes: nodes)
        startResonanceDetection(nodes: nodes)
    }
    
    // MARK: - Physics Simulation
    
    private func startPhysicsSimulation(nodes: [ThoughtNode]) {
        driftTimer?.invalidate()
        
        driftTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / frameRate, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.updateNodePositions(nodes)
            }
        }
    }
    
    private func updateNodePositions(_ nodes: [ThoughtNode]) {
        let speedMultiplier = configuration.driftSpeed
        
        for node in nodes {
            guard var vector = driftVectors[node.id] else { continue }
            
            // 1. Apply Brownian motion
            vector.apply(brownian: configuration.brownianIntensity * speedMultiplier)
            
            // 2. Calculate forces from other nodes
            let forces = calculateForces(for: node, among: nodes)
            vector.dx += forces.dx * speedMultiplier
            vector.dy += forces.dy * speedMultiplier
            
            // 3. Apply boundary constraints (soft boundaries)
            applyBoundaryForces(node: node, vector: &vector)
            
            // 4. Limit maximum speed
            vector.limit(to: configuration.maxDriftDistance / 10.0 * speedMultiplier)
            
            // 5. Update position
            withAnimation(.linear(duration: 1.0 / frameRate)) {
                node.position.x += vector.dx
                node.position.y += vector.dy
            }
            
            // 6. Store updated vector
            driftVectors[node.id] = vector
            
            // 7. Update proximity matrix
            updateProximity(for: node, among: nodes)
        }
    }
    
    private func calculateForces(for node: ThoughtNode, among nodes: [ThoughtNode]) -> DriftVector {
        var totalForce = DriftVector(dx: 0, dy: 0)
        
        for other in nodes {
            guard other.id != node.id else { continue }
            
            let dx = other.position.x - node.position.x
            let dy = other.position.y - node.position.y
            let distance = sqrt(dx * dx + dy * dy)
            
            guard distance > 0.1 else { continue } // Avoid division by zero
            
            // Normalize direction
            let dirX = dx / distance
            let dirY = dy / distance
            
            // Calculate similarity-based attraction
            let similarity = calculateSimilarity(node, other)
            
            if similarity > configuration.resonanceThreshold {
                // Strong attraction for similar nodes
                let attractionForce = configuration.attractionStrength * similarity * (1.0 / max(distance / 100.0, 0.5))
                totalForce.dx += dirX * attractionForce
                totalForce.dy += dirY * attractionForce
            } else if distance < 100 {
                // Repulsion for close but dissimilar nodes
                let repulsionForce = configuration.repulsionStrength * (100 - distance) / 100
                totalForce.dx -= dirX * repulsionForce
                totalForce.dy -= dirY * repulsionForce
            }
        }
        
        return totalForce
    }
    
    private func applyBoundaryForces(node: ThoughtNode, vector: inout DriftVector) {
        let boundaryStrength = 0.5
        let maxDistance = configuration.maxDriftDistance * 10
        
        // Soft boundaries - apply force when approaching edges
        if abs(node.position.x) > maxDistance * 0.8 {
            vector.dx -= (node.position.x / maxDistance) * boundaryStrength
        }
        
        if abs(node.position.y) > maxDistance * 0.8 {
            vector.dy -= (node.position.y / maxDistance) * boundaryStrength
        }
    }
    
    // MARK: - Resonance Detection
    
    private func startResonanceDetection(nodes: [ThoughtNode]) {
        resonanceCheckTimer?.invalidate()
        
        resonanceCheckTimer = Timer.scheduledTimer(
            withTimeInterval: resonanceCheckInterval,
            repeats: true
        ) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                await self.checkForResonances(among: nodes)
            }
        }
    }
    
    private func checkForResonances(among nodes: [ThoughtNode]) async {
        let proximityThreshold: Double = 150.0 // Distance for potential resonance
        let now = Date()
        
        // Clean up expired resonances
        activeResonances.removeAll { resonance in
            resonance.timestamp.addingTimeInterval(resonance.duration) < now
        }
        
        // Check for new resonances
        for i in 0..<nodes.count {
            for j in (i+1)..<nodes.count {
                let node1 = nodes[i]
                let node2 = nodes[j]
                
                // Calculate distance
                let dx = node1.position.x - node2.position.x
                let dy = node1.position.y - node2.position.y
                let distance = sqrt(dx * dx + dy * dy)
                
                // Check if nodes are close enough
                guard distance < proximityThreshold else { continue }
                
                // Check if this resonance is already active
                let isActive = activeResonances.contains { resonance in
                    (resonance.node1.id == node1.id && resonance.node2.id == node2.id) ||
                    (resonance.node1.id == node2.id && resonance.node2.id == node1.id)
                }
                
                guard !isActive else { continue }
                
                // Calculate similarity
                let similarity = calculateSimilarity(node1, node2)
                
                // Check for resonance threshold
                if similarity > configuration.resonanceThreshold {
                    // Generate insight
                    let insight = await generateResonanceInsight(node1: node1, node2: node2, similarity: similarity)
                    
                    // Create resonance event
                    let resonance = DriftResonanceEvent(
                        node1: node1,
                        node2: node2,
                        similarity: similarity,
                        insight: insight
                    )
                    
                    // Add with animation
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        activeResonances.append(resonance)
                    }
                    
                    // Store discovered association
                    if let insight = insight {
                        discoveredAssociations.append((node1, node2, insight))
                    }
                    
                    // Haptic feedback
                    provideHapticFeedback()
                    
                    print("✨ Resonance detected: \(similarity) between nodes")
                }
            }
        }
    }
    
    // MARK: - Embedding and Similarity
    
    private func generateEmbeddings(for nodes: [ThoughtNode]) async {
        for node in nodes {
            if embeddingCache[node.id] == nil {
                if let embedding = await embeddingService.generateEmbedding(for: node.content) {
                    embeddingCache[node.id] = embedding
                }
            }
        }
    }
    
    private func calculateSimilarity(_ node1: ThoughtNode, _ node2: ThoughtNode) -> Double {
        guard let emb1 = embeddingCache[node1.id],
              let emb2 = embeddingCache[node2.id] else {
            // Fallback to simple text similarity
            return calculateTextSimilarity(node1.content, node2.content)
        }
        
        return Double(cosineSimilarity(emb1, emb2))
    }
    
    private func calculateTextSimilarity(_ text1: String, _ text2: String) -> Double {
        let words1 = Set(text1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(text2.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        guard !words1.isEmpty && !words2.isEmpty else { return 0 }
        
        let intersection = words1.intersection(words2).count
        let union = words1.union(words2).count
        
        return Double(intersection) / Double(union)
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }
        
        var dotProduct: Float = 0
        var normA: Float = 0
        var normB: Float = 0
        
        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        
        guard normA > 0 && normB > 0 else { return 0 }
        return dotProduct / (sqrt(normA) * sqrt(normB))
    }
    
    // MARK: - Insight Generation
    
    private func generateResonanceInsight(
        node1: ThoughtNode,
        node2: ThoughtNode,
        similarity: Double
    ) async -> String? {
        
        // Simple insight generation based on similarity and content
        let templates = [
            "这两个想法在概念上高度相关 (相似度: \(Int(similarity * 100))%)",
            "发现潜在的主题联系",
            "可能存在互补关系",
            "值得探索的思维连接",
            "共鸣产生：可能指向更深层的模式"
        ]
        
        // In production, this would call AI service for deeper insight
        return templates.randomElement()
    }
    
    // MARK: - Proximity Management
    
    private func updateProximity(for node: ThoughtNode, among nodes: [ThoughtNode]) {
        if nodeProximities[node.id] == nil {
            nodeProximities[node.id] = [:]
        }
        
        for other in nodes {
            guard other.id != node.id else { continue }
            
            let dx = other.position.x - node.position.x
            let dy = other.position.y - node.position.y
            let distance = sqrt(dx * dx + dy * dy)
            
            nodeProximities[node.id]?[other.id] = distance
        }
    }
    
    // MARK: - Haptic Feedback
    
    private func provideHapticFeedback() {
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.prepare()
        impact.impactOccurred()
        #endif
    }
    
    // MARK: - Configuration
    
    func updateConfiguration(_ config: DriftConfiguration) {
        configuration = config
        
        if !config.isEnabled {
            stopDriftMode()
        }
    }
    
    // MARK: - Observers
    
    private func setupObservers() {
        // Clean up expired resonances periodically
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.cleanupExpiredResonances()
            }
            .store(in: &cancellables)
    }
    
    private func cleanupExpiredResonances() {
        let now = Date()
        activeResonances.removeAll { resonance in
            resonance.timestamp.addingTimeInterval(resonance.duration) < now
        }
    }
    
    // MARK: - Debug and Visualization
    
    func getVisualizationData() -> DriftVisualizationData {
        DriftVisualizationData(
            vectors: driftVectors,
            resonances: activeResonances,
            proximities: nodeProximities
        )
    }
}

// MARK: - Visualization Data

struct DriftVisualizationData {
    let vectors: [UUID: DriftVector]
    let resonances: [DriftResonanceEvent]
    let proximities: [UUID: [UUID: Double]]
}

// MARK: - Drift Mode View Modifier

struct DriftModeModifier: ViewModifier {
    @ObservedObject var engine: DriftModeEngine
    let nodes: [ThoughtNode]
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    // Resonance visualizations
                    ForEach(engine.activeResonances, id: \.id) { resonance in
                        ResonanceVisualization(resonance: resonance)
                    }
                }
                .allowsHitTesting(false)
            )
            .onAppear {
                if engine.configuration.isEnabled {
                    engine.startDriftMode(for: nodes)
                }
            }
            .onDisappear {
                engine.pauseDriftMode()
            }
    }
}

struct ResonanceVisualization: View {
    let resonance: DriftResonanceEvent
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let from = CGPoint(
                    x: resonance.node1.position.x + geometry.size.width / 2,
                    y: resonance.node1.position.y + geometry.size.height / 2
                )
                let to = CGPoint(
                    x: resonance.node2.position.x + geometry.size.width / 2,
                    y: resonance.node2.position.y + geometry.size.height / 2
                )
                
                path.move(to: from)
                path.addLine(to: to)
            }
            .stroke(
                LinearGradient(
                    colors: [Color.yellow, Color.orange],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(
                    lineWidth: 3,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: [5, 3]
                )
            )
            .opacity(opacity)
            .scaleEffect(scale)
            .blur(radius: 2)
            .animation(.easeInOut(duration: 0.5), value: opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.3)) {
                    opacity = 0.8
                    scale = 1.0
                }
                
                // Fade out before removal
                DispatchQueue.main.asyncAfter(deadline: .now() + resonance.duration - 0.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        opacity = 0
                        scale = 1.2
                    }
                }
            }
        }
    }
}

extension View {
    func driftMode(engine: DriftModeEngine, nodes: [ThoughtNode]) -> some View {
        self.modifier(DriftModeModifier(engine: engine, nodes: nodes))
    }
}