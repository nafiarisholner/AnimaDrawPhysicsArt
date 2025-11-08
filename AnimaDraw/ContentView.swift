

import SwiftUI
import Foundation

struct Drawing: Identifiable, Codable {
    let id: UUID
    var points: [CGPoint]
    var velocities: [CGPoint]
    var timestamp: Date
    var duration: TimeInterval
    var score: Int
    var coinsEarned: Int
    
    init(points: [CGPoint], velocities: [CGPoint]) {
        self.id = UUID()
        self.points = points
        self.velocities = velocities
        self.timestamp = Date()
        self.duration = 0.0
        self.score = points.count * 10
        self.coinsEarned = points.count
    }
}

struct Level: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String
    let requiredCoins: Int
    var isUnlocked: Bool
    let targetScore: Int
    let color: String
    
    static let allLevels: [Level] = [
        Level(id: 1, name: "Beginner's Luck", description: "Draw your first masterpiece", requiredCoins: 0, isUnlocked: true, targetScore: 500, color: "green"),
        Level(id: 2, name: "Creative Flow", description: "Unlock advanced drawing tools", requiredCoins: 100, isUnlocked: false, targetScore: 1000, color: "blue"),
        Level(id: 3, name: "AnimaDraw", description: "Master the art of movement", requiredCoins: 250, isUnlocked: false, targetScore: 2000, color: "purple"),
        Level(id: 4, name: "Velocity Vision", description: "See your drawings come alive", requiredCoins: 500, isUnlocked: false, targetScore: 3500, color: "orange"),
        Level(id: 5, name: "Energy Artist", description: "Harness the power of motion", requiredCoins: 800, isUnlocked: false, targetScore: 5000, color: "red"),
        Level(id: 6, name: "Dynamic Designer", description: "Create complex animations", requiredCoins: 1200, isUnlocked: false, targetScore: 7000, color: "pink"),
        Level(id: 7, name: "Rhythm Creator", description: "Find the flow in every line", requiredCoins: 1700, isUnlocked: false, targetScore: 9000, color: "teal"),
        Level(id: 8, name: "Motion Magician", description: "Weave magic with movement", requiredCoins: 2300, isUnlocked: false, targetScore: 12000, color: "indigo"),
        Level(id: 9, name: "Flow Genius", description: "Become one with the motion", requiredCoins: 3000, isUnlocked: false, targetScore: 15000, color: "yellow"),
        Level(id: 10, name: "Grand Master", description: "Reach the pinnacle of momentum art", requiredCoins: 4000, isUnlocked: false, targetScore: 20000, color: "gold")
    ]
}

struct TutorialStep: Identifiable {
    let id: Int
    let title: String
    let description: String
    let image: String
    let action: String?
    
    static let tutorialSteps: [TutorialStep] = [
        TutorialStep(id: 1, title: "Welcome to AnimaDraw", description: "Create beautiful animations by drawing with momentum. The faster you draw, the more dynamic your animations!", image: "sparkles", action: nil),
        TutorialStep(id: 2, title: "Drawing Basics", description: "Draw continuous lines on the canvas. Your drawing speed and direction create unique momentum effects.", image: "pencil.tip", action: nil),
        TutorialStep(id: 3, title: "Earn Coins & Score", description: "• 10 points per drawing point\n• 1 coin per point drawn\n• Complete levels to unlock new features", image: "dollarsign.circle", action: nil),
        TutorialStep(id: 4, title: "Level Progression", description: "Unlock 10 exciting levels by earning coins. Each level offers new challenges and rewards!", image: "star.fill", action: nil),
        TutorialStep(id: 5, title: "Animation Magic", description: "Watch your drawings come alive with beautiful animations. Use play/pause to control the flow.", image: "play.circle", action: nil),
        TutorialStep(id: 6, title: "Save & Share", description: "Save your best creations in the gallery and replay them anytime. Build your portfolio!", image: "square.and.arrow.down", action: "Let's Draw!")
    ]
}

extension CGPoint {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }
    
    private enum CodingKeys: String, CodingKey {
        case x, y
    }
}

class GameManager: ObservableObject {
    @Published var drawings: [Drawing] = []
    @Published var currentScore = 0
    @Published var highScore = 0
    @Published var totalCoins = 0
    @Published var gameState: GameState = .menu
    @Published var currentLevel = 1
    @Published var currentDrawing: Drawing?
    @Published var levels: [Level] = Level.allLevels
    @Published var showTutorial = false
    @Published var tutorialStep = 0
    
