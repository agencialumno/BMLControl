import SwiftUI
import SwiftData
import Charts

struct HealthChartsView: View {
    let dailyRecords: [DailyActivityRecord]
    let hourlySamples: [HourlyVitalSample]
    let sleepSegments: [SleepSegmentRecord]
    let stepGoal: Int

    @State private var selectedCategory = 0
    @State private var selectedTimeframe: HealthTimeframe = .day
    @State private var anchorDate: Date = Calendar.current.startOfDay(for: Date())

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                Picker("Categoria", selection: $selectedCategory) {
                    Text("Sinais Vitais").tag(0)
                    Text("Atividades").tag(1)
                    Text("Sono").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, BMLTheme.screenPadding)

                HStack(spacing: 10) {
                    Picker("Período", selection: $selectedTimeframe) {
                        ForEach(HealthTimeframe.allCases) { tf in
                            Text(tf.rawValue).tag(tf)
                        }
                    }
                    .pickerStyle(.segmented)

                    periodNavigator
                }
                .padding(.horizontal, BMLTheme.screenPadding)

                ScrollView {
                    VStack(spacing: BMLTheme.cardSpacing) {
                        if selectedCategory == 0 {
                            vitalsChartsContent
                        } else if selectedCategory == 1 {
                            activityChartsContent
                        } else {
                            sleepChartsContent
                        }
                    }
                    .padding(BMLTheme.screenPadding)
                }
            }
            .background(BMLTheme.backgroundPrimary)
            .navigationTitle("Saúde & Corpo")
        }
    }

    private var periodNavigator: some View {
        let stepDays = selectedTimeframe == .day ? 1 : (selectedTimeframe == .week ? 7 : 30)
        let isToday = Calendar.current.isDateInToday(anchorDate)

        return HStack(spacing: 6) {
            Button {
                if let prev = Calendar.current.date(byAdding: .day, value: -stepDays, to: anchorDate) {
                    anchorDate = prev
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                    .padding(7)
                    .background(BMLTheme.surfaceCard, in: Circle())
            }

            Text(HealthAnalyticsEngine.periodTitle(for: selectedTimeframe, anchorDate: anchorDate))
                .font(BMLTypography.cardLabel)
                .lineLimit(1)

            Button {
                if let next = Calendar.current.date(byAdding: .day, value: stepDays, to: anchorDate) {
                    let today = Calendar.current.startOfDay(for: Date())
                    anchorDate = min(next, today)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .padding(7)
                    .background(BMLTheme.surfaceCard, in: Circle())
            }
            .disabled(isToday)
            .opacity(isToday ? 0.35 : 1.0)
        }
    }

    // MARK: - 1. SINAIS VITAIS (FC, SpO2, Pressão)
    private var vitalsChartsContent: some View {
        let points = HealthAnalyticsEngine.buildVitalSeries(
            samples: hourlySamples,
            timeframe: selectedTimeframe,
            anchorDate: anchorDate
        )
        let filteredSamples = filteredVitalSamplesForList

        return VStack(alignment: .leading, spacing: BMLTheme.cardSpacing) {
            Text("Aviso: Leituras ópticas de smartwatches são referências para bem-estar e não substituem equipamentos médicos.")
                .font(BMLTypography.caption)
                .foregroundStyle(.secondary)
                .bmlCard(padding: 12)

            if points.isEmpty {
                ContentUnavailableView(
                    "Sem medições neste período",
                    systemImage: "heart.slash",
                    description: Text("Conecte o BML X Pro Max 5 e sincronize os dados ou navegue para uma data anterior.")
                )
            } else {
                HeartRateChartCard(points: points, timeframe: selectedTimeframe)
                SpO2ChartCard(points: points, timeframe: selectedTimeframe)
                BloodPressureChartCard(points: points, timeframe: selectedTimeframe)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Medições Registradas (\(filteredSamples.count))")
                        .font(BMLTypography.sectionTitle)

                    ForEach(filteredSamples.prefix(30)) { sample in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(sample.dateKey) • \(String(format: "%02d:00", sample.hour))")
                                    .font(BMLTypography.cardLabel)
                                if sample.systolicBP > 0 && sample.diastolicBP > 0 {
                                    Text("Pressão Est.: \(sample.systolicBP)/\(sample.diastolicBP) mmHg")
                                        .font(BMLTypography.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            HStack(spacing: 12) {
                                if sample.heartRate > 0 {
                                    Label("\(sample.heartRate) bpm", systemImage: "heart.fill")
                                        .foregroundStyle(BMLTheme.accentHeart)
                                }
                                if sample.spo2 > 0 {
                                    Label("\(sample.spo2)%", systemImage: "lungs.fill")
                                        .foregroundStyle(BMLTheme.accentOxygen)
                                }
                            }
                            .font(BMLTypography.cardLabel)
                        }
                        .bmlCard(padding: 12)
                    }
                }
            }
        }
    }

    private var filteredVitalSamplesForList: [HourlyVitalSample] {
        let calendar = Calendar.current
        let daysBack = selectedTimeframe == .day ? 0 : (selectedTimeframe == .week ? 6 : 29)
        let startDate = calendar.date(byAdding: .day, value: -daysBack, to: anchorDate) ?? anchorDate
        let endDate = calendar.date(byAdding: .day, value: 1, to: anchorDate) ?? anchorDate

        return hourlySamples.filter { $0.timestamp >= startDate && $0.timestamp < endDate }
    }

    // MARK: - 2. ATIVIDADES (Passos, Calorias, Distância)
    private var activityChartsContent: some View {
        let points = HealthAnalyticsEngine.buildActivitySeries(
            dailyRecords: dailyRecords,
            hourlySamples: hourlySamples,
            timeframe: selectedTimeframe,
            anchorDate: anchorDate
        )
        let totalSteps = points.reduce(0) { $0 + $1.steps }
        let totalKcal = points.reduce(0) { $0 + $1.calories }
        let totalKm = points.reduce(0.0) { $0 + $1.distanceKm }

        return VStack(alignment: .leading, spacing: BMLTheme.cardSpacing) {
            HStack(spacing: 10) {
                StatTileView(
                    title: "Passos",
                    value: "\(totalSteps)",
                    unit: "",
                    footnote: selectedTimeframe == .day ? "Acumulado no dia" : "Total no período",
                    icon: "figure.walk",
                    accentColor: BMLTheme.accentVitality
                )
                StatTileView(
                    title: "Energia",
                    value: "\(totalKcal)",
                    unit: "kcal",
                    footnote: String(format: "%.2f km estimados", totalKm),
                    icon: "flame.fill",
                    accentColor: BMLTheme.accentEnergy
                )
            }

            if points.allSatisfy({ $0.steps == 0 }) {
                ContentUnavailableView(
                    "Sem passos registrados no período",
                    systemImage: "figure.walk",
                    description: Text("Sincronize seu relógio para visualizar a distribuição de atividade.")
                )
            } else {
                StepsActivityChartCard(
                    points: points,
                    timeframe: selectedTimeframe,
                    stepGoal: stepGoal
                )
            }
        }
    }

    // MARK: - 3. SONO (Profundo vs. Leve)
    private var sleepChartsContent: some View {
        let points = HealthAnalyticsEngine.buildSleepSeries(
            dailyRecords: dailyRecords,
            timeframe: selectedTimeframe,
            anchorDate: anchorDate
        )
        let totalDeep = points.reduce(0) { $0 + $1.deepMinutes }
        let totalLight = points.reduce(0) { $0 + $1.lightMinutes }
        let totalAll = totalDeep + totalLight

        return VStack(alignment: .leading, spacing: BMLTheme.cardSpacing) {
            HStack(spacing: 10) {
                StatTileView(
                    title: "Sono Total",
                    value: totalAll > 0 ? "\(totalAll / 60)h \(String(format: "%02d", totalAll % 60))m" : "--",
                    unit: "",
                    footnote: "Profundo: \(totalDeep)m",
                    icon: "bed.double.fill",
                    accentColor: BMLTheme.accentSleep
                )
                StatTileView(
                    title: "Sono Leve",
                    value: totalLight > 0 ? "\(totalLight / 60)h \(String(format: "%02d", totalLight % 60))m" : "--",
                    unit: "",
                    footnote: totalAll > 0 ? "\(Int((Double(totalDeep) / Double(totalAll)) * 100))% profundo" : "Sem dados",
                    icon: "moon.zzz.fill",
                    accentColor: BMLTheme.accentOxygen
                )
            }

            if !points.isEmpty {
                SleepStagesChartCard(points: points)
            }

            if sleepSegments.isEmpty {
                ContentUnavailableView(
                    "Sem blocos detalhados de sono",
                    systemImage: "moon.stars",
                    description: Text("Os intervalos de sono profundo e leve sincronizados aparecerão listados aqui.")
                )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Blocos Registrados")
                        .font(BMLTypography.sectionTitle)

                    ForEach(sleepSegments.prefix(25)) { segment in
                        HStack {
                            Image(systemName: segment.isDeepSleep ? "moon.stars.fill" : "moon.fill")
                                .foregroundStyle(segment.isDeepSleep ? BMLTheme.accentSleep : BMLTheme.accentOxygen)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(segment.isDeepSleep ? "Sono Profundo" : "Sono Leve")
                                    .font(BMLTypography.cardLabel)
                                Text(segment.startTimestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(BMLTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(segment.durationMinutes) min")
                                .font(BMLTypography.compactMetric)
                        }
                        .bmlCard(padding: 12)
                    }
                }
            }
        }
    }
}

// MARK: - Subcomponentes de Gráficos

private struct HeartRateChartCard: View {
    let points: [VitalChartPoint]
    let timeframe: HealthTimeframe

    var body: some View {
        let valid = points.filter { $0.avgHeartRate > 0 }
        let avg = valid.isEmpty ? 0 : Int(valid.map(\.avgHeartRate).reduce(0, +) / Double(valid.count))
        let minVal = valid.map(\.minHeartRate).min() ?? 0
        let maxVal = valid.map(\.maxHeartRate).max() ?? 0
        let strideStep = timeframe == .month ? 5 : 1
        let xLabels = valid.enumerated().compactMap { $0.offset % strideStep == 0 ? $0.element.label : nil }

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Frequência Cardíaca", systemImage: "heart.fill")
                    .font(BMLTypography.sectionTitle)
                    .foregroundStyle(BMLTheme.accentHeart)
                Spacer()
                Text("Média: \(avg) bpm")
                    .font(BMLTypography.cardLabel)
                    .foregroundStyle(.secondary)
            }

            Text("Mín: \(minVal) bpm • Máx: \(maxVal) bpm")
                .font(BMLTypography.caption)
                .foregroundStyle(.secondary)

            Chart(valid) { item in
                LineMark(
                    x: .value("Período", item.label),
                    y: .value("BPM", item.avgHeartRate)
                )
                .foregroundStyle(BMLTheme.accentHeart)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Período", item.label),
                    y: .value("BPM", item.avgHeartRate)
                )
                .foregroundStyle(BMLTheme.accentHeart)
            }
            .chartYScale(domain: 40...180)
            .chartXAxis {
                AxisMarks(values: xLabels) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartPlotStyle { plotArea in
                plotArea.clipped()
            }
            .frame(height: 170)
        }
        .bmlCard()
    }
}

