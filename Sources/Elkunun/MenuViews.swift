// © 2026 App-Zilla. Licencia MIT.

import ElkununCore
import SwiftUI

// MARK: - Menú principal

struct MainMenuView: View {
    @Environment(AppModel.self) private var app
    @State private var confirmStartOver = false

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            FoxPortrait(size: 160)
            Text("Elkünun")
                .font(.pixel(48))
            Text("Poner cada cosa en su lugar")
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(.bottom, 14)

            if app.canContinue {
                VStack(spacing: 4) {
                    Button { app.continuePlaying() } label: { Text(app.continueTitle) }
                        .buttonStyle(MenuButtonStyle(prominent: true))
                        .keyboardShortcut(.defaultAction)
                    if let detail = app.continueDetail {
                        Text(detail)
                            .font(.callout)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 4)
                Button("Empezar de cero") { confirmStartOver = true }
                    .buttonStyle(MenuButtonStyle())
            } else {
                Button("Empezar campaña") { app.playCampaign(0) }
                    .buttonStyle(MenuButtonStyle(prominent: true))
                    .keyboardShortcut(.defaultAction)
            }
            Button("Mejores puntajes") { app.showScores() }
                .buttonStyle(MenuButtonStyle())

            HStack(spacing: 18) {
                Button("Elegir nivel") { app.showCampaign() }
                Button("Nivel aleatorio") { app.showRandom() }
                Button("Ayuda y créditos") { app.showCredits() }
                SettingsLink { Text("Ajustes") }
            }
            .buttonStyle(.borderless)
            .font(.callout.weight(.medium))
            .padding(.top, 10)
            Spacer()
        }
        .padding()
        .confirmationDialog("¿Empezar la campaña desde el nivel 1?", isPresented: $confirmStartOver) {
            Button("Empezar de cero") { app.startOver() }
        } message: {
            Text("Se descarta la partida en curso. Tus mejores puntajes y los niveles desbloqueados se conservan; para borrarlo todo, usa Ajustes › Borrar progreso.")
        }
    }
}

// MARK: - Mejores puntajes

struct BestScoresView: View {
    @Environment(AppModel.self) private var app

    private struct Row: Identifiable {
        let id: Int
        let record: CampaignProgress.Record
        let optimal: Int
    }

