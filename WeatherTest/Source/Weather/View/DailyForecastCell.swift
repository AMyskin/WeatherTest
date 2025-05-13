//
//  DailyForecastCell.swift
//  WeatherTest
//
//  Created by Alexander Myskin on 13.05.2025.
//

import UIKit

final class DailyForecastCell: UITableViewCell {

    private let dayLabel = UILabel()
    private let iconImageView = UIImageView()
    private let tempRangeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        dayLabel.text = nil
        iconImageView.cancelImageLoad()
        iconImageView.image = nil
        tempRangeLabel.text = nil
    }


    private func setupUI() {
        dayLabel.font = .systemFont(ofSize: 16)
        tempRangeLabel.font = .systemFont(ofSize: 16)
        tempRangeLabel.textAlignment = .right

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false


        let hStack = UIStackView(arrangedSubviews: [dayLabel, iconImageView, tempRangeLabel])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 8
        hStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 30),
        ])
    }

    func configure(with model: WeatherModels.DailyItem) {
        dayLabel.text = model.day
        tempRangeLabel.text = model.tempRange
        iconImageView.load(from: model.iconURL)
    }
}
