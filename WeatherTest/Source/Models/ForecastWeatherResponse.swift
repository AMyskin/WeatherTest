//
//  ForecastWeatherResponse.swift
//  WeatherTest
//
//  Created by Alexander Myskin on 13.05.2025.
//

import Foundation

struct ForecastWeatherResponse: Decodable {
    let forecast: Forecast
}

struct Forecast: Decodable {
    let forecastday: [ForecastDay]
}

struct ForecastDay: Decodable {
    let date: String
    let day: Day
    let hour: [Hour]
}

struct Day: Decodable {
    let mintemp_c: Double
    let maxtemp_c: Double
    let condition: Condition
}

struct Hour: Decodable {
    let time: String
    let temp_c: Double
    let condition: Condition
}

struct Condition: Decodable {
    let text: String
    let icon: String
}

struct APIErrorResponse: Decodable {
    struct ErrorData: Decodable {
        let code: Int
        let message: String
    }
    let error: ErrorData
}
