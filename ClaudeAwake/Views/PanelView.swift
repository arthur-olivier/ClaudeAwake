import SwiftUI
import AppKit
import Combine

struct PanelView: View {

    @ObservedObject var monitor: ChromeMonitor

    @Environment(\.openWindow) private var openWindow

    ///  Rafraichit le compte a rebours chaque seconde
    @State private var currentTime = Date()
    private let everySecond = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            headerSection

            /// On affiche la jauge si on à armer
            if monitor.state.isArmed {
                cpuGaugeSection
            }

            //Affichage du compteur si chrome tourne
            if monitor.state == .chromeWorking {
                countdownSection
            }

            armButton

            if monitor.state.isArmed {
                footnoteSection
            } else {
                settingsSection
                actionsSection
            }
        }
        .padding(14)
        .frame(width: 244)
        .onReceive(everySecond) { tickTime in currentTime = tickTime }
    }

    // MARK: - En-tete: Icône + Titre

    private var headerSection: some View {
        HStack(spacing: 9) {
            SignalIcon(state: monitor.state, size: 20, lineWidth: 1.8)
                .foregroundStyle(iconColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(monitor.state.title)
                    .font(.callout.weight(.medium))
                if let subtitle = monitor.state.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.bottom, 12)
    }

    private var iconColor: Color {
        switch monitor.state {
        case .idle:               return .secondary
        case .waitingForActivity: return .orange
        case .chromeWorking:      return .accentColor
        }
    }

    // MARK: - Jauge CPU

    private var cpuGaugeSection: some View {
        HStack(spacing: 8) {
            ProgressView(value: monitor.gaugeFraction)
                .progressViewStyle(.linear)
                .tint(monitor.isChromeActive ? .accentColor : .secondary)

            Text(String(format: "%.0f%%", monitor.currentCpuPercent))
                .font(.caption.monospacedDigit())
                .foregroundStyle(monitor.isChromeActive ? .primary : .secondary)
                .frame(width: 34, alignment: .trailing)
        }
        .padding(.bottom, 10)
    }

    // MARK: - Compte a rebours

    private var countdownSection: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Veille dans")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(monitor.countdownText)
                .font(.system(.title3, design: .monospaced))
                .monospacedDigit()
        }
        .padding(.bottom, 12)
    }

    // MARK: - Bouton principal

    private var armButton: some View {
        Button {
            monitor.toggle()
        } label: {
            Text(monitor.state.isArmed ? "Désarmer" : "Armer")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    // MARK: - Ligne de contexte

    private var footnoteSection: some View {
        Group {
            if let footnote = monitor.footnoteText {
                Divider().padding(.vertical, 10)
                Text(footnote)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Reglages

    private var settingsSection: some View {
        VStack(spacing: 6) {
            Divider().padding(.vertical, 10)

            HStack {
                Text("Délai de fin")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Menu("\(Int(monitor.quietSecondsBeforeFinish / 60)) min") {
                    Button("3 minutes")  { monitor.quietSecondsBeforeFinish = 180 }
                    Button("5 minutes")  { monitor.quietSecondsBeforeFinish = 300 }
                    Button("10 minutes") { monitor.quietSecondsBeforeFinish = 600 }
                    Button("15 minutes") { monitor.quietSecondsBeforeFinish = 900 }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            HStack {
                Text("Endormir à la fin")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Toggle("", isOn: $monitor.sleepWhenDone)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.mini)
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider().padding(.vertical, 8)
            actionRow("À propos") {
                openWindow(id: "about")
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            actionRow("Quitter") { NSApplication.shared.terminate(nil) }
        }
    }

    @ViewBuilder
    private func actionRow(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 13))
                Spacer()
            }
        }
        .buttonStyle(MenuRowStyle())
    }

    // MARK: - Style de ligne d'un bouton du menu

    /// Surlignage au survol + style du boutton
    private struct MenuRowStyle: ButtonStyle {

        func makeBody(configuration: Configuration) -> some View {
            MenuRow(configuration: configuration)
        }

        // Vue interne : @State n'est pas utilisable directement dans makeBody
        private struct MenuRow: View {

            let configuration: ButtonStyle.Configuration
            @State private var isHovering = false

            var body: some View {
                configuration.label
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .background {
                        if isHovering {
                            MenuHighlight()
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                    }
                    .foregroundStyle(isHovering
                                     ? Color(nsColor: .selectedMenuItemTextColor)
                                     : Color(nsColor: .labelColor))
                    .onHover { hovering in isHovering = hovering }
            }
        }
    }
    
    /// Le surlignage exact des NSMenu : materiau systeme avec vibrance.
    struct MenuHighlight: NSViewRepresentable {

        func makeNSView(context: Context) -> NSVisualEffectView {
            let view = NSVisualEffectView()
            view.material = .selection
            view.blendingMode = .behindWindow
            view.state = .active
            view.isEmphasized = true
            return view
        }

        func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
    }
}

#Preview {
    PanelView(monitor: ChromeMonitor())
}