    private let saveKey = "savedDrawings"
    private let highScoreKey = "highScore"
    private let coinsKey = "totalCoins"
    private let levelsKey = "unlockedLevels"
    private let tutorialKey = "hasSeenTutorial"
    
    enum GameState {
        case menu, drawing, animating, gallery, levels
    }
    
    init() {
        loadData()
    }
    
    func save(_ drawing: Drawing) {
        drawings.insert(drawing, at: 0)
        currentScore = drawing.score
        totalCoins += drawing.coinsEarned
        
        if currentScore > highScore {
            highScore = currentScore
            UserDefaults.standard.set(highScore, forKey: highScoreKey)
        }
        
        UserDefaults.standard.set(totalCoins, forKey: coinsKey)
        checkLevelUnlocks()
        saveDrawings()
    }
    
    func unlockNextLevel() {
        if currentLevel < levels.count {
            currentLevel += 1
            if currentLevel - 1 < levels.count {
                levels[currentLevel - 1].isUnlocked = true
            }
            saveLevelProgress()
        }
    }
    
    func checkLevelUnlocks() {
        for i in 0..<levels.count {
            if totalCoins >= levels[i].requiredCoins && !levels[i].isUnlocked {
                levels[i].isUnlocked = true
                if i + 1 > currentLevel {
                    currentLevel = i + 1
                }
            }
        }
        saveLevelProgress()
    }
    
    func canUnlockLevel(_ level: Level) -> Bool {
        return totalCoins >= level.requiredCoins
    }
    
    func unlockLevel(_ level: Level) -> Bool {
        if canUnlockLevel(level) {
            if let index = levels.firstIndex(where: { $0.id == level.id }) {
                levels[index].isUnlocked = true
                currentLevel = max(currentLevel, level.id)
                saveLevelProgress()
                return true
            }
        }
        return false
    }
    
    private func saveLevelProgress() {
        let unlockedLevels = levels.filter { $0.isUnlocked }.map { $0.id }
        UserDefaults.standard.set(unlockedLevels, forKey: levelsKey)
        UserDefaults.standard.set(currentLevel, forKey: "currentLevel")
    }
    
    private func saveDrawings() {
        if let encoded = try? JSONEncoder().encode(drawings) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Drawing].self, from: data) {
            drawings = decoded
        }
        
        highScore = UserDefaults.standard.integer(forKey: highScoreKey)
        totalCoins = UserDefaults.standard.integer(forKey: coinsKey)
        
        let savedCurrentLevel = UserDefaults.standard.integer(forKey: "currentLevel")
        self.currentLevel = max(1, savedCurrentLevel)
        
        if let unlockedLevels = UserDefaults.standard.array(forKey: levelsKey) as? [Int] {
            for i in 0..<levels.count {
                levels[i].isUnlocked = unlockedLevels.contains(levels[i].id) || levels[i].id == 1
            }
        } else {
            levels[0].isUnlocked = true
        }
        
        if !UserDefaults.standard.bool(forKey: tutorialKey) {
            showTutorial = true
            UserDefaults.standard.set(true, forKey: tutorialKey)
        }
    }
    
    func delete(_ drawing: Drawing) {
        drawings.removeAll { $0.id == drawing.id }
        saveDrawings()
    }
    
    func resetGame() {
        currentScore = 0
        gameState = .menu
        currentDrawing = nil
    }
    
    func completeTutorial() {
        showTutorial = false
        tutorialStep = 0
    }
    
    func nextTutorialStep() {
        if tutorialStep < TutorialStep.tutorialSteps.count - 1 {
            tutorialStep += 1
        } else {
            completeTutorial()
            gameState = .drawing
        }
    }
}


import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    @State private var scale = 0.3
    @State private var rotation = 0.0
    @State private var glowOpacity = 0.3
    
    var body: some View {
        if isActive {
            GameMainView()
        } else {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.3),
                        Color(red: 0.3, green: 0.1, blue: 0.5),
                        Color(red: 0.1, green: 0.2, blue: 0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ForEach(0..<15) { index in
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: CGFloat.random(in: 2...8), height: CGFloat.random(in: 2...8))
                        .position(
                            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                            y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                        )
                        .opacity(glowOpacity)
                }
                
                VStack(spacing: 30) {
                    ZStack {
                        
                        Image("draw")
                            .resizable()
                            .frame(width: 100,height: 100)
                            .shadow(color: .yellow, radius: 10)
                    }
                    .scaleEffect(scale)
                    
                    VStack(spacing: 15) {
                        Text("MOMENTUM GAME")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .purple, radius: 10)
                        
                        Text("Draw • Animate • Conquer")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .italic()
                    }
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 200, height: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.yellow)
                                .frame(width: 200 * scale, height: 4)
                                .shadow(color: .yellow, radius: 5),
                            alignment: .leading
                        )
                }
                .scaleEffect(scale)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    scale = 1.0
                }
                
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowOpacity = 0.8
                }
                
                withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

