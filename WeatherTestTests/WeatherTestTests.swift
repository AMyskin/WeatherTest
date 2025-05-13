//
//  WeatherTestTests.swift
//  WeatherTestTests
//
//  Created by Alexander Myskin on 13.05.2025.
//

import XCTest
import CoreLocation
@testable import WeatherTest

final class WeatherInteractorTests: XCTestCase {

    var interactor: WeatherInteractor!
    var mockPresenter: MockWeatherPresenter!
    var mockWeatherService: MockWeatherService!
    var mockLocationService: MockLocationService!

    override func setUp() {
        super.setUp()
        mockPresenter = MockWeatherPresenter()
        mockWeatherService = MockWeatherService()
        mockLocationService = MockLocationService()

        interactor = WeatherInteractor()
        interactor.presenter = mockPresenter
        interactor.weatherService = mockWeatherService
        interactor.locationService = mockLocationService
    }

    override func tearDown() {
        interactor = nil
        super.tearDown()
    }

    // MARK: - Success Scenario
    func testSuccessfulWeatherFetch() async {
        // Given
        let expectation = XCTestExpectation(description: "Weather fetch success")
        mockLocationService.mockCoordinate = CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6176)
        mockWeatherService.mockCurrentResponse = .mock()
        mockWeatherService.mockForecastResponse = .mock()

        // When
        interactor.fetchWeather()

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockPresenter.presentWeatherCalled)
            XCTAssertEqual(self.mockPresenter.response?.city, "Test City")
            XCTAssertEqual(self.mockPresenter.response?.currentTemp, 23.5)
            XCTAssertEqual(self.mockPresenter.response?.hourly.count, 36)
            XCTAssertEqual(self.mockPresenter.response?.daily.count, 3)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Error Scenarios
    func testLocationDeniedError() async {
        // Given
        let expectation = XCTestExpectation(description: "Location denied")
        mockLocationService.shouldShowSettings = true

        // When
        interactor.fetchWeather()

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockPresenter.presentLocationDeniedCalled)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testAPIErrorHandling() async {
        // Given
        let expectation = XCTestExpectation(description: "API error handling")
        mockWeatherService.shouldThrowError = true
        mockWeatherService.mockError = .apiError(message: "Test error message")

        // When
        interactor.fetchWeather()

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertTrue(self.mockPresenter.presentErrorCalled)
            XCTAssertEqual(self.mockPresenter.errorMessage, "Test error message")
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testInvalidTimezoneHandling() async {
        // Given
        let expectation = XCTestExpectation(description: "Invalid timezone")
        let originalResponse = CurrentWeatherResponse.mock()

        let invalidLocation = Location(
            name: originalResponse.location.name,
            lat: originalResponse.location.lat,
            lon: originalResponse.location.lon,
            tz_id: "Invalid/Timezone"
        )

        let invalidResponse = CurrentWeatherResponse(
            location: invalidLocation,
            current: originalResponse.current
        )

        mockWeatherService.mockCurrentResponse = invalidResponse

        // When
        interactor.fetchWeather()

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockPresenter.presentErrorCalled)
            XCTAssertEqual(self.mockPresenter.errorMessage, "Invalid timezone")
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Helper Methods Tests
    func testHourFilteringLogic() {
        // Given
        let timeZone = TimeZone(identifier: "Europe/Moscow")!
        let currentDate = Date()
        let calendar = Calendar.current

        let forecastDays = [
            ForecastDay.mock(date: currentDate),
            ForecastDay.mock(date: calendar.date(byAdding: .day, value: 1, to: currentDate)!)
        ]

        // When
        let result = interactor.filterHourlyForecast(
            forecastDays: forecastDays,
            currentDate: currentDate,
            timeZone: timeZone
        )

        // Then
        let currentHour = calendar.component(.hour, from: currentDate, in: timeZone)
        XCTAssertEqual(result.count, 24 - currentHour + 24)
    }

    func testHourFormatting() {
        // Given
        let timeString = "2023-10-05 15:00"
        let timeZone = TimeZone(identifier: "Europe/Moscow")!

        // When
        let result = interactor.formatHourString(timeString, timeZone: timeZone)

        // Then
        XCTAssertEqual(result, "15", "Форматирование часа должно возвращать двухзначное число")
    }

    func testHourFormattingEdgeCases() {
        let testCases = [
            ("2023-12-31 23:59", "Europe/Moscow", "23"),
            ("2024-02-29 00:00", "America/New_York", "16"),
            ("invalid-date", "UTC", "invalid-date")
        ]

        for (timeString, tzID, expected) in testCases {
            let timeZone = TimeZone(identifier: tzID)!
            let result = interactor.formatHourString(timeString, timeZone: timeZone)
            XCTAssertEqual(result, expected, "Неверный формат для: \(timeString)")
        }
    }

    func testLoadingStateManagement() {
        // When
        interactor.setLoading()

        // Then
        XCTAssertTrue(mockPresenter.setLoadingCalled)
        XCTAssertEqual(mockPresenter.isLoading, true)
    }
}

