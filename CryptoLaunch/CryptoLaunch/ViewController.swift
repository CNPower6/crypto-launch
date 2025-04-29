//
//  ViewController.swift
//  CryptoLaunch
//
//  Created by Brian Todi on 2025-02-20.
//

import UIKit
import Alamofire
import SDWebImage

// MARK: - Models

// struct to hold a coin
struct NewCoin: Codable {
    let id: String?
    let symbol: String?
    let name: String?
    let image: String?
    let current_price: Double?
    let market_cap: Double?
    let price_change_percentage_24h: Double?
    let icon: String?
    
    // initializer for coding token
    enum CodingKeys: String, CodingKey {
        case id, symbol, name, image, current_price, market_cap, price_change_percentage_24h, icon
    }
    
    // set token row
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        symbol = try container.decodeIfPresent(String.self, forKey: .symbol)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        current_price = try container.decodeIfPresent(Double.self, forKey: .current_price)
        market_cap = try container.decodeIfPresent(Double.self, forKey: .market_cap)
        price_change_percentage_24h = try container.decodeIfPresent(Double.self, forKey: .price_change_percentage_24h)
        icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? image
    }
}


// struct for server response with batched coin data
struct CoinData: Codable {
    let viralCoins: [NewCoin]
    let biggestGainers: [NewCoin]
    let topMarketCap: [NewCoin]
}

// full server response struct
struct AllCoinsResponse: Codable {
    let data: CoinData
    let msg: String
    let status: Int
}

