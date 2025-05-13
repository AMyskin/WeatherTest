//
//  WeatherInteractor.swift
//  WeatherTest
//
//  Created by Alexander Myskin on 13.05.2025.
//

import Foundation
import CoreLocation

// MARK: - Interactor
protocol WeatherBusinessLogic {
    func fetchWeather()
    func setLoading()
}

final class WeatherInteractor: WeatherBusinessLogic {
    var presenter: WeatherPresentationLogic?
    var weatherService: WeatherServiceProtocol?
    var locationService: LocationServiceProtocol?

    private var isFirstLaunch: Bool = true

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    func filterHourlyForecast(
        forecastDays: [ForecastDay],
        currentDate: Date,
        timeZone: TimeZone
    ) -> [Hour] {
        let calendar = Calendar.current
        var result = [Hour]()

        let currentDay = forecastDays.first { day in
            guard let dayDate = dateFormatter.date(from: day.date + " 00:00") else { return false }
            return calendar.isDate(dayDate, inSameDayAs: currentDate, in: timeZone)
        }

        if let currentDay = currentDay {
            let currentHour = calendar.component(.hour, from: currentDate, in: timeZone)
            let filtered = currentDay.hour.filter { hour in
                guard let hourDate = dateFormatter.date(from: hour.time) else { return false }
                let hourValue = calendar.component(.hour, from: hourDate, in: timeZone)
                return hourValue >= currentHour
            }
            result.append(contentsOf: filtered)
        }

        if let currentIndex = forecastDays.firstIndex(where: {
            calendar.isDate(dateFormatter.date(from: $0.date + " 00:00")!, inSameDayAs: currentDate, in: timeZone)
        }), currentIndex + 1 < forecastDays.count {
            result.append(contentsOf: forecastDays[currentIndex + 1].hour)
        }

        return result
    }

    func formatHourString(_ timeString: String, timeZone: TimeZone) -> String {
        guard let date = dateFormatter.date(from: timeString) else {
            return String(timeString.split(separator: " ").last ?? "")
        }

        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH"
        return formatter.string(from: date)
    }

    // MARK: - WeatherBusinessLogic

    func setLoading() {
        presenter?.setLoading(true)
    }

    func fetchWeather() {
        Task {
            if locationService?.shouldShowSettingsAlert() == true && isFirstLaunch {
                presenter?.presentLocationDenied()
                isFirstLaunch = false
                return
            }

            let coordinate = await locationService?.getCurrentLocation() ??
            CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6176) // Москва по умолчанию

            do {
                guard let weatherService else {
                    presenter?.presentError(message: "Weather service not initialized")
                    return
                }

                async let current = weatherService.fetchCurrentWeather(lat: coordinate.latitude, lon: coordinate.longitude)
                async let forecast = weatherService.fetchForecast(lat: coordinate.latitude, lon: coordinate.longitude)

                let (currentWeather, forecastWeather) = try await (current, forecast)

                guard let tz = TimeZone(identifier: currentWeather.location.tz_id) else {
                    presenter?.presentError(message: "Invalid timezone")
                    return
                }

                let filteredHours = filterHourlyForecast(
                    forecastDays: forecastWeather.forecast.forecastday,
                    currentDate: Date(),
                    timeZone: tz
                )

                let hourlyData = filteredHours.map {
                    WeatherModels.HourlyForecast(
                        time: formatHourString($0.time, timeZone: tz),
                        temperature: $0.temp_c,
                        iconURL: $0.condition.icon
                    )
                }

                let dailyData = forecastWeather.forecast.forecastday.map {
                    WeatherModels.DailyForecast(
                        date: $0.date,
                        minTemp: $0.day.mintemp_c,
                        maxTemp: $0.day.maxtemp_c,
                        iconURL: $0.day.condition.icon
                    )
                }

                let response = WeatherModels.Response(
                    city: currentWeather.location.name,
                    currentTemp: currentWeather.current.temp_c,
                    conditionIcon: currentWeather.current.condition.icon,
                    hourly: hourlyData,
                    daily: dailyData
                )

                presenter?.presentWeather(response: response)
            } catch let error as APIError {
                presenter?.presentError(message: "\(error.localizedDescription)")
            } catch {
                presenter?.presentError(message: "Что-то пошло не так... Попробуйте еще раз")
            }

            presenter?.setLoading(false)
        }
    }
}
