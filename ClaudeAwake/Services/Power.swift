import Foundation

/// Appels systeme
enum Power {

    // MARK: - Verrou de veille

    ///  Process qui permet de verouiller la mise en veille
    private static var sleepBlockerProcess: Process?

    static var isBlockingSleep: Bool {
        sleepBlockerProcess?.isRunning ?? false
    }

    /// Lance un process et empêhce l''ordinateur de se mettre en veille
    static func blockSleep() {
        /// Vérification que le process ne tourne pas déjà
        guard sleepBlockerProcess?.isRunning != true else { return }

        let blocker = Process()
        blocker.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        blocker.arguments = ["-i"]   // -i correspond à la veille systeme
        try? blocker.run()

        sleepBlockerProcess = blocker
    }

    /// Arrête le process
    static func allowSleep() {
        // Relache le verrou. N'endort pas : reautorise seulement la veille
        sleepBlockerProcess?.terminate()
        sleepBlockerProcess = nil
    }

    // MARK: - Veille

    /// Force l'endormissement immediat
    static func sleepImmediately() {
        let sleepCommand = Process()
        sleepCommand.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        sleepCommand.arguments = ["sleepnow"]
        try? sleepCommand.run()
    }

    // MARK: - Mesure

    /// Somme du %CPU de tous les process Chrome (un par onglet, d'ou > 100 %)
    static func totalChromeCpuPercent() -> Double {
        let processList = runCommand("/bin/ps", ["-A", "-o", "%cpu,comm"])

        return processList
            .split(separator: "\n")
            // On ne garde que les lignes Chrome
            .filter { line in line.lowercased().contains("google chrome") }
            // Premiere colonne = %CPU
            .compactMap { line in
                let cpuColumn = line.trimmingCharacters(in: .whitespaces)
                    .split(separator: " ", maxSplits: 1)
                    .first
                return Double(cpuColumn ?? "")
            }
            //On additionne
            .reduce(0, +)
    }

    // MARK: - Utilitaire

    /// Lance une commande et recupere sa sortie standard
    private static func runCommand(_ executablePath: String, _ arguments: [String]) -> String {
        let command = Process()
        command.executableURL = URL(fileURLWithPath: executablePath)
        command.arguments = arguments

        let outputPipe = Pipe()
        command.standardOutput = outputPipe

        do { try command.run() } catch { return "" }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        command.waitUntilExit()

        return String(data: outputData, encoding: .utf8) ?? ""
    }
}
