//
//  WeatherViewController.swift
//  WeatherTest
//
//  Created by Alexander Myskin on 13.05.2025.
//
import UIKit

protocol WeatherDisplayLogic: AnyObject {
    func displayWeather(viewModel: WeatherModels.ViewModel)
    func displayError(message: String)
    func setLoading(_ isLoading: Bool)
    func showLocationDeniedAlert()
}

final class WeatherViewController: UIViewController, WeatherDisplayLogic {

    var interactor: WeatherBusinessLogic?
    var router: WeatherRoutingLogic?

    // MARK: - UI

    private let scrollView = UIScrollView()

    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let cityLabel = UILabel()
    private let temperatureLabel = UILabel()
    private let iconImageView = UIImageView()
    private let refreshControl = UIRefreshControl()

    private let hourlyCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    )

    private let dailyTableView = UITableView()

    private let errorLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupNotifications()
        interactor?.fetchWeather()
    }

    override func viewDidAppear(_ animated: Bool) {
        interactor?.setLoading()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSceneActivation),
            name: .sceneDidBecomeActive,
            object: nil
        )
    }

    // MARK: - Setup UI

    private func setupUI() {
        refreshControl.addTarget(self, action: #selector(refreshWeatherData), for: .valueChanged)
        scrollView.refreshControl = refreshControl
        cityLabel.font = .boldSystemFont(ofSize: 24)
        temperatureLabel.font = .systemFont(ofSize: 64)
        iconImageView.contentMode = .scaleAspectFit

        hourlyCollectionView.dataSource = self
        hourlyCollectionView.register(HourlyForecastCell.self, forCellWithReuseIdentifier: "HourlyCell")
        if let layout = hourlyCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.itemSize = CGSize(width: 60, height: 80)
        }

        dailyTableView.dataSource = self
        dailyTableView.register(DailyForecastCell.self, forCellReuseIdentifier: "DailyCell")
        dailyTableView.isScrollEnabled = false
        dailyTableView.rowHeight = UITableView.automaticDimension
        dailyTableView.estimatedRowHeight = 60

        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.textColor = .systemRed
        errorLabel.isHidden = true

        retryButton.setTitle("Повторить", for: .normal)
        retryButton.addTarget(self, action: #selector(didTapRetry), for: .touchUpInside)
        retryButton.isHidden = true

        activityIndicator.hidesWhenStopped = true

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        [cityLabel, temperatureLabel, iconImageView, hourlyCollectionView, dailyTableView, errorLabel, retryButton, activityIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            // Констрейнты для ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // Констрейнты для контента внутри ScrollView
            cityLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            cityLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            cityLabel.widthAnchor.constraint(lessThanOrEqualTo: scrollView.widthAnchor, constant: -32),

            temperatureLabel.topAnchor.constraint(equalTo: cityLabel.bottomAnchor, constant: 8),
            temperatureLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),

            iconImageView.topAnchor.constraint(equalTo: temperatureLabel.bottomAnchor, constant: 16),
            iconImageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            iconImageView.heightAnchor.constraint(equalToConstant: 64),
            iconImageView.widthAnchor.constraint(equalToConstant: 64),

            hourlyCollectionView.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 24),
            hourlyCollectionView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            hourlyCollectionView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            hourlyCollectionView.heightAnchor.constraint(equalToConstant: 100),

            dailyTableView.topAnchor.constraint(equalTo: hourlyCollectionView.bottomAnchor, constant: 24),
            dailyTableView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            dailyTableView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            dailyTableView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            // Констрейнты для error и retry
            errorLabel.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),

            retryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 12),
            retryButton.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
        ])

        scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor).isActive = true
    }

    // MARK: - Display Logic

    private var hourlyItems: [WeatherModels.HourlyItem] = []
    private var dailyItems: [WeatherModels.DailyItem] = []

    private func updateTableConstraints() {
        let tableHeight = self.dailyTableView.contentSize.height
        self.dailyTableView.constraints
            .filter { $0.firstAttribute == .height }
            .forEach { $0.isActive = false }

        self.dailyTableView.heightAnchor.constraint(equalToConstant: tableHeight).isActive = true
    }

    func displayWeather(viewModel: WeatherModels.ViewModel) {
        refreshControl.endRefreshing()
        errorLabel.isHidden = true
        retryButton.isHidden = true

        cityLabel.text = viewModel.city
        temperatureLabel.text = viewModel.currentTemp
        iconImageView.load(
            from: viewModel.conditionIcon,
            placeholder: UIImage(systemName: "heart")
        )

        hourlyItems = viewModel.hourlyForecast
        dailyItems = viewModel.dailyForecast
        dailyTableView.isHidden = false
        hourlyCollectionView.isHidden = false
        hourlyCollectionView.reloadData()
        dailyTableView.reloadData()
        updateTableConstraints()
    }


    func displayError(message: String) {
        refreshControl.endRefreshing()
        errorLabel.text = message
        errorLabel.isHidden = false
        retryButton.isHidden = false
        dailyTableView.isHidden = true
        hourlyCollectionView.isHidden = true
    }

    func setLoading(_ isLoading: Bool) {
        if isLoading && !refreshControl.isRefreshing {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
            refreshControl.endRefreshing()
        }
    }

    func showLocationDeniedAlert() {
        let alert = UIAlertController(
            title: "Доступ к геолокации отключён",
            message: "Для показа погоды в вашем регионе, пожалуйста, разрешите доступ к геопозиции в настройках.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Настройки", style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }))

        present(alert, animated: true)
    }

    // MARK: - Actions

    @objc private func didTapRetry() {
        errorLabel.isHidden = true
        retryButton.isHidden = true
        interactor?.fetchWeather()
    }

    // MARK: - Refresh Control
    @objc private func refreshWeatherData() {
        interactor?.fetchWeather()
    }

    @objc private func handleSceneActivation() {
        interactor?.fetchWeather()
    }
}

// MARK: - CollectionView + TableView

extension WeatherViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        hourlyItems.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let item = hourlyItems[indexPath.item]
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "HourlyCell",
            for: indexPath
        ) as? HourlyForecastCell else {
            assertionFailure("Cell registration failed")
            return UICollectionViewCell()
        }
        cell.configure(with: item)
        return cell
    }
}

extension WeatherViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dailyItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = dailyItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "DailyCell", for: indexPath) as! DailyForecastCell
        cell.configure(with: item)
        return cell
    }
}
