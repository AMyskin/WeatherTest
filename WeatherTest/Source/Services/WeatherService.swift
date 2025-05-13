//
//  WeatherService.swift
//  WeatherTest
//
//  Created by Alexander Myskin on 13.05.2025.
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case httpError(statusCode: Int)
    case apiError(message: String)
    case invalidResponse
    case decodingError
    case unknownError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL адрес"
        case .httpError(let statusCode):
            return "Ошибка сервера: \(statusCode)"
        case .apiError(let message):
            return message
        case .invalidResponse:
            return "Некорректный ответ от сервера"
        case .decodingError:
            return "Ошибка обработки данных"
        case .unknownError:
            return "Неизвестная ошибка"
        }
    }
}

protocol WeatherServiceProtocol {
    func fetchCurrentWeather(lat: Double, lon: Double) async throws -> CurrentWeatherResponse
    func fetchForecast(lat: Double, lon: Double) async throws -> ForecastWeatherResponse
}

final class WeatherAPIService: WeatherServiceProtocol {
    private let apiKey = "fa8b3df74d4042b9aa7135114252304"
    private let baseURL = "http://api.weatherapi.com/v1"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private func performRequest<T: Decodable>(urlString: String) async throws -> T {
            guard let url = URL(string: urlString) else {
                throw APIError.invalidURL
            }

            var request = URLRequest(url: url)
            request.timeoutInterval = 10

            do {
                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                        throw APIError.apiError(message: errorResponse.error.message)
                    }
                    throw APIError.httpError(statusCode: httpResponse.statusCode)
                }

                guard !data.isEmpty else {
                    throw APIError.invalidResponse
                }

                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    print("Decoding error: \(error)")
                    throw APIError.decodingError
                }

            } catch let error as APIError {
                throw error
            } catch {
                throw handleNetworkError(error)
            }
        }

        // Обработка сетевых ошибок
        private func handleNetworkError(_ error: Error) -> APIError {
            switch (error as NSError).code {
            case NSURLErrorTimedOut:
                return .apiError(message: "Таймаут соединения")
            case NSURLErrorNotConnectedToInternet, NSURLErrorDataNotAllowed:
                return .apiError(message: "Нет интернет соединения")
            case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                return .apiError(message: "Не удалось подключиться к серверу")
            default:
                return .unknownError
            }
        }

    // MARK: - Public methods

    func fetchCurrentWeather(lat: Double, lon: Double) async throws -> CurrentWeatherResponse {
        let urlString = "\(baseURL)/current.json?key=\(apiKey)&q=\(lat),\(lon)"
        return try await performRequest(urlString: urlString)
    }

    func fetchForecast(lat: Double, lon: Double) async throws -> ForecastWeatherResponse {
        let urlString = "\(baseURL)/forecast.json?key=\(apiKey)&q=\(lat),\(lon)&days=7"
        return try await performRequest(urlString: urlString)
    }
}