    private var rows: [Row] {
        app.progress.records.keys.sorted().compactMap { i in
            app.progress.records[i].map { Row(id: i, record: $0, optimal: Campaign.entries[i].optimalPushes) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Mejores puntajes") { app.showMenu() }
            let progress = app.progress
            HStack(spacing: 28) {
                Label("Completados: \(progress.completedCount) de \(Campaign.levelCount)", systemImage: "checkmark.circle")
                Label("Con el mínimo de empujes: \(progress.optimalCount)", systemImage: "star.fill")
                Label("Tiempo total: \(formatTime(TimeInterval(progress.totalBestSeconds)))", systemImage: "stopwatch")
            }
            .font(.callout)
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .padding(.bottom, 12)

            if rows.isEmpty {
                Spacer()
                Text("Todavía no has completado ningún nivel.")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                Table(rows) {
                    TableColumn("Nivel") { row in
                        Text("\(row.id + 1)").monospacedDigit()
                    }
                    .width(60)
                    TableColumn("Movimientos") { row in
                        Text("\(row.record.bestMoves)").monospacedDigit()
                    }
                    TableColumn("Empujes") { row in
                        HStack(spacing: 4) {
                            Text("\(row.record.bestPushes)").monospacedDigit()
                            if row.record.bestPushes <= row.optimal {
                                Image(systemName: "star.fill").foregroundStyle(Palette.red)
                                    .accessibilityLabel(Text("Mínimo de empujes"))
                            }
                        }
                    }
                    TableColumn("Mínimo posible") { row in
                        Text("\(row.optimal)").monospacedDigit().foregroundStyle(.secondary)
                    }
                    TableColumn("Mejor tiempo") { row in
                        Text(row.record.bestSeconds.map { formatTime(TimeInterval($0)) } ?? "—").monospacedDigit()
                    }
                    TableColumn("") { row in
                        Button("Jugar") { app.playCampaign(row.id) }
                            .buttonStyle(.borderless)
                    }
                    .width(60)
                }
                .frame(maxWidth: 720)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Selector de la campaña

struct CampaignSelectView: View {
    @Environment(AppModel.self) private var app
    private let columns = Array(repeating: GridItem(.flexible(minimum: 44, maximum: 64), spacing: 10), count: 10)

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Campaña") { app.showMenu() }
            Text("Completados: \(app.progress.completedCount) de \(Campaign.levelCount)")
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(0..<Campaign.groupCount, id: \.self) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Text(groupName(group))
                                    .font(.headline)
                                if !app.progress.isGroupUnlocked(group) {
                                    Label("Completa los niveles \(group * 10 - 9)–\(group * 10) para desbloquearlos",
                                          systemImage: "lock.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(0..<Campaign.levelsPerGroup, id: \.self) { k in
                                    LevelCell(index: group * Campaign.levelsPerGroup + k)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
        }
        .background { LevelSelectBackdrop() }
    }

    private func groupName(_ group: Int) -> LocalizedStringKey {
        "Niveles \(group * 10 + 1)–\(group * 10 + 10)"
    }
}

private struct LevelCell: View {
    let index: Int
    @Environment(AppModel.self) private var app

    var body: some View {
        let progress = app.progress
        let unlocked = progress.isUnlocked(index)
        let completed = progress.isCompleted(index)
        let optimal = progress.isOptimal(index)
        Button { app.playCampaign(index) } label: {
            VStack(spacing: 2) {
                if unlocked {
                    Text("\(index + 1)")
                        .font(.headline.monospacedDigit())
                } else {
                    Image(systemName: "lock.fill")
                }
                Image(systemName: optimal ? "star.fill" : completed ? "checkmark" : "circle")
                    .font(.caption2)
                    .opacity(completed ? 1 : 0)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(background(unlocked: unlocked, completed: completed),
                        in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(completed ? Palette.white : Color.primary)
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
        .opacity(unlocked ? 1 : 0.45)
        .help(help(completed: completed))
        .accessibilityLabel(Text(accessibility(unlocked: unlocked, completed: completed, optimal: optimal)))
    }

    private func background(unlocked: Bool, completed: Bool) -> Color {
        completed ? Palette.red : Color.primary.opacity(unlocked ? 0.1 : 0.05)
    }

    private func help(completed: Bool) -> String {
        guard let r = app.progress.records[index] else { return "" }
        return String(localized: "Mejor: \(r.bestMoves) movimientos, \(r.bestPushes) empujes (mínimo \(Campaign.entries[index].optimalPushes))")
    }

    private func accessibility(unlocked: Bool, completed: Bool, optimal: Bool) -> String {
        if !unlocked { return String(localized: "Nivel \(index + 1), bloqueado") }
        if optimal { return String(localized: "Nivel \(index + 1), completado con el mínimo de empujes") }
        if completed { return String(localized: "Nivel \(index + 1), completado") }
        return String(localized: "Nivel \(index + 1)")
    }
}

// MARK: - Nivel aleatorio

struct RandomLevelView: View {
    @Environment(AppModel.self) private var app
    @State private var codeText = ""
    @State private var difficulty: Difficulty = .easy

    private var parsedCode: LevelCode? { LevelCode(codeText) }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Nivel aleatorio") { app.showMenu() }
            Spacer()
            VStack(spacing: 28) {
                VStack(spacing: 12) {
                    Text("Elige la dificultad").font(.headline)
                    HStack(spacing: 8) {
                        ForEach(Difficulty.allCases, id: \.self) { d in
                            DifficultyButton(difficulty: d, selected: difficulty == d,
                                             unlocked: app.progress.isUnlocked(d)) { difficulty = d }
                        }
                    }
                    Text(difficultyCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(height: 16)
                    Button("Crear nivel") { app.playNewRandom(difficulty) }
                        .buttonStyle(MenuButtonStyle(prominent: true))
                        .keyboardShortcut(.defaultAction)
                        .disabled(app.isGenerating || !app.progress.isUnlocked(difficulty))
                }

                Divider().frame(width: 320)

                VStack(spacing: 12) {
                    Text("¿Tienes un código?").font(.headline)
                    TextField("Ej.: 2-9F3A0C1D", text: $codeText)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3.monospaced())
                        .multilineTextAlignment(.center)
                        .frame(width: 220)
                        .onSubmit { if let parsedCode { app.playRandom(parsedCode) } }
                    Button("Jugar código") { if let parsedCode { app.playRandom(parsedCode) } }
                        .buttonStyle(MenuButtonStyle())
                        .disabled(parsedCode == nil || app.isGenerating)
                }

                Group {
                    if app.isGenerating {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text("Construyendo el almacén…")
                        }
                    } else if let error = app.generationError {
                        Text(error).foregroundStyle(Palette.red)
                    } else {
                        Text(" ")
                    }
                }
                .frame(height: 24)
            }
            Spacer()
        }
        .onAppear {
            difficulty = app.progress.isUnlocked(app.lastDifficulty) ? app.lastDifficulty : .easy
        }
    }

    private var difficultyCaption: String {
        switch difficulty {
        case .easy: String(localized: "2 cajas, como los niveles 1–20")
        case .medium: String(localized: "3 cajas, como los niveles 21–40")
        case .hard: String(localized: "4 cajas, como los niveles 41–60")
        }
    }
}

/// Botón de dificultad: con candado si aún no se ha desbloqueado en la campaña.
private struct DifficultyButton: View {
    let difficulty: Difficulty
    let selected: Bool
    let unlocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if !unlocked { Image(systemName: "lock.fill").font(.caption) }
                Text(title)
            }
            .font(.body.weight(.semibold))
            .frame(width: 104, height: 34)
            .background(selected && unlocked ? Palette.red : Color.primary.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(selected && unlocked ? Palette.white : Color.primary)
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
        .opacity(unlocked ? 1 : 0.45)
        .help(unlocked ? Text("") : Text(AppModel.lockedMessage(difficulty)))
        .accessibilityLabel(Text(title))
        .accessibilityValue(unlocked ? Text(selected ? "Seleccionada" : "") : Text("Bloqueada"))
    }

    private var title: LocalizedStringKey {
        switch difficulty {
        case .easy: "Fácil"
        case .medium: "Media"
        case .hard: "Difícil"
        }
    }
}

// MARK: - Créditos

struct CreditsView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Ayuda y créditos") { app.showMenu() }
            ScrollView {
                VStack(spacing: 18) {
                    HelpSection()
                    Divider()
                    FoxImage(view: .side, size: 112)
                    Text("Elkünun").font(.pixel(32))
                    Text("«Elkünun» es un verbo en mapudungun que significa ubicar, poner, colocar, dejar puesto (también se escribe «elkünün»). Es justo lo que hace el protagonista: dejar cada caja en su lugar. Es un zorro culpeo, el zorro colorado de los Andes, que vive desde Ecuador hasta Tierra del Fuego.")
                    Text("Colores y formas inspirados con respeto en los textiles mapuches.")
                    Text("Inspirado en el género de empujar cajas creado por Sokoban (Hiroyuki Imabayashi, 1981). Elkünun es un juego independiente, sin relación con Sokoban ni con sus titulares; sus niveles, gráficos y sonidos son originales.")
                    Text("Los niveles se generan por procedimiento con un método de plantillas basado en el trabajo de Joshua Taylor e Ian Parberry (2011).")
                    Divider()
                    Text("Creado por App-Zilla").font(.headline)
                    Text("Código abierto con licencia MIT · © 2026 App-Zilla")
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

/// Reglas y controles.
private struct HelpSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cómo se juega").font(.pixel(20))
            Text("Lleva cada caja a un destino marcado con un rombo. Cuando todas están en su sitio, el nivel está completo.")
            Label("Solo puedes empujar las cajas, nunca tirar de ellas.", systemImage: "arrow.right.square")
            Label("Solo puedes empujar una caja a la vez.", systemImage: "square.stack")
            Label("Una caja en un fondo de saco (una esquina o una pared sin destino) ya no se puede sacar y se marca con «!»: deshaz o reinicia.", systemImage: "exclamationmark.circle.fill")
            Text("Controles").font(.headline).padding(.top, 6)
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                GridRow { Text("Flechas o W A S D"); Text("Mover") }
                GridRow { Text("Clic en una casilla"); Text("Caminar hasta ella") }
                GridRow { Text("Z  ·  ⇧Z"); Text("Deshacer · Rehacer") }
                GridRow { Text("R"); Text("Reiniciar el nivel") }
                GridRow { Text("H"); Text("Pista") }
                GridRow { Text("Esc"); Text("Pausa") }
            }
            .font(.callout)
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Fondo de la selección de nivel: el zorro eligiendo piso en el panel de un ascensor,
/// muy tenue sobre el color de fondo. La imagen es una máscara (el dibujo en el canal alfa)
/// que se tiñe de claro en modo oscuro y de oscuro en modo claro.
struct LevelSelectBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Image("LevelSelectFox")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(colorScheme == .dark ? Palette.white : Palette.black)
            .opacity(colorScheme == .dark ? 0.09 : 0.07)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .clipped()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
