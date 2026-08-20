import Foundation
import Combine

/// Echantillonne le CPU de Chrome et pilote l'application
final class ChromeMonitor: ObservableObject {

    // MARK: - Reglages

    
    let activityThresholdPercent: Double = 15        // au-dela de ce seuil on consière que chrome est actif (j'avais mesuré au repos < 1 %)
    let gaugeMaxPercent: Double = 200                // borne haute de la jauge
    @Published var quietSecondsBeforeFinish: TimeInterval = 180  // temps de calme continu avant de conclure
    let secondsBeforeGivingUp: TimeInterval = 900    // temps avant le désarmement auto si aucun pic n'arrive
    @Published var sleepWhenDone = true              // false = tester sans se faire endormir
    
    @Published private(set) var now = Date()

    private var displayTimer: Timer?

    // MARK: - Etats
    
    @Published private(set) var state: MonitorState = .idle
    @Published private(set) var currentCpuPercent: Double = 0
    @Published private(set) var lastActivityAt: Date?
    @Published private(set) var firstActivityAt: Date?
    @Published private(set) var activityCount: Int = 0

    // MARK: - Interne

    private var armedAt: Date?
    private var samplingTimer: Timer?
    private let samplingIntervalSeconds: TimeInterval = 10

    // MARK: - Commandes

    func arm() {
        state = .waitingForActivity
        armedAt = Date()
        lastActivityAt = nil
        firstActivityAt = nil
        activityCount = 0

        /// On pose le verrou
        Power.blockSleep()

        /// Boucle d'echantillonnage qui s'effectue tout les samplingIntervalSeconds secondes
        samplingTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: samplingIntervalSeconds, repeats: true) { [weak self] _ in
            self?.updateState()
        }
        timer.tolerance = 2
        samplingTimer = timer
        
        /// timer toutes les secondes
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.now = Date()
        }

        updateState()   // premiere mesure
    }

    func disarm() {
        state = .idle
        armedAt = nil
        lastActivityAt = nil
        Power.allowSleep()
        samplingTimer?.invalidate()
        samplingTimer = nil
        displayTimer?.invalidate()
        displayTimer = nil
    }

    func toggle() {
        state == .idle ? arm() : disarm()
    }

    // MARK: - Boucle de lecture du cpu

    private func updateState() {
        currentCpuPercent = Power.totalChromeCpuPercent()
        let now = Date()

        /// On mesure le cpu et on le mémorise
        if currentCpuPercent >= activityThresholdPercent {
            lastActivityAt = now
            activityCount += 1
            if state == .waitingForActivity {
                state = .chromeWorking
                firstActivityAt = now
            }
        }

        /// On décide selon l'etat
        switch state {

        case .idle:
            break

        case .waitingForActivity:
            /// Si toujours rien apres 15 min , c'est sûrement un oubli -> on désarme
            if let armedAt, now.timeIntervalSince(armedAt) > secondsBeforeGivingUp {
                disarm()
            }

        case .chromeWorking:
            guard let lastActivityAt else { return }
            /// Chaque pic rearme le compteur : il faut du calme continu pour que cela s'arrête
            if now.timeIntervalSince(lastActivityAt) > quietSecondsBeforeFinish {
                finishAndMaybeSleep()
            }
        }
    }

    /// Quand le compteur est fini et qu'on met en veille ou non
    private func finishAndMaybeSleep() {
        let shouldSleep = sleepWhenDone
        disarm()
        if shouldSleep { Power.sleepImmediately() }
    }

    // MARK: - Donnees d'affichage

    var isChromeActive: Bool { currentCpuPercent >= activityThresholdPercent }

    /// Position de la jauge, entre 0 et 1
    var gaugeFraction: Double {
        min(currentCpuPercent / gaugeMaxPercent, 1)
    }

    /// Secondes avant la fin, si rien ne relance le compteur
    var secondsBeforeFinish: TimeInterval {
        guard let lastActivityAt else { return quietSecondsBeforeFinish }
        return max(0, quietSecondsBeforeFinish - now.timeIntervalSince(lastActivityAt))
    }

    /// Format mm:ss
    var countdownText: String {
        let totalSeconds = Int(secondsBeforeFinish.rounded())
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    /// Minutes avant un désarmement automatique,
    var minutesBeforeGivingUp: Int {
        guard let armedAt else { return 0 }
        let secondsLeft = secondsBeforeGivingUp - now.timeIntervalSince(armedAt)
        return max(0, Int(secondsLeft / 60))
    }

    /// Ligne de contexte en bas du panneau
    var footnoteText: String? {
        switch state {
        case .idle:
            return nil
        case .waitingForActivity:
            return "Abandon automatique dans \(minutesBeforeGivingUp) min"
        case .chromeWorking:
            guard let firstActivityAt else { return nil }
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return "Demarre a \(timeFormatter.string(from: firstActivityAt)) · \(activityCount) pics"
        }
    }
}
