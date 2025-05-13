//
//  WeatherResponse.swift
//  WeatherTest
//
//  Created by Alexander Myskin on 13.05.2025.
//

// MARK: - Models
enum WeatherModels {
    struct Request {}

    struct Response {
        let city: String
        let currentTemp: Double
        let conditionIcon: String
        let hourly: [HourlyForecast]
        let daily: [DailyForecast]
    }

    struct ViewModel {
        let city: String
        let currentTemp: String
        let conditionIcon: String
        let hourlyForecast: [HourlyItem]
        let dailyForecast: [DailyItem]
    }

    struct HourlyForecast {
        let time: String
        let temperature: Double
        let iconURL: String
    }

    struct DailyForecast {
        let date: String
        let minTemp: Double
        let maxTemp: Double
        let iconURL: String
    }

    struct HourlyItem {
        let time: String
        let temperature: String
        let iconURL: String
    }

    struct DailyItem {
        let day: String
        let tempRange: String
        let iconURL: String
    }
}