private struct SpO2ChartCard: View {
    let points: [VitalChartPoint]
    let timeframe: HealthTimeframe

    var body: some View {
        let valid = points.filter { $0.avgSpO2 > 0 }
        let avg = valid.isEmpty ? 0 : Int(valid.map(\.avgSpO2).reduce(0, +) / Double(valid.count))
        let strideStep = timeframe == .month ? 5 : 1
        let xLabels = valid.enumerated().compactMap { $0.offset % strideStep == 0 ? $0.element.label : nil }

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Oxigenação (SpO2)", systemImage: "lungs.fill")
                    .font(BMLTypography.sectionTitle)
                    .foregroundStyle(BMLTheme.accentOxygen)
                Spacer()
                Text("Média: \(avg)%")
                    .font(BMLTypography.cardLabel)
                    .foregroundStyle(.secondary)
            }

            Chart(valid) { item in
                BarMark(
                    x: .value("Período", item.label),
                    yStart: .value("Base", 85),
                    yEnd: .value("SpO2", max(85, min(100, item.avgSpO2)))
                )
                .foregroundStyle(BMLTheme.accentOxygen.gradient)
                .cornerRadius(4)
            }
            .chartYScale(domain: 85...100)
            .chartXAxis {
                AxisMarks(values: xLabels) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartPlotStyle { plotArea in
                plotArea.clipped()
            }
            .frame(height: 155)
        }
        .bmlCard()
    }
}

