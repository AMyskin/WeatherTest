//
//  WeatherAssembly.swift
//  WeatherTest
//
//  Created by Alexander Myskin on 13.05.2025.
//

import Foundation

final class WeatherAssembly {
    static func makeWeatherViewController() -> WeatherViewController {
        let viewController = WeatherViewController()

        let interactor = WeatherInteractor()
        let presenter = WeatherPresenter()
        let router = WeatherRouter()

        viewController.interactor = interactor
        viewController.router = router

        let weatherService = WeatherAPIService()
        let locationService = LocationService()
        
        interactor.presenter = presenter
        interactor.weatherService = weatherService
        interactor.locationService = locationService

        presenter.viewController = viewController

        router.viewController = viewController

        return viewController
    }
}