import SwiftUI

struct GameMainView: View {
    @StateObject private var gameManager = GameManager()
    
    var body: some View {
        ZStack {
            // Background - fixed, non-scrolling
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.2),
                    Color(red: 0.2, green: 0.1, blue: 0.3),
                    Color(red: 0.1, green: 0.15, blue: 0.25)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Star field background - fixed, non-scrolling
            StarField()
            
            // Main content area - each view handles its own scrolling
            Group {
                switch gameManager.gameState {
                case .menu:
                    MainMenuView(gameManager: gameManager)
                case .drawing:
                    DrawingGameView(gameManager: gameManager)
                case .animating:
                    AnimationView(gameManager: gameManager)
                case .gallery:
                    GalleryView(gameManager: gameManager)
                case .levels:
                    LevelsView(gameManager: gameManager)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Tutorial overlay - fixed position
            if gameManager.showTutorial {
                TutorialView(gameManager: gameManager)
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
    }
}



struct StarField: View {
    @State private var stars: [Star] = []
    
    struct Star {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
    }
    
    init() {
        var stars = [Star]()
        for _ in 0..<50 {
            stars.append(Star(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                size: CGFloat.random(in: 1...3),
                opacity: Double.random(in: 0.1...0.8)
            ))
        }
        _stars = State(initialValue: stars)
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<stars.count, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: stars[index].size, height: stars[index].size)
                    .position(x: stars[index].x, y: stars[index].y)
                    .opacity(stars[index].opacity)
            }
        }
    }
}


struct MainMenuView: View {
    @ObservedObject var gameManager: GameManager
    @State private var buttonScale: [CGFloat] = [1.0, 1.0, 1.0, 1.0]
    @State private var titleGlow = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header stats
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Coins")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: 6) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(.yellow)
                                .font(.title2)
                            
                            Text("\(gameManager.totalCoins)")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(.yellow)
                                .shadow(color: .orange, radius: 5)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Level")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(gameManager.currentLevel)/10")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.purple)
                            .shadow(color: .blue, radius: 5)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                Spacer(minLength: 20)
                
                // Title section
                VStack(spacing: 10) {
                    Text("MOMENTUM")
                        .font(.system(size: 50, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .purple, radius: titleGlow ? 20 : 10)
                        .scaleEffect(titleGlow ? 1.05 : 1.0)
                    
                    Text("GAME")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                        .shadow(color: .orange, radius: titleGlow ? 15 : 8)
                        .scaleEffect(titleGlow ? 1.05 : 1.0)
                    
            
                    Text("Create Eternal Motion")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .italic()
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        titleGlow.toggle()
                    }
                }
                
                Spacer(minLength: 20)
                
                // Next level progress
                if let nextLevel = gameManager.levels.first(where: { $0.id == gameManager.currentLevel + 1 }) {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Next: \(nextLevel.name)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(gameManager.totalCoins)/\(nextLevel.requiredCoins)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        ProgressBar(value: Double(gameManager.totalCoins), maxValue: Double(nextLevel.requiredCoins))
                            .frame(height: 8)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 30)
                }
                
                Spacer(minLength: 20)
                
                // Stats row
                HStack(spacing: 30) {
                    StatBox(title: "HIGH SCORE", value: "\(gameManager.highScore)")
                    StatBox(title: "CREATIONS", value: "\(gameManager.drawings.count)")
                    StatBox(title: "COINS", value: "\(gameManager.totalCoins)")
                }
                .padding(.horizontal)
                
                Spacer(minLength: 20)
                
                // Action buttons
                VStack(spacing: 20) {
                    GameButton(
                        title: "🎨 START DRAWING GAME",
                        subtitle: "Create your momentum art",
                        color: .blue,
                        scale: $buttonScale[0]
                    ) {
                        animateButton(index: 0)
                        gameManager.gameState = .drawing
                    }
                    
                    GameButton(
                        title: "📚 GAME GALLERY",
                        subtitle: "View your creations",
                        color: .purple,
                        scale: $buttonScale[1]
                    ) {
                        animateButton(index: 1)
                        gameManager.gameState = .gallery
                    }
                    
                    GameButton(
                        title: "🏆 GAME LEVELS",
                        subtitle: "Progress & unlock features",
                        color: .green,
                        scale: $buttonScale[2]
                    ) {
                        animateButton(index: 2)
                        gameManager.gameState = .levels
                    }
                    
                    GameButton(
                        title: "🎓 GAME TUTORIAL",
                        subtitle: "Learn to play",
                        color: .orange,
                        scale: $buttonScale[3]
                    ) {
                        animateButton(index: 3)
                        gameManager.showTutorial = true
                        gameManager.tutorialStep = 0
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer(minLength: 20)
                
                // Footer
                Text("Draw with energy, create with style!")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height)
        }
        .scrollIndicators(.hidden) // Hide scroll indicators for cleaner look
    }
    
    private func animateButton(index: Int) {
        withAnimation(.spring()) {
            buttonScale[index] = 0.9
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring()) {
                buttonScale[index] = 1.0
            }
        }
    }
}

