//
//  HourlyForecastCell.swift
//  WeatherTest
//
//  Created by Alexander Myskin on 13.05.2025.
//

import UIKit

final class HourlyForecastCell: UICollectionViewCell {

    private let timeLabel = UILabel()
    private let iconImageView = UIImageView()
    private let temperatureLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        timeLabel.text = nil
        iconImageView.cancelImageLoad()
        iconImageView.image = nil
        temperatureLabel.text = nil
    }

    private func setupUI() {
        timeLabel.font = .systemFont(ofSize: 16)
        timeLabel.textAlignment = .center

        temperatureLabel.font = .systemFont(ofSize: 18)
        temperatureLabel.textAlignment = .center

        iconImageView.contentMode = .scaleAspectFit

        let stack = UIStackView(arrangedSubviews: [timeLabel, iconImageView, temperatureLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.distribution = .fillProportionally
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            iconImageView.heightAnchor.constraint(equalToConstant: 30),
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
        ])

        timeLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        temperatureLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }

    func configure(with model: WeatherModels.HourlyItem) {
        timeLabel.text = model.time
        temperatureLabel.text = model.temperature
        iconImageView.load(from: model.iconURL)
    }
}
