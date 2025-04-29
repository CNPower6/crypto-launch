//
//  CoinDetailViewController.swift
//  CryptoLaunch
//
//  Created by Brian Todi on 2025-03-20.
//

import UIKit
import Charts
import Alamofire
import SDWebImage

class CoinDetailViewController: UIViewController {
    
    // MARK: - Public Properties
    // coin type
    var coin: NewCoin
    
    // initialize coin so swift doesnt crash
    init(coin: NewCoin) {
        self.coin = coin
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable, message: "Use init(coin:) instead.")
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    // MARK: - UI Elements
    
    // container at top that has name price image
    private let topContainer = UIView()
    
    // coin image
    private let coinIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 30
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    // coin name
    private let coinNameLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .white
        lbl.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        lbl.text = "Coin"
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    // coin price
    private let priceLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .white
        lbl.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        lbl.text = "$0.00"
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
        // % change
        private let percentageLabel: UILabel = {
            let lbl = UILabel()
            lbl.text = "+0.0%"
            lbl.textColor = .systemGreen
            lbl.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
            lbl.translatesAutoresizingMaskIntoConstraints = false
            return lbl
        }()
    
    // create chart
    private let lineChartView: LineChartView = {
            let chart = LineChartView()
            chart.noDataText = "Loading chart..."
            chart.backgroundColor = .clear
        
        // hide grid
        chart.xAxis.drawGridLinesEnabled = false
        chart.leftAxis.drawGridLinesEnabled = false
        chart.rightAxis.drawGridLinesEnabled = false
        
        // white y
        chart.leftAxis.labelTextColor = .white
        chart.leftAxis.axisLineColor = .white
        
        // hide x
        chart.xAxis.drawLabelsEnabled = false
        chart.xAxis.axisLineColor = .white
        
        // hiding legend
        chart.rightAxis.enabled = false
            chart.legend.enabled = false
        
        chart.translatesAutoresizingMaskIntoConstraints = false
        return chart
    }()
    
    // labels for quick stats
    private let quickStatsLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Quick Stats"
        lbl.textColor = .white
        lbl.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    // putting in the 6 key pills for quick stats
    private let marketCapPill = StatPillView(title: "Market Cap")
    private let volumePill = StatPillView(title: "Volume (24h)")
    private let fdvPill = StatPillView(title: "FDV")
    private let circSupplyPill = StatPillView(title: "Circulating Supply")
    private let totalSupplyPill = StatPillView(title: "Total Supply")
    private let maxSupplyPill = StatPillView(title: "Max Supply")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup page
        title = "Coin Details"
        view.backgroundColor = UIColor(red: 20/255, green: 19/255, blue: 45/255, alpha: 1.0)
        
        setupLayout()
        updateUI()
        