struct ProgressBar: View {
    let value: Double
    let maxValue: Double
    let height: CGFloat = 8
    
    var progress: Double {
        return min(value / maxValue, 1.0)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: height)
                    .opacity(0.3)
                    .foregroundColor(.white)
                
                Rectangle()
                    .frame(width: min(CGFloat(self.progress) * geometry.size.width, geometry.size.width), height: height)
                    .foregroundColor(.yellow)
                    .animation(.linear, value: progress)
            }
            .cornerRadius(height / 2)
        }
        .frame(height: height)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.yellow)
                .shadow(color: .orange, radius: 5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

struct GameButton: View {
    let title: String
    let subtitle: String
    let color: Color
    @Binding var scale: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [color, color.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: color, radius: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
            )
        }
        .scaleEffect(scale)
        .buttonStyle(PlainButtonStyle())
    }
}


import SwiftUI

struct DrawingGameView: View {
    @ObservedObject var gameManager: GameManager
    @State private var currentPoints: [CGPoint] = []
    @State private var currentVelocities: [CGPoint] = []
    @State private var showInstructions = true
    
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Button("← MENU") {
                        gameManager.resetGame()
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("SCORE: \(currentPoints.count * 10)")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(.yellow)
                        
                        Text("Coins: +\(currentPoints.count)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                        
                        Text("Level \(gameManager.currentLevel)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Button("ANIMATE →") {
                        if currentPoints.count >= 10 {
                            startAnimation()
                        }
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(currentPoints.count >= 10 ? .white : .gray)
                    .padding(10)
                    .background(currentPoints.count >= 10 ? Color.green.opacity(0.3) : Color.gray.opacity(0.3))
                    .cornerRadius(10)
                    .disabled(currentPoints.count < 10)
                }
                .padding()
                .background(Color.black.opacity(0.5))
                
                ZStack {
                    Canvas { context, size in
                        let gridSize: CGFloat = 20
                        for x in stride(from: 0, through: size.width, by: gridSize) {
                            var path = Path()
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: size.height))
                            context.stroke(path, with: .color(Color.white.opacity(0.1)), lineWidth: 1)
                        }
                        for y in stride(from: 0, through: size.height, by: gridSize) {
                            var path = Path()
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: size.width, y: y))
                            context.stroke(path, with: .color(Color.white.opacity(0.1)), lineWidth: 1)
                        }
                    }
                    
                    Canvas { context, size in
                        if !currentPoints.isEmpty {
                            var path = Path()
                            path.addLines(currentPoints)
                            
                            context.stroke(path, with: .color(.blue.opacity(0.3)), lineWidth: 15)
                            context.stroke(path, with: .color(.purple.opacity(0.2)), lineWidth: 25)
                            context.stroke(path, with: .color(.white), lineWidth: 5)
                            
                            if let first = currentPoints.first {
                                let startCircle = Path(ellipseIn: CGRect(x: first.x-8, y: first.y-8, width: 16, height: 16))
                                context.fill(startCircle, with: .color(.green))
                            }
                            if let last = currentPoints.last {
                                let endCircle = Path(ellipseIn: CGRect(x: last.x-6, y: last.y-6, width: 12, height: 12))
                                context.fill(endCircle, with: .color(.red))
                            }
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if showInstructions { showInstructions = false }
                                
                                let point = value.location
                                let velocity = value.velocity
                                
                                currentPoints.append(point)
                                currentVelocities.append(CGPoint(x: velocity.width / 500, y: velocity.height / 500))
                                
                                if currentPoints.count > 2000 {
                                    currentPoints.removeFirst(100)
                                    currentVelocities.removeFirst(100)
                                }
                            }
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            if showInstructions {
                VStack {
                    Text("🎨 DRAW YOUR MASTERPIECE")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(15)
                    
                    Text("Draw a continuous line\nMake it creative and flowing!")
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding(.bottom, 200)
            }
            
            VStack {
                Spacer()
                
                HStack(spacing: 20) {
                    ActionButton(icon: "trash", color: .red) {
                        currentPoints.removeAll()
                        currentVelocities.removeAll()
                        showInstructions = true
                    }
                    
                    ActionButton(icon: "play.circle", color: .green) {
                        if currentPoints.count >= 10 {
                            startAnimation()
                        }
                    }
                    .opacity(currentPoints.count >= 10 ? 1.0 : 0.5)
                    
                    ActionButton(icon: "square.and.arrow.down", color: .blue) {
                        saveDrawing()
                    }
                    .opacity(currentPoints.count >= 10 ? 1.0 : 0.5)
                }
                .padding(.bottom, 30)
            }
        }
    }
    
    private func startAnimation() {
        let drawing = Drawing(points: currentPoints, velocities: currentVelocities)
        gameManager.currentDrawing = drawing
        gameManager.currentScore = drawing.score
        gameManager.gameState = .animating
    }
    
    private func saveDrawing() {
        let drawing = Drawing(points: currentPoints, velocities: currentVelocities)
        gameManager.save(drawing)
        currentPoints.removeAll()
        currentVelocities.removeAll()
        showInstructions = true
    }
}

