import Foundation

struct WeatherCityPreset: Identifiable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double

    static let presets: [WeatherCityPreset] = [
        WeatherCityPreset(id: "rio", name: "Rio de Janeiro, RJ", latitude: -22.9068, longitude: -43.1729),
        WeatherCityPreset(id: "sp", name: "São Paulo, SP", latitude: -23.5505, longitude: -46.6333),
        WeatherCityPreset(id: "bh", name: "Belo Horizonte, MG", latitude: -19.9167, longitude: -43.9345),
        WeatherCityPreset(id: "bsb", name: "Brasília, DF", latitude: -15.7975, longitude: -47.8919),
        WeatherCityPreset(id: "cwb", name: "Curitiba, PR", latitude: -25.4284, longitude: -49.2733),
        WeatherCityPreset(id: "poa", name: "Porto Alegre, RS", latitude: -30.0346, longitude: -51.2177),
        WeatherCityPreset(id: "ssa", name: "Salvador, BA", latitude: -12.9714, longitude: -38.5014),
        WeatherCityPreset(id: "rec", name: "Recife, PE", latitude: -8.0476, longitude: -34.8770)
    ]
}

struct WeatherSnapshot: Equatable {
    let cityName: String
    let currentTemp: Int
    let minTemp: Int
    let maxTemp: Int
    let watchConditionCode: UInt8
    let conditionDescription: String
    let fetchedAt: Date
}

@MainActor
final class WeatherService: ObservableObject {
    @Published var isLoading = false
    @Published var currentWeather: WeatherSnapshot?
    @Published var lastError: String?

    func fetchWeather(for city: WeatherCityPreset) async -> WeatherSnapshot? {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(city.latitude)&longitude=\(city.longitude)&current=temperature_2m,weather_code&daily=temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=1"
        guard let url = URL(string: urlString) else {
            lastError = "URL de clima inválida."
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)

            let current = Int(decoded.current.temperature_2m.rounded())
            let maxT = Int((decoded.daily.temperature_2m_max.first ?? decoded.current.temperature_2m).rounded())
            let minT = Int((decoded.daily.temperature_2m_min.first ?? decoded.current.temperature_2m).rounded())
            let mapped = mapWMOCode(decoded.current.weather_code)

            let snapshot = WeatherSnapshot(
                cityName: city.name,
                currentTemp: current,
                minTemp: minT,
                maxTemp: maxT,
                watchConditionCode: mapped.watchCode,
                conditionDescription: mapped.label,
                fetchedAt: Date()
            )
            self.currentWeather = snapshot
            return snapshot
        } catch {
            self.lastError = "Falha ao obter clima: \(error.localizedDescription)"
            return nil
        }
    }

    /// Mapeia códigos meteorológicos WMO para ícones padrão Wearfit (0x01 Sol, 0x02 Nublado, 0x03 Chuva, 0x04 Tempestade).
    private func mapWMOCode(_ wmo: Int) -> (watchCode: UInt8, label: String) {
        switch wmo {
        case 0, 1:
            return (0x01, "Ensolarado")
        case 2, 3, 45, 48:
            return (0x02, "Nublado")
        case 51...67, 80...82:
            return (0x03, "Chuva")
        case 95...99:
            return (0x04, "Tempestade")
        default:
            return (0x02, "Parcialmente Nublado")
        }
    }
}

private struct OpenMeteoResponse: Decodable {
    struct Current: Decodable {
        let temperature_2m: Double
        let weather_code: Int
    }
    struct Daily: Decodable {
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
    }
    let current: Current
    let daily: Daily
}