// handle all network requests in a diff class to keep all the pages clean
class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
        
    // server base url
    let baseURL = "https://crypto-launch-e430d83afb8b.herokuapp.com"
    
    func fetchAllCoins(completion: @escaping (Result<CoinData, Error>) -> Void) {
        
        let userId = UserDefaults.standard.string(forKey: "user_id") ?? ""
            
        // getcoins route
        let url = "\(baseURL)/cryptolaunch/getCoins"
        let parameters: [String: Any] = [
            "unique_key": userId
        ]
        
        // alamofire for the request is very simple
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .responseDecodable(of: AllCoinsResponse.self) { response in
                switch response.result {
                case .success(let allCoinsResponse):
                    completion(.success(allCoinsResponse.data))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}

// MARK: - ViewController

class ViewController: UIViewController {
    
    // MARK: - UI Elements
    
    // create scrollview
    private let mainScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    // stack view for page
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 25
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // first stack section is viral coins
    private let viralCoinsLabel: UILabel = {
        let label = UILabel()
        label.text = "Viral Coins"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    // collection view for viral coins section
    private lazy var viralCoinsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        layout.itemSize = CGSize(width: 60, height: 80)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CircleCollectionViewCell.self, forCellWithReuseIdentifier: CircleCollectionViewCell.reuseIdentifier)
        return collectionView
    }()
    
    // second stack section for biggest gainers
    private let biggestGainersLabel: UILabel = {
        let label = UILabel()
        label.text = "Biggest Gainers 24h"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    private lazy var biggestGainersCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        layout.itemSize = CGSize(width: 60, height: 80)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CircleCollectionViewCell.self, forCellWithReuseIdentifier: CircleCollectionViewCell.reuseIdentifier)
        return collectionView
    }()
    
    // bottom stack section for top market cap
    private let topMarketCapLabel: UILabel = {
        let label = UILabel()
        label.text = "Top Market Cap"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    // setup tableview for top market cap bottom stack section
    private lazy var topMarketCapTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 80
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(
            TopMarketCapTableViewCell.self,
            forCellReuseIdentifier: TopMarketCapTableViewCell.reuseIdentifier
        )
        return tableView
    }()
    
    
//    private var newcoin: [NewCoin] = []
//    private var gain: [NewCoin] = []
    
    private var viralCoinsData: [NewCoin] = []
    private var biggestGainersData: [NewCoin] = []
    private var topMarketCapData: [NewCoin] = []
    private var topMarketCapHeightConstraint: NSLayoutConstraint?
    
    // MARK: - Lifecycle
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        super.viewDidLoad()
        
        self.title = "Discover"
        view.backgroundColor = UIColor(red: 20/255, green: 19/255, blue: 45/255, alpha: 1.0)
//        view.backgroundColor = UIColor(red: 28/255, green: 6/255, blue: 56/255, alpha: 1.0)
        
        // call setup functions once view loads in
        setupLayout()
        fetchAllCoins()
    }
    
    // MARK: - Networking
    
    // request to fetch coins through network manager
    private func fetchAllCoins() {
        NetworkManager.shared.fetchAllCoins { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let coinData):
                    
                    // setup sections in success
                    self?.viralCoinsData = coinData.viralCoins
                    self?.biggestGainersData = coinData.biggestGainers
                    self?.topMarketCapData = coinData.topMarketCap
                    
                    self?.viralCoinsCollectionView.reloadData()
                    self?.biggestGainersCollectionView.reloadData()
                    self?.topMarketCapTableView.reloadData()
                    
                    // fix table height based on num loaded in
                    let tableHeight = 80 * CGFloat(self?.topMarketCapData.count ?? 0)
                    self?.topMarketCapHeightConstraint?.constant = tableHeight
                    UIView.animate(withDuration: 0.3) {
                        self?.view.layoutIfNeeded()
                    }
                case .failure(let error):
//                    print("what 1: \(error.localizedDescription)")
                    print("Error fetching coins: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Layout
    
    // main layout function
    private func setupLayout() {
        view.addSubview(mainScrollView)
        
//        
//        contentStackView.addArrangedSubview(biggain)
//        contentStackView.addArrangedSubview(viral)
//
//        contentStackView.addArrangedSubview(gainlbl)
//        contentStackView.addArrangedSubview(bgcolview)
//
        
        mainScrollView.addSubview(contentStackView)
        
        contentStackView.addArrangedSubview(viralCoinsLabel)
        contentStackView.addArrangedSubview(viralCoinsCollectionView)
        
        contentStackView.addArrangedSubview(biggestGainersLabel)
        contentStackView.addArrangedSubview(biggestGainersCollectionView)
        
        contentStackView.addArrangedSubview(topMarketCapLabel)
        contentStackView.addArrangedSubview(topMarketCapTableView)
//        
//        contentStackView.addArrangedSubview(topMarketCapLabel)
//        contentStackView.addArrangedSubview(topMarketCapTableView)
        
        mainScrollView.translatesAutoresizingMaskIntoConstraints = false
        viralCoinsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        biggestGainersCollectionView.translatesAutoresizingMaskIntoConstraints = false
        topMarketCapTableView.translatesAutoresizingMaskIntoConstraints = false
        
        // constraints for the whole stacks
        NSLayoutConstraint.activate([
            // extend to full bounds
            mainScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: mainScrollView.topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: mainScrollView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: mainScrollView.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: mainScrollView.bottomAnchor, constant: -16),
            contentStackView.widthAnchor.constraint(equalTo: mainScrollView.widthAnchor, constant: -32),
            
            // set height for both sections to match
            viralCoinsCollectionView.heightAnchor.constraint(equalToConstant: 80),
            biggestGainersCollectionView.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        topMarketCapHeightConstraint = topMarketCapTableView.heightAnchor.constraint(equalToConstant: 0)
        topMarketCapHeightConstraint?.isActive = true
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        
//        print("here")
        if collectionView == viralCoinsCollectionView {
            return viralCoinsData.count
        } else {
            return biggestGainersData.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CircleCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as! CircleCollectionViewCell
        
        let coin: NewCoin
        
        // print("here 2", collectionView)

        if collectionView == viralCoinsCollectionView {
            coin = viralCoinsData[indexPath.item]
        } else {
            coin = biggestGainersData[indexPath.item]
        }
        
        cell.configure(coin: coin)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedCoin: NewCoin
        if collectionView == viralCoinsCollectionView {
            selectedCoin = viralCoinsData[indexPath.item]
        } else {
            selectedCoin = biggestGainersData[indexPath.item]
        }
        let detailVC = CoinDetailViewController(coin: selectedCoin)
        navigationController?.pushViewController(detailVC, animated: true)
    }


}

// MARK: - UITableView DataSource & Delegate

// table view extension for top market cop rows
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topMarketCapData.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: TopMarketCapTableViewCell.reuseIdentifier,
            for: indexPath
        ) as! TopMarketCapTableViewCell
        
        let coin = topMarketCapData[indexPath.row]
        cell.configure(coin: coin)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCoin = topMarketCapData[indexPath.row]
        let detailVC = CoinDetailViewController(coin: selectedCoin)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
}

// MARK: - CircleCollectionViewCell

// putting circle class in viewcontroller since it shows up on this page to keep it clean
class CircleCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "CircleCollectionViewCell"
        
    // set image for coin and setup stack with label
    private let coinImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor(red: 60/255, green: 60/255, blue: 100/255, alpha: 1.0)
        imageView.layer.cornerRadius = 30
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // title label
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let verticalStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // add to subview
        contentView.addSubview(verticalStack)
        verticalStack.addArrangedSubview(coinImageView)
        verticalStack.addArrangedSubview(titleLabel)
        
        // constrain the whole stack
        NSLayoutConstraint.activate([
            verticalStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            verticalStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            verticalStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            verticalStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            coinImageView.widthAnchor.constraint(equalToConstant: 60),
            coinImageView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // set coin image with sdwebimage
    func configure(coin: NewCoin) {
        titleLabel.text = coin.name ?? "Unknown"
        if let imageUrl = coin.image, let url = URL(string: imageUrl) {
            coinImageView.sd_setImage(with: url, placeholderImage: nil)
        } else {
            coinImageView.image = nil
        }
    }
}

// MARK: - TopMarketCapTableViewCell

// also putting topmarketcap cell in this page since it shows up here
class TopMarketCapTableViewCell: UITableViewCell {
    static let reuseIdentifier = "TopMarketCapTableViewCell"
    
    // image
    private let coinImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor(red: 60/255, green: 60/255, blue: 100/255, alpha: 1.0)
        imageView.layer.cornerRadius = 30
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // coin label
    private let coinLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // price
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 21, weight: .bold)
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // % change
    private let percentageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemGreen
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var rightStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [priceLabel, percentageLabel])
        stack.axis = .vertical
        stack.alignment = .trailing
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(coinImageView)
        contentView.addSubview(coinLabel)
        contentView.addSubview(rightStack)
        
        // lock price stack width so no shrinking
        rightStack.widthAnchor.constraint(equalToConstant: 90).isActive = true
        
        // flexible coin label
        rightStack.setContentHuggingPriority(.required, for: .horizontal)
        rightStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        coinLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        coinLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        // setup constraints
        NSLayoutConstraint.activate([
            coinImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            coinImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            coinImageView.widthAnchor.constraint(equalToConstant: 60),
            coinImageView.heightAnchor.constraint(equalToConstant: 60),
            
            coinLabel.leadingAnchor.constraint(equalTo: coinImageView.trailingAnchor, constant: 16),
            coinLabel.trailingAnchor.constraint(equalTo: rightStack.leadingAnchor, constant: -8),
            coinLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            rightStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            rightStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // configure a coin for bottom section
    func configure(coin: NewCoin) {
        coinLabel.text = coin.name ?? "Unknown"
        
        if let imageUrl = coin.image, let url = URL(string: imageUrl) {
            coinImageView.sd_setImage(with: url, placeholderImage: nil)
        } else {
            coinImageView.image = nil
        }
        
        if let price = coin.current_price {
            priceLabel.text = String(format: "$%.2f", price)
        } else {
            priceLabel.text = "$--"
        }
        
        if let change = coin.price_change_percentage_24h {
            let formatted = String(format: "%.2f%%", change)
            percentageLabel.text = formatted
            percentageLabel.textColor = change < 0 ? .systemRed : .systemGreen
        } else {
            percentageLabel.text = "--%"
            percentageLabel.textColor = .white
        }
    }
}

