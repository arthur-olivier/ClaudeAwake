import SwiftUI

// MARK: - Le trace

/// Le trait du signal
/// Trait plat au repos, ondulation en attente, pouls quand ca travaille.
struct SignalShape: Shape {

    let state: MonitorState

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let middle = rect.midY

        switch state {

        case .idle:
            // Un simple trait horizontal
            path.move(to: CGPoint(x: 0, y: middle))
            path.addLine(to: CGPoint(x: width, y: middle))

        case .waitingForActivity:
            // Deux courbes douces : une bosse en haut, une en bas
            path.move(to: CGPoint(x: 0, y: middle))
            path.addQuadCurve(
                to: CGPoint(x: width * 0.5, y: middle),
                control: CGPoint(x: width * 0.25, y: middle - height * 0.40))
            path.addQuadCurve(
                to: CGPoint(x: width, y: middle),
                control: CGPoint(x: width * 0.75, y: middle + height * 0.40))

        case .chromeWorking:
            // Trace type electrocardiogramme : plat, pic haut, pic bas, rebond, plat
            path.move(to: CGPoint(x: 0, y: middle))
            path.addLine(to: CGPoint(x: width * 0.20, y: middle))
            path.addLine(to: CGPoint(x: width * 0.32, y: middle - height * 0.48))
            path.addLine(to: CGPoint(x: width * 0.46, y: middle + height * 0.48))
            path.addLine(to: CGPoint(x: width * 0.57, y: middle - height * 0.22))
            path.addLine(to: CGPoint(x: width * 0.66, y: middle))
            path.addLine(to: CGPoint(x: width, y: middle))
        }

        return path
    }
}

// MARK: - L'icone

struct SignalIcon: View {

    let state: MonitorState
    var size: CGFloat = 17
    var lineWidth: CGFloat = 1.6

    var body: some View {
        SignalShape(state: state)
            .stroke(style: StrokeStyle(
                lineWidth: lineWidth,
                lineCap: .round,
                lineJoin: .round))
            // Le trait plat est volontairement plus discret
            .opacity(state == .idle ? 0.55 : 1)
            .frame(width: size, height: size * 0.75)
    }
}

#Preview {
    HStack(spacing: 24) {
        SignalIcon(state: .idle)
        SignalIcon(state: .waitingForActivity)
        SignalIcon(state: .chromeWorking)
    }
    .padding(30)
}
