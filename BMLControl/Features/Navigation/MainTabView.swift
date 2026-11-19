import SwiftUI
import SwiftData

struct MainTabView: View {
    @ObservedObject var bleManager: BLEManager
    @ObservedObject var syncEngine: BMLSyncEngine
    @ObservedObject var settingsStore: DeviceSettingsStore

    @Query(sort: \DailyActivityRecord.dateKey, order: .reverse) private var dailyRecords: [DailyActivityRecord]
    @Query(sort: \HourlyVitalSample.sampleID, order: .reverse) private var hourlySamples: [HourlyVitalSample]
    @Query(sort: \SleepSegmentRecord.segmentID, order: .reverse) private var sleepSegments: [SleepSegmentRecord]

    @State private var showingPurgeAlert = false

    var body: some View {
        TabView {
            summaryTab
                .tabItem {
                    Label("Resumo", systemImage: "square.grid.2x2.fill")
                }

            HealthChartsView(
                dailyRecords: dailyRecords,
                hourlySamples: hourlySamples,
                sleepSegments: sleepSegments,
                stepGoal: settingsStore.dailyStepGoal
            )
            .tabItem {
                Label("Saúde", systemImage: "heart.text.square.fill")
            }

            watchFacesTab
                .tabItem {
                    Label("Mostradores", systemImage: "applewatch.watchface")
                }

            deviceTab
                .tabItem {
                    Label("Dispositivo", systemImage: "slider.horizontal.3")
                }

            diagnosticsTab
                .tabItem {
                    Label("Dados & BLE", systemImage: "waveform.path.ecg.rectangle")
                }
        }
        .tint(BMLTheme.accentVitality)
    }

