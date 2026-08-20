import SwiftUI

//Vue à propos
struct AboutView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            header

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                infoBlock(
                    "Utilisation",
                    "Clique sur Armer juste avant de lancer une tâche Claude in Chrome, puis laisse ton Mac travailler. L'app garde la machine éveillée tant que Chrome s'active, et l'endort quand tout est terminé."
                )
                infoBlock(
                    "Comment la détection fonctionne",
                    "Aucune app ne signale qu'une tâche Claude tourne. ClaudeAwake mesure donc le CPU cumulé de Chrome toutes les 10 secondes : au-delà de 15 %, elle considère que le navigateur travaille."
                )
                infoBlock(
                    "Délai de fin",
                    "Un creux ne suffit pas à conclure : chaque pic réarme le compteur. Il faut donc un calme continu pendant tout le délai avant que l'app décide que la tâche est finie."
                )
                infoBlock(
                    "Abandon automatique",
                    "Si tu armes sans jamais lancer de tâche, l'app se désarme seule au bout de 15 minutes plutôt que de bloquer la veille indéfiniment."
                )
                infoBlock(
                    "Limites",
                    "La détection repose sur l'activité de Chrome, pas sur Claude lui-même : une vidéo ou un onglet qui recharge peuvent la déclencher."
                )
            }

            Divider()

            Link("Code source", destination: URL(string: "https://github.com/arthur-olivier/ClaudeAwake")!)
                .font(.caption)
        }
        .padding(20)
        .frame(width: 360)
    }

    // MARK: - En-tete

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 26))
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 1) {
                Text("ClaudeAwake")
                    .font(.title3.weight(.medium))
                Text("Version 1.0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Bloc de texte

    @ViewBuilder
    private func infoBlock(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.medium))
            Text(body)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    AboutView()
}
