import Foundation
import Combine

class CatchGame: ObservableObject {
    static private let startLevel = 0
    static private let startFreeSeconds = 7.0
    static private let startPosition = (x: 0.0, y: 0.0)
    static private let startButtonSize = (width: 0.0, height: 0.0)
    
    @Published private(set) var level = CatchGame.startLevel
    @Published private(set) var freeSeconds = CatchGame.startFreeSeconds
    @Published private(set) var position = CatchGame.startPosition
    @Published private(set) var buttonSize = CatchGame.startButtonSize
    
    private(set) var isYouWin: Bool?
    
    @Published var wasButtonPressed: Bool = false
    
    private lazy var levels = [{ self.firstLevel() }, { self.secondLevel() }, { self.thirdLevel() }, { self.fourthLevel() }]
    
    private let region = (width: 2.0, height: 2.0)

    func start() {
        level += 1
        play()
    }
    
    func restart() {
        level = CatchGame.startLevel
        freeSeconds = CatchGame.startFreeSeconds
        position = CatchGame.startPosition
        buttonSize = CatchGame.startButtonSize
        
        forRandomMoveStepCounter = 0
        forRandomResizeStepCounter = 0
        forNextColorInversion = 0
        
        isYouWin = nil
        wasButtonPressed = false
        onChangeColor.send(false)
    }
    
    private func play() {
        levels[level - 1]()
    }
    
    private var lastTime = Date().timeIntervalSince1970
    private func startCatching() {
        lastTime = Date().timeIntervalSince1970
    }
    
    private func firstLevel() {
        position.x = 0
        position.y = 0
        
        buttonSize.width = region.width / 5.0
        buttonSize.height = region.width / 5.0
        
        let numberSteps = 10
        let step = (region.width -  buttonSize.width) / (2.0 * Double(numberSteps))
        var direction = 1
        var stepIndexPosition = 0
        waitLevelResolve() { [unowned self] in
            if numberSteps <= abs(stepIndexPosition) {
                direction *= -1
            }
            
            stepIndexPosition += direction
            position.x += step * Double(direction)
        }
    }
    
    private func secondLevel() {
        waitLevelResolve() { [unowned self] in
            randomMove(eachStep: 5)
        }
    }
    
    private func thirdLevel() {
        waitLevelResolve() { [unowned self] in
            randomResize(eachStep: 2)
            randomMove(eachStep: 5)
        }
    }
    
    private func fourthLevel() {
        waitLevelResolve() { [unowned self] in
            colorInversion()
            randomResize(eachStep: 2)
            randomMove(eachStep: 5)
        }
    }
    
    private var forRandomMoveStepCounter = 0
    private func randomMove(eachStep: Int) {
        guard forRandomMoveStepCounter <= 0 else {
            forRandomMoveStepCounter -= 1
            return
        }
        forRandomMoveStepCounter = eachStep
        
        let range = (
            width: (region.width -  buttonSize.width) / 2.0,
            height: (region.height -  buttonSize.height) / 2.0
        )

        let minK = 0.5
        let maxK = 0.75
        
        position.x = Double.random(in: (range.width * minK)...(range.width * maxK))
        position.y = Double.random(in: (range.height * minK)...(range.height * maxK))
        position.x *= (Bool.random()) ? -1 : 1
        position.y *= (Bool.random()) ? -1 : 1
    }
    
    private var forRandomResizeStepCounter = 0
    private func randomResize(eachStep: Int) {
        guard forRandomResizeStepCounter <= 0 else {
            forRandomResizeStepCounter -= 1
            return
        }
        forRandomResizeStepCounter = eachStep
        
        let minK = 1 / 40.0
        let maxK = 1 / 5.0
        
        buttonSize.width = Double.random(in: (region.width * minK)...(region.width * maxK))
        buttonSize.height = Double.random(in: (region.width * minK)...(region.width * maxK))
    }
    
    private var forNextColorInversion = 0
    let onChangeColor = PassthroughSubject<Bool, Never>()
    private func colorInversion() {
        guard forNextColorInversion <= 0 else {
            forNextColorInversion -= 1
            return
        }
        forNextColorInversion = Int.random(in: 3...20)

        onChangeColor.send(true)
    }
    
    private func onLevelEnd() {
        defer {
            wasButtonPressed = false
        }
        
        let currentTime = Date().timeIntervalSince1970
        freeSeconds -= (currentTime - lastTime)
        lastTime = currentTime
        if !wasButtonPressed {
            isYouWin = false
            return
        }
        level += 1
        if level > levels.count {
            isYouWin = true
            print("Game Over")
            return
        }
        play()
    }
    
    let onTimeUpdate = PassthroughSubject<Double, Never>()
    
    let stepTime = 0.05
    private func waitLevelResolve(stepAction: @escaping () -> ()) {
        startCatching()
        Timer.scheduledTimer(withTimeInterval: stepTime, repeats: true) { [unowned self] timer in
            if wasButtonPressed || freeSeconds <= (Date().timeIntervalSince1970 - lastTime) {
                DispatchQueue.main.async {
                    onLevelEnd()
                }
                timer.invalidate()
            }
            
            onTimeUpdate.send(freeSeconds - (Date().timeIntervalSince1970 - lastTime))
            
            stepAction()
        }
    }
}
