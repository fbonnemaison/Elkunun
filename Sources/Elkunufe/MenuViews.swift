// © 2026 App-Zilla. Licencia MIT.

import ElkunufeCore
import SwiftUI

// MARK: - Menú principal

struct MainMenuView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            FoxImage(size: 128)
            Text("Elkünufe")
                .font(.system(size: 52, weight: .bold, design: .rounded))
            Text("El que guarda las cosas")
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(.bottom, 16)

            if app.progress.completedCount > 0 {
                Button { app.continueCampaign() } label: {
                    Text("Continuar · nivel \(app.progress.nextLevel + 1)")
                }
                .buttonStyle(MenuButtonStyle(prominent: true))
                .keyboardShortcut(.defaultAction)
                Button("Campaña") { app.showCampaign() }
                    .buttonStyle(MenuButtonStyle())
            } else {
                Button("Empezar campaña") { app.playCampaign(0) }
                    .buttonStyle(MenuButtonStyle(prominent: true))
                    .keyboardShortcut(.defaultAction)
            }
            Button("Nivel aleatorio") { app.showRandom() }
                .buttonStyle(MenuButtonStyle())
            Button("Ayuda y créditos") { app.showCredits() }
                .buttonStyle(MenuButtonStyle())
            SettingsLink {
                Text("Ajustes")
            }
            .buttonStyle(MenuButtonStyle())
            Spacer()
        }
        .padding()
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
                            Text(groupName(group))
                                .font(.headline)
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
                    Picker("Dificultad", selection: $difficulty) {
                        Text("Fácil").tag(Difficulty.easy)
                        Text("Media").tag(Difficulty.medium)
                        Text("Difícil").tag(Difficulty.hard)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 320)
                    Button("Crear nivel") { app.playNewRandom(difficulty) }
                        .buttonStyle(MenuButtonStyle(prominent: true))
                        .keyboardShortcut(.defaultAction)
                        .disabled(app.isGenerating)
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
        .onAppear { difficulty = app.lastDifficulty }
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
                    FoxImage(view: .side, size: 110)
                    Text("Elkünufe").font(.largeTitle.weight(.bold))
                    Text("«Elkünufe» significa en mapudungun «el que guarda o deja cosas», del verbo «elkünun» (guardar, dejar). El protagonista es un zorro culpeo, el zorro colorado de los Andes, que vive desde Ecuador hasta Tierra del Fuego.")
                    Text("Colores y formas inspirados con respeto en los textiles mapuches.")
                    Text("Inspirado en el género de empujar cajas creado por Sokoban (Hiroyuki Imabayashi, 1981). Elkünufe es un juego independiente, sin relación con Sokoban ni con sus titulares; sus niveles, gráficos y sonidos son originales.")
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
            Text("Cómo se juega").font(.title2.weight(.bold))
            Text("Lleva cada caja a un destino marcado con un rombo. Cuando todas están en su sitio, el nivel está completo.")
            Label("Solo puedes empujar las cajas, nunca tirar de ellas.", systemImage: "arrow.right.square")
            Label("Solo puedes empujar una caja a la vez.", systemImage: "square.stack")
            Label("Una caja en una esquina ya no se puede sacar: deshaz o reinicia.", systemImage: "exclamationmark.triangle")
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
