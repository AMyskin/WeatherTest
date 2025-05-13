//
//  Calendar+Extensions.swift
//  WeatherTest
//
//  Created by Alexander Myskin on 13.05.2025.
//

import Foundation

extension Calendar {
    func isDate(_ date: Date, inSameDayAs otherDate: Date, in timeZone: TimeZone) -> Bool {
        var cal = self
        cal.timeZone = timeZone
        return cal.isDate(date, inSameDayAs: otherDate)
    }

    func component(_ component: Component, from date: Date, in timeZone: TimeZone) -> Int {
        var cal = self
        cal.timeZone = timeZone
        return cal.component(component, from: date)
    }
}
