//
//  CurrentWeatherResponse.swift
//  WeatherTest
//
//  Created by Alexander Myskin on 13.05.2025.
//

import Foundation

struct CurrentWeatherResponse: Decodable {
    let location: Location
    let current: Current
}

struct Location: Decodable {
    let name: String
    let lat: Double
    let lon: Double
    let tz_id: String
}

struct Current: Decodable {
    let temp_c: Double
    let condition: Condition
}