struct ActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(color)
                .cornerRadius(25)
                .shadow(color: color, radius: 5)
        }
    }
}

import SwiftUI

struct AnimationView: View {
    @ObservedObject var gameManager: GameManager
    @State private var animationPhase = 0.0
    @State private var isAnimating = true
    @State private var showScore = false
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button("← BACK") {
                        gameManager.gameState = .drawing
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    VStack {
                        Text("YOUR SCORE")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(gameManager.currentScore)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.yellow)
                            .scaleEffect(showScore ? 1.2 : 1.0)
                    }
                    
                    Spacer()
                    
                    Button("SAVE") {
                        saveCurrentDrawing()
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.green.opacity(0.3))
                    .cornerRadius(10)
                }
                .padding()
                .background(Color.black.opacity(0.5))
                
                Spacer()
                
                Canvas { context, size in
                    let animatedPath = createAnimatedPath(phase: animationPhase, in: size)
                    
                    context.stroke(animatedPath, with: .color(.purple.opacity(0.3)), lineWidth: 30)
                    context.stroke(animatedPath, with: .color(.blue.opacity(0.4)), lineWidth: 20)
                    context.stroke(animatedPath, with: .color(.white.opacity(0.6)), lineWidth: 8)
                    context.stroke(animatedPath, with: .color(.yellow), lineWidth: 3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
                
                HStack(spacing: 30) {
                    ControlButton(icon: "backward.end.fill", color: .blue) {
                        animationPhase = 0.0
                    }
                    
                    ControlButton(icon: isAnimating ? "pause.circle.fill" : "play.circle.fill", color: .green) {
                        isAnimating.toggle()
                    }
                    
                    ControlButton(icon: "arrow.clockwise", color: .orange) {
                        animationPhase = 0.0
                        isAnimating = true
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            withAnimation(.spring()) {
                showScore = true
            }
        }
        .onReceive(Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()) { _ in
            if isAnimating {
                animationPhase += 0.015
                if animationPhase >= 1.0 {
                    animationPhase = 0.0
                }
            }
        }
    }
    
    private func createAnimatedPath(phase: Double, in size: CGSize) -> Path {
        var path = Path()
        
        if let drawing = gameManager.currentDrawing {
            let totalPoints = drawing.points.count
            let visiblePoints = Int(Double(totalPoints) * phase)
            
            guard visiblePoints > 1 else { return path }
            
            let points = Array(drawing.points[0..<visiblePoints])
            path.addLines(points)
        } else {
            let points = createSamplePoints(phase: phase, in: size)
            if points.count > 1 {
                path.addLines(points)
            }
        }
        
        return path
    }
    
    private func createSamplePoints(phase: Double, in size: CGSize) -> [CGPoint] {
        var points: [CGPoint] = []
        let steps = 100
        for i in 0..<steps {
            let progress = Double(i) / Double(steps)
            let totalProgress = progress * phase
            
            if totalProgress <= 1.0 {
                let x = size.width * totalProgress
                let y = size.height / 2 + sin(totalProgress * 4 * .pi) * 100
                points.append(CGPoint(x: x, y: y))
            }
        }
        return points
    }
    
    private func saveCurrentDrawing() {
        if let drawing = gameManager.currentDrawing {
            gameManager.save(drawing)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                gameManager.gameState = .gallery
            }
        }
    }
}

