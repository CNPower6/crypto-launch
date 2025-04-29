import UIKit
import Alamofire
import SDWebImage

// MARK: - Model for your coin on Back4App

// struct for a coin
struct MyCoin: Codable {
    let objectId: String
    let user_id: String
    let name: String?
    let ticker: String?
    let description: String?
    let initial_supply: String?
    let email: String?
    let completed: Bool?
    let chain: String?
    let icon: String?
    let polyscan_link: String?
    let dex_link: String?
}

// data response from server
struct MyCoinsResponse: Codable {
    let data: [MyCoin]
    let msg: String
    let status: Int
}

class MyCoinsViewController: UIViewController {
    
    private let tableView = UITableView()
    private var myCoins: [MyCoin] = []
    
    // refresh control to refetch data
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup page
        title = "My Coins"
        view.backgroundColor = UIColor(red: 24/255, green: 23/255, blue: 50/255, alpha: 1.0)
        
        setupTableView()
        fetchMyCoins()
    }
    
    // setup table for launch history
    private func setupTableView() {
        
        // clear back and lines between rows
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor(white: 1.0, alpha: 0.1)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MyCoinTableViewCell.self, forCellReuseIdentifier: "MyCoinCell")
        
        // add refresh
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        // setup constraints for table
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // refetch on swipe down
    @objc private func handleRefresh() {
        fetchMyCoins()
    }
    
    // pull userid and fetch from b4a
    private func fetchMyCoins() {
        let userId = UserDefaults.standard.string(forKey: "user_id") ?? ""
        let urlString = "https://crypto-launch-e430d83afb8b.herokuapp.com/cryptolaunch/getUserCoins"
        
        let params: [String: Any] = [
            "user_id": userId
        ]
        
        AF.request(urlString, method: .post, parameters: params, encoding: JSONEncoding.default)
            .validate()
            .responseDecodable(of: MyCoinsResponse.self) { response in
                // stop refersh once the network call completes
                self.refreshControl.endRefreshing()
                
                switch response.result {
                case .success(let myCoinsResponse):
                    self.myCoins = myCoinsResponse.data
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                case .failure(let error):
                    print("Error fetching my coins:", error)
                }
            }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension MyCoinsViewController: UITableViewDataSource, UITableViewDelegate {
    
    // table view
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return myCoins.count
    }
    
    // configure each row
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "MyCoinCell",
            for: indexPath
        ) as! MyCoinTableViewCell
        
        let coin = myCoins[indexPath.row]
        cell.configure(with: coin)
        
        cell.onTradeTap = { [weak self] in
            guard let link = coin.dex_link, !link.isEmpty else { return }
            self?.openURL(link)
        }
        cell.onViewTap = { [weak self] in
            guard let link = coin.polyscan_link, !link.isEmpty else { return }
            self?.openURL(link)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

// MARK: - Custom Cell
class MyCoinTableViewCell: UITableViewCell {
    
    // icon on left
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 20
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(red: 60/255, green: 60/255, blue: 100/255, alpha: 1.0)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    // title
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .white
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    // subtitle
    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .lightGray
        lbl.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    // description label
    private let descriptionLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .lightGray
        lbl.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    // if the token completed, add links else put pending
    private let pendingLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Pending"
        lbl.textColor = .systemYellow
        lbl.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        lbl.textAlignment = .right
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    // links to trade and view
        private let tradeButton: UIButton = {
            let btn = UIButton(type: .system)
            btn.setTitle("Trade", for: .normal)
            btn.setTitleColor(.systemBlue, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            btn.translatesAutoresizingMaskIntoConstraints = false
            return btn
        }()
        
        private let viewButton: UIButton = {
            let btn = UIButton(type: .system)
            btn.setTitle("View", for: .normal)
            btn.setTitleColor(.systemGreen, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            btn.translatesAutoresizingMaskIntoConstraints = false
            return btn
        }()
    
    var onTradeTap: (() -> Void)?
    var onViewTap: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        
                contentView.addSubview(iconImageView)
            contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(descriptionLabel)
            contentView.addSubview(pendingLabel)
        contentView.addSubview(tradeButton)
        contentView.addSubview(viewButton)
        
        tradeButton.addTarget(self, action: #selector(handleTradeTap), for: .touchUpInside)
        viewButton.addTarget(self, action: #selector(handleViewTap), for: .touchUpInside)
        
        // constraints for each row
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
        iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
        iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            
                descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
                descriptionLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 2),
            descriptionLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -80),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),
            
            pendingLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            pendingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            tradeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            tradeButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            
            viewButton.trailingAnchor.constraint(equalTo: tradeButton.trailingAnchor),
            viewButton.topAnchor.constraint(equalTo: tradeButton.bottomAnchor, constant: 4),
            viewButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    func configure(with coin: MyCoin) {
        // icon config
        if let iconURL = coin.icon, let url = URL(string: iconURL) {
            iconImageView.sd_setImage(with: url, placeholderImage: nil)
        } else {
            iconImageView.image = UIImage(systemName: "bitcoinsign.circle.fill")
            iconImageView.tintColor = .white
        }
        
        // title
        titleLabel.text = coin.name ?? "Untitled Coin"
        
        // ticker and supply in the subtitle
        let ticker = coin.ticker ?? "???"
        let supply = coin.initial_supply ?? "???"
        subtitleLabel.text = "\(ticker) | Supply: \(supply)"
        
        // desc
        descriptionLabel.text = coin.description ?? ""
        
        // trade view buttons or pending based on completion
                if let completed = coin.completed, completed == true {
                    pendingLabel.isHidden = true
                    tradeButton.isHidden = false
                    viewButton.isHidden = false
                } else {
                    pendingLabel.isHidden = false
                    tradeButton.isHidden = true
                    viewButton.isHidden = true
                }
    }
    
    // click each row btns
    @objc private func handleTradeTap() {
        onTradeTap?()
    }
    
    @objc private func handleViewTap() {
        onViewTap?()
    }
}