// MARK: - Test Doubles
final class MockWeatherPresenter: WeatherPresentationLogic {
    var presentWeatherCalled = false
    var response: WeatherModels.Response?

    var presentErrorCalled = false
    var errorMessage: String?

    var presentLocationDeniedCalled = false

    var setLoadingCalled = false
    var isLoading: Bool?

    func presentWeather(response: WeatherModels.Response) {
        presentWeatherCalled = true
        self.response = response
    }

    func presentError(message: String) {
        presentErrorCalled = true
        errorMessage = message
    }

    func presentLocationDenied() {
        presentLocationDeniedCalled = true
    }

    func setLoading(_ isLoading: Bool) {
        setLoadingCalled = true
        self.isLoading = isLoading
    }
}

final class MockWeatherService: WeatherServiceProtocol {
    var mockCurrentResponse: CurrentWeatherResponse!
    var mockForecastResponse: ForecastWeatherResponse!
    var mockError: APIError!
    var shouldThrowError = false

    func fetchCurrentWeather(lat: Double, lon: Double) async throws -> CurrentWeatherResponse {
        if shouldThrowError {
            throw mockError
        }
        return mockCurrentResponse
    }

    func fetchForecast(lat: Double, lon: Double) async throws -> ForecastWeatherResponse {
        if shouldThrowError {
            throw mockError
        }
        return mockForecastResponse
    }
}

final class MockLocationService: LocationServiceProtocol {
    var mockCoordinate: CLLocationCoordinate2D?
    var shouldShowSettings = false

    func getCurrentLocation() async -> CLLocationCoordinate2D? {
        return mockCoordinate
    }

    func shouldShowSettingsAlert() -> Bool {
        return shouldShowSettings
    }
}

// MARK: - Test Data
extension CurrentWeatherResponse {
    static func mock() -> CurrentWeatherResponse {
        CurrentWeatherResponse(
            location: Location(
                name: "Test City",
                lat: 55.7558,
                lon: 37.6176,
                tz_id: "Europe/Moscow"
            ),
            current: Current(
                temp_c: 23.5,
                condition: Condition(
                    text: "Sunny",
                    icon: "//cdn.weatherapi.com/weather/64x64/day/113.png"
                )
            )
        )
    }
}

extension ForecastWeatherResponse {
    static func mock() -> ForecastWeatherResponse {
        ForecastWeatherResponse(
            forecast: Forecast(
                forecastday: [
                    ForecastDay.mock(),
                    ForecastDay.mock(date: Date().addingTimeInterval(86400)),
                    ForecastDay.mock(date: Date().addingTimeInterval(172800))
                ]
            )
        )
    }
}

extension ForecastDay {
    static func mock(date: Date = Date()) -> ForecastDay {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return ForecastDay(
            date: formatter.string(from: date),
            day: Day(
                mintemp_c: 15.0,
                maxtemp_c: 25.0,
                condition: Condition(
                    text: "Partly cloudy",
                    icon: "//cdn.weatherapi.com/weather/64x64/day/116.png"
                )
            ),
            hour: (0..<24).map { hour in
                Hour(
                    time: String(format: "%@ %02d:00", formatter.string(from: date), hour),
                    temp_c: 20.0 + Double(hour),
                    condition: Condition(
                        text: hour < 18 ? "Sunny" : "Clear",
                        icon: String(format: "//cdn.weatherapi.com/weather/64x64/day/%d.png", hour % 3 + 113)
                    )
                )
            }
        )
    }
}

extension APIErrorResponse {
    static func mock() -> APIErrorResponse {
        APIErrorResponse(
            error: ErrorData(
                code: 1000,
                message: "Test error message"
            )
        )
    }
}