struct ControlButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(color)
                .cornerRadius(30)
                .shadow(color: color, radius: 10)
        }
    }
}


struct LevelsView: View {
    @ObservedObject var gameManager: GameManager
    @State private var selectedLevel: Level?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("← BACK") {
                    gameManager.gameState = .menu
                }
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(10)
                .background(Color.blue.opacity(0.3))
                .cornerRadius(10)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("LEVEL PROGRESSION")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.yellow)
                        
                        Text("\(gameManager.totalCoins) Coins")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.yellow)
                    }
                }
                
                Spacer()
                
                // Invisible spacer for balance
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 60, height: 40)
            }
            .padding()
            .background(Color.black.opacity(0.5))
            
            // Scrollable content with explicit frame
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(gameManager.levels) { level in
                            LevelCard(level: level, gameManager: gameManager) {
                                selectedLevel = level
                            }
                        }
                    }
                    .padding()
                    .frame(minHeight: geometry.size.height)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .sheet(item: $selectedLevel) { level in
            LevelDetailView(level: level, gameManager: gameManager)
        }
    }
}




struct LevelCard: View {
    let level: Level
    let gameManager: GameManager
    let onTap: () -> Void
    
    var isCurrentLevel: Bool {
        return level.id == gameManager.currentLevel
    }
    
