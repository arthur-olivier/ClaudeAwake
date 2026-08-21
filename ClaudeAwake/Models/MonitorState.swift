import Foundation

/// Les trois etats possibles de la surveillance
enum MonitorState: Equatable {
    case idle                // veille normale
    case waitingForActivity  // verrou posé, on attend le premier pic
    case chromeWorking       // pic recent, Chrome travaille
}

// MARK: - Affichage

extension MonitorState {

    var isArmed: Bool { self != .idle }

    var title: String {
        switch self {
        case .idle:               return "Inactif"
        case .waitingForActivity: return "En attente"
        case .chromeWorking:      return "Claude in Chrome travaille"
        }
    }

    var subtitle: String? {
        switch self {
        case .idle:               return nil
        case .waitingForActivity: return "Aucune activité détectée"
        case .chromeWorking:      return "Veille suspendue"
        }
    }

    var iconName: String {
        switch self {
        case .idle:               return "waveform.slash"
        case .waitingForActivity: return "waveform"
        case .chromeWorking:      return "waveform.path.ecg"
        }
    }
}