private struct BloodPressureChartCard: View {
    let points: [VitalChartPoint]
    let timeframe: HealthTimeframe

    var body: some View {
        let valid = points.filter { $0.avgSystolic > 0 && $0.avgDiastolic > 0 }
        let strideStep = timeframe == .month ? 5 : 1
        let xLabels = valid.enumerated().compactMap { $0.offset % strideStep == 0 ? $0.element.label : nil }

        Group {
            if !valid.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Pressão Arterial (Referência Óptica)", systemImage: "waveform.path.ecg")
                        .font(BMLTypography.sectionTitle)
                        .foregroundStyle(BMLTheme.accentVitality)

                    Chart(valid) { item in
                        PointMark(
                            x: .value("Período", item.label),
                            y: .value("Sistólica", item.avgSystolic)
                        )
                        .foregroundStyle(BMLTheme.accentHeart)

                        PointMark(
                            x: .value("Período", item.label),
                            y: .value("Diastólica", item.avgDiastolic)
                        )
                        .foregroundStyle(BMLTheme.accentOxygen)
                    }
                    .chartYScale(domain: 50...180)
                    .chartXAxis {
                        AxisMarks(values: xLabels) { _ in
                            AxisGridLine()
                            AxisValueLabel()
                        }
                    }
                    .chartPlotStyle { plotArea in
                        plotArea.clipped()
                    }
                    .frame(height: 150)

                    HStack(spacing: 16) {
                        Label("Sistólica", systemImage: "circle.fill")
                            .foregroundStyle(BMLTheme.accentHeart)
                        Label("Diastólica", systemImage: "circle.fill")
                            .foregroundStyle(BMLTheme.accentOxygen)
                    }
                    .font(BMLTypography.caption)
                }
                .bmlCard()
            }
        }
    }
}