    var isLocked: Bool {
        return !level.isUnlocked
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(levelColor(level.color))
                        .frame(width: 50, height: 50)
                    
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .bold))
                    } else {
                        Text("\(level.id)")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(level.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        if isCurrentLevel {
                            Text("CURRENT")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.yellow)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.yellow.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(level.description)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                    
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                        
                        Text("\(level.requiredCoins) coins to unlock")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isLocked ? .red : .green)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if isLocked {
                        Image(systemName: "lock.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    
                    Text("Level \(level.id)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isCurrentLevel ? Color.yellow : Color.white.opacity(0.2), lineWidth: isCurrentLevel ? 2 : 1)
            )
            .opacity(isLocked ? 0.6 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLocked && !gameManager.canUnlockLevel(level))
    }
    
    private func levelColor(_ colorName: String) -> Color {
        switch colorName {
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "pink": return .pink
        case "teal": return .teal
        case "indigo": return .indigo
        case "yellow": return .yellow
        case "gold": return .yellow
        default: return .blue
        }
    }
}

struct LevelDetailView: View {
    let level: Level
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss
    
    var isLocked: Bool {
        return !level.isUnlocked
    }
    
    var canUnlock: Bool {
        return gameManager.canUnlockLevel(level)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Text("Level \(level.id)")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                .padding()
                
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(levelColor(level.color))
                            .frame(width: 100, height: 100)
                        
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(level.id)")
                                .font(.system(size: 40, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Text(level.name)
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                    
                    Text(level.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 12) {
                    InfoRow(icon: "dollarsign.circle.fill", title: "Required Coins", value: "\(level.requiredCoins)", color: .yellow)
                    InfoRow(icon: "star.fill", title: "Target Score", value: "\(level.targetScore)", color: .orange)
                    InfoRow(icon: "trophy.fill", title: "Status", value: isLocked ? "Locked" : "Unlocked", color: isLocked ? .red : .green)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                if isLocked {
                    VStack(spacing: 12) {
                        Text("You need \(level.requiredCoins - gameManager.totalCoins) more coins to unlock this level")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                        
                        if canUnlock {
                            Button("Unlock Level for \(level.requiredCoins) coins") {
                                if gameManager.unlockLevel(level) {
                                    dismiss()
                                }
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                        } else {
                            Button("Keep Drawing to Earn Coins") {
                                dismiss()
                                gameManager.gameState = .drawing
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                } else {
                    Button("Start Drawing at This Level") {
                        dismiss()
                        gameManager.currentLevel = level.id
                        gameManager.gameState = .drawing
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding()
                }
                
                Spacer()
            }
        }
    }
    
    private func levelColor(_ colorName: String) -> Color {
        switch colorName {
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "pink": return .pink
        case "teal": return .teal
        case "indigo": return .indigo
        case "yellow": return .yellow
        case "gold": return .yellow
        default: return .blue
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
    }
}


import SwiftUI

struct TutorialView: View {
    @ObservedObject var gameManager: GameManager
    @State private var currentStep = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    ForEach(0..<TutorialStep.tutorialSteps.count, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStep ? Color.yellow : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                let step = TutorialStep.tutorialSteps[currentStep]
                
                VStack(spacing: 30) {
                    Image(systemName: step.image)
                        .font(.system(size: 70, weight: .thin))
                        .foregroundColor(.yellow)
                        .padding()
                        .background(Circle().fill(Color.white.opacity(0.1)))
                    
                    VStack(spacing: 16) {
                        Text(step.title)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(step.description)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 30)
                }
                
                Spacer()
                
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation(.spring()) {
                                currentStep -= 1
                            }
                        }
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(25)
                    }
                    
                    Spacer()
                    
                    Button(step.action ?? (currentStep == TutorialStep.tutorialSteps.count - 1 ? "Complete" : "Next")) {
                        if currentStep < TutorialStep.tutorialSteps.count - 1 {
                            withAnimation(.spring()) {
                                currentStep += 1
                            }
                        } else {
                            gameManager.completeTutorial()
                        }
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.3))
                    .cornerRadius(25)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            currentStep = gameManager.tutorialStep
        }
        .onChange(of: currentStep) { oldValue, newValue in
            gameManager.tutorialStep = newValue
        }
    }
}

import SwiftUI

struct GalleryView: View {
    @ObservedObject var gameManager: GameManager
    @State private var selectedDrawing: Drawing?
    @State private var showAnimationView = false
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button("← BACK") {
                        gameManager.gameState = .menu
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    Text("MY GALLERY")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(gameManager.drawings.count)")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(.yellow)
                        .padding(10)
                        .background(Color.purple.opacity(0.3))
                        .cornerRadius(10)
                }
                .padding()
                .background(Color.black.opacity(0.5))
                
                if gameManager.drawings.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "tray")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("No Creations Yet")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("Start drawing to fill your gallery!")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            ForEach(gameManager.drawings) { drawing in
                                GalleryItem(drawing: drawing) {
                                    gameManager.currentDrawing = drawing
                                    gameManager.currentScore = drawing.score
                                    showAnimationView = true
                                } onDelete: {
                                    gameManager.delete(drawing)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            
            if showAnimationView {
                GalleryAnimationView(
                    gameManager: gameManager,
                    isPresented: $showAnimationView
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}

struct GalleryItem: View {
    let drawing: Drawing
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Canvas { context, size in
                        if !drawing.points.isEmpty {
                            var path = Path()
                            path.addLines(drawing.points)
                            
                            let scaledPoints = scalePoints(drawing.points, to: size)
                            var scaledPath = Path()
                            scaledPath.addLines(scaledPoints)
                            
                            context.stroke(scaledPath, with: .color(.white), lineWidth: 2)
                            context.stroke(scaledPath, with: .color(.yellow.opacity(0.5)), lineWidth: 4)
                        }
                    }
                    .padding(8)
                }
                .frame(height: 120)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Score: \(drawing.score)")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.yellow)
                    
                    HStack(spacing: 8) {
                        Text("\(drawing.points.count) points")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("+\(drawing.coinsEarned) coins")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                    }
                    
                    Text(formatDate(drawing.timestamp))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func scalePoints(_ points: [CGPoint], to size: CGSize) -> [CGPoint] {
        guard !points.isEmpty else { return [] }
        
        let minX = points.map { $0.x }.min() ?? 0
        let maxX = points.map { $0.x }.max() ?? 1
        let minY = points.map { $0.y }.min() ?? 0
        let maxY = points.map { $0.y }.max() ?? 1
        
        let width = maxX - minX
        let height = maxY - minY
        
        guard width > 0 && height > 0 else { return points }
        
        let scale = min((size.width - 20) / width, (size.height - 20) / height)
        let offsetX = (size.width - width * scale) / 2 - minX * scale
        let offsetY = (size.height - height * scale) / 2 - minY * scale
        
        return points.map { point in
            CGPoint(
                x: point.x * scale + offsetX,
                y: point.y * scale + offsetY
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct GalleryAnimationView: View {
    @ObservedObject var gameManager: GameManager
    @Binding var isPresented: Bool
    @State private var animationPhase = 0.0
    @State private var isAnimating = true
    
    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button("← BACK") {
                        isPresented = false
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    VStack {
                        Text("CREATION VIEW")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        if let drawing = gameManager.currentDrawing {
                            Text("Score: \(drawing.score)")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Spacer()
                    
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 60, height: 40)
                }
                .padding()
                .background(Color.black.opacity(0.7))
                
                ZStack {
                    if let drawing = gameManager.currentDrawing {
                        Canvas { context, size in
                            let animatedPath = createAnimatedPath(from: drawing, phase: animationPhase, in: size)
                            
                            context.stroke(animatedPath, with: .color(.purple.opacity(0.4)), lineWidth: 25)
                            context.stroke(animatedPath, with: .color(.blue.opacity(0.5)), lineWidth: 18)
                            context.stroke(animatedPath, with: .color(.white.opacity(0.8)), lineWidth: 6)
                            context.stroke(animatedPath, with: .color(.yellow), lineWidth: 2)
                            
                            if animationPhase > 0.01, let firstPoint = getPointAtPhase(drawing: drawing, phase: 0.01) {
                                let startCircle = Path(ellipseIn: CGRect(
                                    x: firstPoint.x - 6,
                                    y: firstPoint.y - 6,
                                    width: 12,
                                    height: 12
                                ))
                                context.fill(startCircle, with: .color(.green))
                            }
                            
                            if animationPhase > 0.99, let lastPoint = getPointAtPhase(drawing: drawing, phase: 0.99) {
                                let endCircle = Path(ellipseIn: CGRect(
                                    x: lastPoint.x - 4,
                                    y: lastPoint.y - 4,
                                    width: 8,
                                    height: 8
                                ))
                                context.fill(endCircle, with: .color(.red))
                            }
                        }
                    } else {
                        Text("No drawing data")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                
                VStack(spacing: 15) {
                    HStack(spacing: 20) {
                        ControlButton(icon: "backward.end.fill", color: .blue) {
                            animationPhase = 0.0
                        }
                        
                        ControlButton(
                            icon: isAnimating ? "pause.circle.fill" : "play.circle.fill",
                            color: .green
                        ) {
                            isAnimating.toggle()
                        }
                        
                        ControlButton(icon: "arrow.clockwise", color: .orange) {
                            animationPhase = 0.0
                            isAnimating = true
                        }
                    }
                    
                    VStack(spacing: 5) {
                        HStack {
                            Text("Progress")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("\(Int(animationPhase * 100))%")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: CGFloat(animationPhase) * UIScreen.main.bounds.width * 0.8, height: 6)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 30)
            }
        }
        .onReceive(timer) { _ in
            if isAnimating {
                animationPhase += 0.008
                if animationPhase >= 1.0 {
                    animationPhase = 0.0
                }
            }
        }
        .onAppear {
            animationPhase = 0.0
            isAnimating = true
        }
    }
    
    private func createAnimatedPath(from drawing: Drawing, phase: Double, in size: CGSize) -> Path {
        var path = Path()
        
        let totalPoints = drawing.points.count
        let visiblePoints = Int(Double(totalPoints) * phase)
        
        guard visiblePoints > 1 else { return path }
        
        let points = Array(drawing.points[0..<visiblePoints])
        
        let scaledPoints = scalePointsToCanvas(points, canvasSize: size)
        path.addLines(scaledPoints)
        
        return path
    }
    
    private func scalePointsToCanvas(_ points: [CGPoint], canvasSize: CGSize) -> [CGPoint] {
        guard !points.isEmpty else { return [] }
        
        let minX = points.map { $0.x }.min() ?? 0
        let maxX = points.map { $0.x }.max() ?? 1
        let minY = points.map { $0.y }.min() ?? 0
        let maxY = points.map { $0.y }.max() ?? 1
        
        let drawingWidth = maxX - minX
        let drawingHeight = maxY - minY
        
        guard drawingWidth > 0 && drawingHeight > 0 else { return points }
        
        let padding: CGFloat = 50
        let scale = min(
            (canvasSize.width - padding * 2) / drawingWidth,
            (canvasSize.height - padding * 2) / drawingHeight
        )
        
        let offsetX = (canvasSize.width - drawingWidth * scale) / 2 - minX * scale
        let offsetY = (canvasSize.height - drawingHeight * scale) / 2 - minY * scale
        
        return points.map { point in
            CGPoint(
                x: point.x * scale + offsetX,
                y: point.y * scale + offsetY
            )
        }
    }
    
    private func getPointAtPhase(drawing: Drawing, phase: Double) -> CGPoint? {
        let totalPoints = drawing.points.count
        let index = Int(Double(totalPoints) * phase)
        
        guard index >= 0 && index < drawing.points.count else { return nil }
        
        return drawing.points[index]
    }
}

struct GalleryControlButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(color)
                .cornerRadius(25)
                .shadow(color: color, radius: 8)
        }
    }
}