    // MARK: - ABA 1: RESUMO (MÓDULO A)
    private var summaryTab: some View {
        let today = dailyRecords.first
        let latestVital = hourlySamples.first(where: { $0.heartRate > 0 })
        let steps = today?.steps ?? 0
        let goal = settingsStore.dailyStepGoal
        let progress = min(1.0, Double(steps) / Double(max(1, goal)))

        return NavigationStack {
            ScrollView {
                VStack(spacing: BMLTheme.cardSpacing) {
                    ConnectionStatusHeader(
                        bleManager: bleManager,
                        syncEngine: syncEngine,
                        settingsStore: settingsStore
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Atividade Diária", systemImage: "figure.walk")
                                .font(BMLTypography.sectionTitle)
                                .foregroundStyle(BMLTheme.accentVitality)
                            Spacer()
                            Text("\(Int(progress * 100))% da meta")
                                .font(BMLTypography.cardLabel)
                                .foregroundStyle(.secondary)
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(steps)")
                                .font(BMLTypography.heroMetric)
                            Text("/ \(goal) passos")
                                .font(BMLTypography.cardLabel)
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: progress)
                            .tint(BMLTheme.accentVitality)

                        HStack {
                            Label(
                                String(format: "%.2f km estimados", today?.estimatedDistanceKm ?? 0.0),
                                systemImage: "map"
                            )
                            Spacer()
                            Label("\(today?.calories ?? 0) kcal", systemImage: "flame.fill")
                                .foregroundStyle(BMLTheme.accentEnergy)
                        }
                        .font(BMLTypography.caption)
                        .foregroundStyle(.secondary)
                    }
                    .bmlCard()

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: BMLTheme.cardSpacing) {
                        StatTileView(
                            title: "Batimentos",
                            value: latestVital.map { "\($0.heartRate)" } ?? "--",
                            unit: "bpm",
                            footnote: latestVital.map { String(format: "Às %02d:00", $0.hour) } ?? "Sem leitura",
                            icon: "heart.fill",
                            accentColor: BMLTheme.accentHeart
                        )

                        StatTileView(
                            title: "Oxigenação",
                            value: latestVital.flatMap { $0.spo2 > 0 ? "\($0.spo2)" : nil } ?? "--",
                            unit: "%",
                            footnote: "SpO2 óptico",
                            icon: "lungs.fill",
                            accentColor: BMLTheme.accentOxygen
                        )

                        StatTileView(
                            title: "Sono Total",
                            value: {
                                let mins = today?.totalSleepMinutes ?? 0
                                return mins > 0 ? "\(mins / 60)h \(String(format: "%02d", mins % 60))m" : "--"
                            }(),
                            unit: "",
                            footnote: "Profundo: \(today?.deepSleepMinutes ?? 0)m",
                            icon: "bed.double.fill",
                            accentColor: BMLTheme.accentSleep
                        )

                        StatTileView(
                            title: "Pressão (Est.)",
                            value: {
                                if let s = latestVital, s.systolicBP > 0, s.diastolicBP > 0 {
                                    return "\(s.systolicBP)/\(s.diastolicBP)"
                                }
                                return "--"
                            }(),
                            unit: "mmHg",
                            footnote: "Referência óptica",
                            icon: "waveform.path.ecg",
                            accentColor: BMLTheme.accentVitality
                        )
                    }

                    if bleManager.isConnected {
                        HStack(spacing: 10) {
                            Button(action: { bleManager.sendSyncData() }) {
                                Label("Sincronizar Dados", systemImage: "arrow.clockwise")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(BMLTheme.accentVitality)

                            Button(action: { bleManager.sendFindWatch(activate: true) }) {
                                Label("Vibrar Relógio", systemImage: "bell.and.waves.left.and.right")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        .font(BMLTypography.sectionTitle)
                    }
                }
                .padding(BMLTheme.screenPadding)
            }
            .background(BMLTheme.backgroundPrimary)
            .navigationTitle("BML Control")
        }
    }

    // MARK: - ABA 3: MOSTRADORES (MÓDULO E)
    private var watchFacesTab: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ContentUnavailableView(
                    "Estúdio de Watch Faces",
                    systemImage: "applewatch.watchface",
                    description: Text("O canal secundário 6E400011 já foi mapeado no hardware. O gerador binário compatível com o kernel YM0242-1 será implementado na Fase 10.")
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BMLTheme.backgroundPrimary)
            .navigationTitle("Mostradores")
        }
    }

    // MARK: - ABA 4: DISPOSITIVO & FUNÇÕES INTELIGENTES (MÓDULOS F, G e H)
    private var deviceTab: some View {
        NavigationStack {
            Form {
                Section("Identificação do Hardware") {
                    LabeledContent("Modelo", value: "BML X Pro Max 5")
                    LabeledContent("Endereço MAC", value: "41:42:75:A4:3F:A2")
                    LabeledContent("Firmware / Kernel", value: "V1.06 • fwk_2.23")
                    LabeledContent("Status BLE", value: bleManager.isConnected ? "Conectado" : "Desconectado")
                }

                Section("Comportamento Validado (Escrita BLE)") {
                    Toggle("Levantar Pulso para Acender (0x77)", isOn: $settingsStore.raiseWristEnabled)
                        .disabled(!bleManager.isConnected)
                        .onChange(of: settingsStore.raiseWristEnabled) { _, newValue in
                            bleManager.sendRaiseWrist(enabled: newValue)
                        }

                    Toggle("Formato 24 Horas (0x7C)", isOn: $settingsStore.is24HourFormat)
                        .disabled(!bleManager.isConnected)
                        .onChange(of: settingsStore.is24HourFormat) { _, newValue in
                            bleManager.sendTimeFormat(is24Hour: newValue)
                        }

                    Stepper(
                        "Meta Diária: \(settingsStore.dailyStepGoal) passos",
                        value: $settingsStore.dailyStepGoal,
                        in: 2000...30000,
                        step: 1000
                    )

                    Button("Aplicar Meta de Passos no Relógio (0x74)") {
                        bleManager.sendStepGoal(settingsStore.dailyStepGoal)
                    }
                    .disabled(!bleManager.isConnected)
                }

                SmartFunctionsSections(bleManager: bleManager, settingsStore: settingsStore)

                Section("Utilitários do Relógio") {
                    Button("Sincronizar Data e Hora Agora (0x93)") {
                        bleManager.sendSyncTime()
                    }
                    .disabled(!bleManager.isConnected)

                    Button("Encontrar Relógio / Vibrar (0x71)") {
                        bleManager.sendFindWatch(activate: true)
                    }
                    .disabled(!bleManager.isConnected)

                    if bleManager.isConnected {
                        Button("Desconectar Relógio", role: .destructive) {
                            bleManager.disconnect()
                        }
                    } else if bleManager.hasSavedWatch {
                        Button("Esquecer Relógio Pareado", role: .destructive) {
                            bleManager.forgetSavedWatch()
                        }
                    }
                }
            }
            .navigationTitle("Dispositivo")
        }
    }

    // MARK: - ABA 5: DADOS, PRIVACIDADE E CONSOLE BLE (MÓDULOS I, J e K)
    private var diagnosticsTab: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BMLTheme.cardSpacing) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Armazenamento Local (SwiftData)", systemImage: "internaldrive.fill")
                            .font(BMLTypography.sectionTitle)
                        Text("Todos os dados ficam salvos exclusivamente no seu iPhone 11, sem nuvem externa.")
                            .font(BMLTypography.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text("Dias: \(syncEngine.totalPersistedDays)")
                            Spacer()
                            Text("Amostras: \(syncEngine.totalPersistedHourlySamples)")
                            Spacer()
                            Text("Sono: \(syncEngine.totalPersistedSleepSegments)")
                        }
                        .font(BMLTypography.cardLabel)
                        .padding(.top, 4)

                        Button("Apagar Histórico Local", role: .destructive) {
                            showingPurgeAlert = true
                        }
                        .font(BMLTypography.cardLabel)
                        .padding(.top, 4)
                    }
                    .bmlCard()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Console Técnico BLE (6E400002 / 6E400003)")
                                .font(BMLTypography.sectionTitle)
                            Spacer()
                            Button("Limpar") {
                                bleManager.clearLogs()
                            }
                            .font(BMLTypography.cardLabel)
                        }

                        if bleManager.logs.isEmpty {
                            Text("Nenhum pacote registrado na sessão atual.")
                                .font(BMLTypography.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                ForEach(bleManager.logs.prefix(60)) { entry in
                                    Text("[\(entry.formattedTime)] \(entry.direction.rawValue) \(entry.message)")
                                        .font(BMLTypography.monoLog)
                                        .foregroundStyle(entry.direction == .error ? BMLTheme.accentHeart : (entry.direction == .tx ? BMLTheme.accentOxygen : .primary))
                                }
                            }
                        }
                    }
                    .bmlCard()
                }
                .padding(BMLTheme.screenPadding)
            }
            .background(BMLTheme.backgroundPrimary)
            .navigationTitle("Dados & Diagnóstico")
            .alert("Apagar todo o histórico?", isPresented: $showingPurgeAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Apagar Tudo", role: .destructive) {
                    syncEngine.purgeAllLocalData()
                }
            } message: {
                Text("Esta ação removerá permanentemente todos os registros de atividades, saúde e sono salvos neste iPhone.")
            }
        }
    }
}