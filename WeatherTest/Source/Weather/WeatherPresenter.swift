//
//  WeatherPresenter.swift
//  WeatherTest
//
//  Created by Alexander Myskin on 13.05.2025.
//

// MARK: - Presenter
import Foundation

protocol WeatherPresentationLogic: AnyObject {
    func presentWeather(response: WeatherModels.Response)
    func presentError(message: String)
    func setLoading(_ isLoading: Bool)
    func presentLocationDenied()
}

final class WeatherPresenter: WeatherPresentationLogic {
    weak var viewController: WeatherDisplayLogic?

    // MARK: - WeatherPresentationLogic

    func presentWeather(response: WeatherModels.Response) {
        let hourly = response.hourly.map {
            WeatherModels.HourlyItem(
                time: $0.time,
                temperature: "\(Int($0.temperature))°",
                iconURL: $0.iconURL
            )
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"

        let daily = response.daily.map {
            let date = dateFormatter.date(from: $0.date) ?? Date()
            let dayName = dayFormatter.string(from: date).capitalized
            return WeatherModels.DailyItem(
                day: dayName,
                tempRange: "\(Int($0.minTemp))° / \(Int($0.maxTemp))°",
                iconURL: $0.iconURL
            )
        }

        let viewModel = WeatherModels.ViewModel(
            city: response.city,
            currentTemp: "\(Int(response.currentTemp))°",
            conditionIcon: response.conditionIcon,
            hourlyForecast: hourly,
            dailyForecast: daily
        )

        Task { @MainActor in
            viewController?.displayWeather(viewModel: viewModel)
        }
    }

    func presentError(message: String) {
        Task { @MainActor in
            viewController?.displayError(message: message)
        }
    }

    func setLoading(_ isLoading: Bool) {
        Task { @MainActor in
            viewController?.setLoading(isLoading)
        }
    }

    func presentLocationDenied() {
        Task { @MainActor in
            viewController?.showLocationDeniedAlert()
        }
    }
}
