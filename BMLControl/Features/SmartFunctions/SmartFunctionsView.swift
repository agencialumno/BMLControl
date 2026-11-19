import SwiftUI

struct SmartFunctionsSections: View {
    @ObservedObject var bleManager: BLEManager
    @ObservedObject var settingsStore: DeviceSettingsStore
    @StateObject private var weatherService = WeatherService()
    @State private var remoteCameraActive = false

    var body: some View {
        Group {
            notificationsSection
            alarmsSection
            weatherSection
            cameraAndFindPhoneSection
        }
    }

    // MARK: - MÓDULO F: NOTIFICAÇÕES (ANCS + MÁSCARA BLE 0x72)
    private var notificationsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("Requisitos do iOS (ANCS):")
                    .font(BMLTypography.cardLabel)
                Text("1. Em Ajustes > Bluetooth do iPhone 11, toque no (i) ao lado de X5 Pro Max e ative 'Compartilhar Notificações do Sistema'.\n2. Escolha abaixo quais alertas deseja encaminhar e aplique no relógio.")
                    .font(BMLTypography.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            Toggle("Chamadas Recebidas", isOn: $settingsStore.notifyCalls)
            Toggle("WhatsApp", isOn: $settingsStore.notifyWhatsApp)
            Toggle("Instagram", isOn: $settingsStore.notifyInstagram)
            Toggle("Telegram", isOn: $settingsStore.notifyTelegram)
            Toggle("SMS / Mensagens", isOn: $settingsStore.notifySMS)
            Toggle("E-mail e Outros Apps", isOn: $settingsStore.notifyOtherApps)

            Button("Aplicar Notificações no Relógio (0x72)") {
                bleManager.sendNotificationMask(settingsStore.notificationBitmask)
            }
            .disabled(!bleManager.isConnected)
        } header: {
            Text("Notificações Inteligentes (ANCS)")
        }
    }

    // MARK: - MÓDULO G: ALARMES DO RELÓGIO (0x73)
    private var alarmsSection: some View {
        Section {
            ForEach($settingsStore.alarms) { $alarm in
                HStack {
                    DatePicker(
                        "Alarme \(alarm.id + 1)",
                        selection: Binding(
                            get: {
                                Calendar.current.date(bySettingHour: alarm.hour, minute: alarm.minute, second: 0, of: Date()) ?? Date()
                            },
                            set: { newDate in
                                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                alarm.hour = comps.hour ?? alarm.hour
                                alarm.minute = comps.minute ?? alarm.minute
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()

                    Spacer()

                    Toggle("", isOn: $alarm.isEnabled)
                        .labelsHidden()
                }
            }

            Button("Sincronizar Alarmes no Relógio (0x73)") {
                Task {
                    for alarm in settingsStore.alarms {
                        bleManager.sendAlarm(alarm)
                        try? await Task.sleep(nanoseconds: 250_000_000)
                    }
                }
            }
            .disabled(!bleManager.isConnected)
        } header: {
            Text("Alarmes do Relógio")
        }
    }

    // MARK: - MÓDULO G: CLIMA EM TEMPO REAL (0x7E)
    private var weatherSection: some View {
        Section {
            Picker("Cidade", selection: $settingsStore.selectedCityID) {
                ForEach(WeatherCityPreset.presets) { city in
                    Text(city.name).tag(city.id)
                }
            }

            if let weather = weatherService.currentWeather {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(weather.currentTemp)°C • \(weather.conditionDescription)")
                            .font(BMLTypography.sectionTitle)
                        Text("Mín \(weather.minTemp)° / Máx \(weather.maxTemp)°")
                            .font(BMLTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(weather.fetchedAt.formatted(date: .omitted, time: .shortened))
                        .font(BMLTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let error = weatherService.lastError {
                Text(error)
                    .font(BMLTypography.caption)
                    .foregroundStyle(BMLTheme.accentHeart)
            }

            Button {
                Task {
                    if let snapshot = await weatherService.fetchWeather(for: settingsStore.selectedCity),
                       bleManager.isConnected {
                        bleManager.sendWeather(snapshot)
                    }
                }
            } label: {
                HStack {
                    Text(weatherService.isLoading ? "Buscando Clima..." : "Atualizar e Enviar Clima (0x7E)")
                    if weatherService.isLoading {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(weatherService.isLoading)
        } header: {
            Text("Clima (Open-Meteo Gratuito)")
        }
    }

    // MARK: - MÓDULO G: CÂMERA REMOTA (0x79) & LOCALIZAR CELULAR
    private var cameraAndFindPhoneSection: some View {
        Section {
            Toggle("Modo Câmera Remota no Relógio (0x79)", isOn: $remoteCameraActive)
                .disabled(!bleManager.isConnected)
                .onChange(of: remoteCameraActive) { _, active in
                    bleManager.sendRemoteCamera(enabled: active)
                }

            if let lastShot = bleManager.lastRemoteCameraTrigger {
                Label(
                    "Disparo recebido do relógio às \(lastShot.formatted(date: .omitted, time: .standard))",
                    systemImage: "camera.shutter.button.fill"
                )
                .font(BMLTypography.caption)
                .foregroundStyle(BMLTheme.accentVitality)
            }

            if bleManager.isFindingPhoneAlertActive {
                Label("O relógio está chamando este iPhone!", systemImage: "iphone.radiowaves.left.and.right")
                    .font(BMLTypography.cardLabel)
                    .foregroundStyle(BMLTheme.accentEnergy)
            }
        } header: {
            Text("Controle Bidirecional")
        }
    }
}