private struct StepsActivityChartCard: View {
    let points: [ActivityChartPoint]
    let timeframe: HealthTimeframe
    let stepGoal: Int

    var body: some View {
        let strideStep = timeframe == .month ? 5 : 1
        let xLabels = points.enumerated().compactMap { $0.offset % strideStep == 0 ? $0.element.label : nil }

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(timeframe == .day ? "Passos por Hora" : "Passos por Dia", systemImage: "chart.bar.fill")
                    .font(BMLTypography.sectionTitle)
                    .foregroundStyle(BMLTheme.accentVitality)
                Spacer()
                if timeframe != .day {
                    Text("Meta: \(stepGoal)")
                        .font(BMLTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Chart {
                ForEach(points) { item in
                    BarMark(
                        x: .value("Período", item.label),
                        y: .value("Passos", item.steps)
                    )
                    .foregroundStyle(BMLTheme.accentVitality.gradient)
                    .cornerRadius(4)
                }

                if timeframe != .day {
                    RuleMark(y: .value("Meta", stepGoal))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(BMLTheme.accentEnergy)
                }
            }
            .chartXAxis {
                AxisMarks(values: xLabels) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 190)
        }
        .bmlCard()
    }
}

private struct SleepStagesChartCard: View {
    let points: [SleepChartPoint]

    var body: some View {
        let strideStep = points.count > 10 ? 5 : 1
        let xLabels = points.enumerated().compactMap { $0.offset % strideStep == 0 ? $0.element.label : nil }

        VStack(alignment: .leading, spacing: 10) {
            Label("Distribuição de Sono (Minutos)", systemImage: "moon.fill")
                .font(BMLTypography.sectionTitle)
                .foregroundStyle(BMLTheme.accentSleep)

            Chart(points) { item in
                BarMark(
                    x: .value("Data", item.label),
                    y: .value("Profundo", item.deepMinutes)
                )
                .foregroundStyle(BMLTheme.accentSleep)

                BarMark(
                    x: .value("Data", item.label),
                    y: .value("Leve", item.lightMinutes)
                )
                .foregroundStyle(BMLTheme.accentOxygen)
            }
            .chartXAxis {
                AxisMarks(values: xLabels) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 170)

            HStack(spacing: 16) {
                Label("Sono Profundo", systemImage: "square.fill")
                    .foregroundStyle(BMLTheme.accentSleep)
                Label("Sono Leve", systemImage: "square.fill")
                    .foregroundStyle(BMLTheme.accentOxygen)
            }
            .font(BMLTypography.caption)
        }
        .bmlCard()
    }
}