        // call fetch functions
        fetchCoinDetails()
        fetchChartData()
    }
    
    // MARK: - Setup Layout
    
    private func setupLayout() {
        // add subviews
        topContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topContainer)
        
        topContainer.addSubview(coinIconImageView)
        topContainer.addSubview(coinNameLabel)
            topContainer.addSubview(priceLabel)
        topContainer.addSubview(percentageLabel)
        
        view.addSubview(lineChartView)
        view.addSubview(quickStatsLabel)
        
        // contian pills
        let row1Stack = UIStackView(arrangedSubviews: [marketCapPill, volumePill])
        let row2Stack = UIStackView(arrangedSubviews: [fdvPill, circSupplyPill])
            let row3Stack = UIStackView(arrangedSubviews: [totalSupplyPill, maxSupplyPill])
        
            [row1Stack, row2Stack, row3Stack].forEach { row in
                row.axis = .horizontal
                row.alignment = .fill
                row.distribution = .fillEqually
                row.spacing = 12
            }
        
        let pillsContainerStack = UIStackView(arrangedSubviews: [row1Stack, row2Stack, row3Stack])
        pillsContainerStack.axis = .vertical
            pillsContainerStack.alignment = .fill
        pillsContainerStack.distribution = .fillEqually
        pillsContainerStack.spacing = 12
            pillsContainerStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pillsContainerStack)
        
        // constraints
        NSLayoutConstraint.activate([
            // pin top section to top of screen
            topContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            topContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topContainer.heightAnchor.constraint(equalToConstant: 80),
                // icons
                coinIconImageView.leadingAnchor.constraint(equalTo: topContainer.leadingAnchor, constant: 16),
                coinIconImageView.centerYAnchor.constraint(equalTo: topContainer.centerYAnchor),
                coinIconImageView.widthAnchor.constraint(equalToConstant: 60),
                coinIconImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // name label at top
            coinNameLabel.leadingAnchor.constraint(equalTo: coinIconImageView.trailingAnchor, constant: 16),
            coinNameLabel.topAnchor.constraint(equalTo: topContainer.topAnchor),
            
            // price label after name
            priceLabel.leadingAnchor.constraint(equalTo: coinNameLabel.leadingAnchor),
            priceLabel.topAnchor.constraint(equalTo: coinNameLabel.bottomAnchor, constant: 4),
            
            // percentage label
            percentageLabel.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor),
            percentageLabel.leadingAnchor.constraint(equalTo: priceLabel.trailingAnchor, constant: 16),
            
            // contraints for chart
            lineChartView.topAnchor.constraint(equalTo: topContainer.bottomAnchor, constant: 16),
                lineChartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            lineChartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            lineChartView.heightAnchor.constraint(equalToConstant: 250),
            
                // quickstats secitons
                quickStatsLabel.topAnchor.constraint(equalTo: lineChartView.bottomAnchor, constant: 26),
                quickStatsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                
            // Put the pills under the container
            pillsContainerStack.topAnchor.constraint(equalTo: quickStatsLabel.bottomAnchor, constant: 16),
            pillsContainerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                pillsContainerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            pillsContainerStack.heightAnchor.constraint(equalToConstant: 220),
//            pillsContainerStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Update UI
    
    private func updateUI() {
        // pass in icon from prev page ?
        if let iconUrlString = coin.icon, let url = URL(string: iconUrlString) {
            coinIconImageView.sd_setImage(with: url, placeholderImage: nil)
        } else {
            coinIconImageView.image = UIImage(systemName: "bitcoinsign.circle.fill")
            coinIconImageView.tintColor = .white
        }

//        print("update ui")
        coinNameLabel.text = coin.name ?? "Coin"
        
        if let price = coin.current_price {
            priceLabel.text = String(format: "$%.6f", price)
        } else {
            priceLabel.text = "$--"
        }
        
        if let change = coin.price_change_percentage_24h {
            let formatted = String(format: "%.2f%%", change)
            percentageLabel.text = change >= 0 ? "+\(formatted)" : formatted
//            print("testt", percentageLabel.text)
            percentageLabel.textColor = (change >= 0) ? .systemGreen : .systemRed
        } else {
            percentageLabel.text = "--%"
            percentageLabel.textColor = .white
        }
    }
    
    // MARK: - Networking
    
    // post req to get cpin details
    private func fetchCoinDetails() {
        guard let coinId = coin.id else { return }
        let urlString = "https://crypto-launch-e430d83afb8b.herokuapp.com/cryptolaunch/getCoinDetails"
        let params: [String: Any] = ["coin_id": coinId]
        
        AF.request(urlString, method: .post, parameters: params, encoding: JSONEncoding.default)
            .validate()
            .responseDecodable(of: CoinDetailsResponse.self) { response in
                switch response.result {
                case .success(let detailsResponse):
                    guard let details = detailsResponse.data else { return }
                    DispatchQueue.main.async {
                        
                        // fill up the quick stats pills
                        if let mc = details.market_cap {
                            self.marketCapPill.updateValue("$\(self.formatLargeNumber(mc))")
                        }
                        if let vol = details.volume_24h {
//                            print("dc", volumePill)
                            self.volumePill.updateValue("$\(self.formatLargeNumber(vol))")
                        }
                            if let fdv = details.fdv {
                                self.fdvPill.updateValue("$\(self.formatLargeNumber(fdv))")
                            }
//                        let circ
                            if let circ = details.circulating_supply {
                            self.circSupplyPill.updateValue(self.formatLargeNumber(circ))
                        }
                        if let total = details.total_supply {
                                    self.totalSupplyPill.updateValue(self.formatLargeNumber(total))
                        }
                        if let max = details.max_supply {
                            self.maxSupplyPill.updateValue(self.formatLargeNumber(max))
                        }
                    }
                case .failure(let error):
                    print("Error fetching coin details:", error)
                }
            }
    }
    
    // func to get chart data from server
    private func fetchChartData() {
//        print("coinid", coin.id)
        guard let coinId = coin.id else { return }
        let urlString = "https://crypto-launch-e430d83afb8b.herokuapp.com/cryptolaunch/getCoinMarketChart"
        let params: [String: Any] = [
            "coin_id": coinId,
//            "days"
            "days": "1",
            "vs_currency": "usd"
        ]
        
        AF.request(urlString, method: .post, parameters: params, encoding: JSONEncoding.default)
            .validate()
            .responseDecodable(of: MarketChartResponse.self) { response in
                switch response.result {
                case .success(let chartResponse):
//                    print("succes return")
                    self.updateChart(with: chartResponse.data)
                case .failure(let error):
                    print("Error fetching chart data:", error)
                }
            }
    }
    
    // update chart function
    private func updateChart(with data: [[Double]]) {
        let entries = data.map { ChartDataEntry(x: $0[0], y: $0[1]) }
        
//        print("update chart")
        let dataSet = LineChartDataSet(entries: entries, label: "")
        dataSet.drawCirclesEnabled = false
        dataSet.mode = .cubicBezier
//        dataSet.lineWidth = 4
            dataSet.lineWidth = 2
        
        if #available(iOS 13.0, *) {
            // make it purple background
            dataSet.setColor(.systemPurple)
            dataSet.fillColor = .systemPurple
        } else {
            dataSet.setColor(.purple)
            dataSet.fillColor = .purple
        }
        
        dataSet.drawFilledEnabled = true
        dataSet.fillAlpha = 0.2
        
        let chartData = LineChartData(dataSet: dataSet)
        chartData.setDrawValues(false)
        
        DispatchQueue.main.async {
            self.lineChartView.data = chartData
        }
    }
    
    // MARK: - Helpers
    
    // helper function to format large numbers
    private func formatLargeNumber(_ value: Double) -> String {
        let absValue = abs(value)
        let sign = (value < 0) ? "-" : ""
        
//        print("val",value)
        switch absValue {
        case 1_000_000_000...:
            return String(format: "%@%.1fB", sign, absValue / 1_000_000_000)
        case 1_000_000...:
            return String(format: "%@%.1fM", sign, absValue / 1_000_000)
        case 1_000...:
            return String(format: "%@%.1fK", sign, absValue / 1_000)
        default:
            return String(format: "%@%.0f", sign, absValue)
        }
    }
}

// MARK: - Data Models

// struct for data response
struct CoinDetailsResponse: Codable {
    let data: CoinDetailsData?
    let msg: String
    let status: Int
}

//struct for coin details
struct CoinDetailsData: Codable {
    let market_cap: Double?
    let volume_24h: Double?
    let fdv: Double?
    let circulating_supply: Double?
    let total_supply: Double?
    let max_supply: Double?
}

// struct for chartsy
struct MarketChartResponse: Codable {
    let data: [[Double]]
    let msg: String
    let status: Int
}

// pills class for top 6 stats
class StatPillView: UIView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    
//    initialize pill title
    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor(red: 35/255, green: 32/255, blue: 70/255, alpha: 1.0)
        layer.cornerRadius = 10
        
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        valueLabel.text = "---"
        valueLabel.textColor = .white
        valueLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(titleLabel)
        addSubview(valueLabel)
        
            // set constraints for pills
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                
                valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                valueLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
            ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    
    
        func updateValue(_ text: String) {
        valueLabel.text = text
    }
}
