//
//  LaunchCoinViewController.swift
//  CryptoLaunch
//
//  Created by Brian Todi on 2025-02-20.
//

import UIKit
import Alamofire

class LaunchCoinViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // setup scrollview so smaller phones fit page aswell
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // title
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Launch a Coin"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // coin image
    private let coinImageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = UIColor(red: 32/255, green: 31/255, blue: 65/255, alpha: 1.0)
        iv.layer.cornerRadius = 8
        iv.clipsToBounds = true
        iv.contentMode = .center
        iv.image = UIImage(systemName: "photo.on.rectangle")
        iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // special function to create a text field
    private func createTextField() -> UITextField {
        let tf = UITextField()
        
        // white small
            tf.textColor = .white
            tf.font = UIFont.systemFont(ofSize: 16)
            tf.autocapitalizationType = .none
            tf.autocorrectionType = .no
            tf.borderStyle = .none
            tf.translatesAutoresizingMaskIntoConstraints = false

        // clean underline
        let underline = UIView()
        underline.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        underline.translatesAutoresizingMaskIntoConstraints = false
        tf.addSubview(underline)
        NSLayoutConstraint.activate([
            underline.heightAnchor.constraint(equalToConstant: 1),
            underline.leadingAnchor.constraint(equalTo: tf.leadingAnchor),
            underline.trailingAnchor.constraint(equalTo: tf.trailingAnchor),
            underline.bottomAnchor.constraint(equalTo: tf.bottomAnchor)
        ])

        tf.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return tf
    }

    // setup labels and make text fields for each metadata
    private let nameLabel = LaunchCoinViewController.label(with: "Name *")
    private lazy var nameTextField: UITextField = { createTextField() }()

    private let tickerLabel = LaunchCoinViewController.label(with: "Ticker (e.g., 490COIN) *")
    private lazy var tickerTextField: UITextField = { createTextField() }()

    private let descriptionLabel = LaunchCoinViewController.label(with: "Description *")
    private lazy var descriptionTextField: UITextField = { createTextField() }()

    private let initialSupplyLabel = LaunchCoinViewController.label(with: "Initial Supply (e.g., 1000000) *")
    private lazy var initialSupplyTextField: UITextField = { createTextField() }()

    private let emailLabel = LaunchCoinViewController.label(with: "Email (e.g., john@doe.com)*")
    private lazy var emailTextField: UITextField = { createTextField() }()

        // blueish launch button
        private let launchButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("Launch Token", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            button.backgroundColor = UIColor(red: 45/255, green: 120/255, blue: 250/255, alpha: 1.0)
            button.layer.cornerRadius = 8
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()

    private static func label(with text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    override func viewDidLoad() {
            // call all the setup
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 20/255, green: 19/255, blue: 45/255, alpha: 1.0)
        setupScrollView()
        
        // dismiss taps
        setupTapToDismissKeyboard()
        setupImagePickerTap()
        launchButton.addTarget(self, action: #selector(launchTokenTapped), for: .touchUpInside)
    }

    // scrollview setup
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(activityIndicator)

        // constraints setup for page
            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

                contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

                activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            ])

        [titleLabel, coinImageView, nameLabel, nameTextField, tickerLabel, tickerTextField,
         descriptionLabel, descriptionTextField, initialSupplyLabel, initialSupplyTextField,
         emailLabel, emailTextField, launchButton].forEach { contentView.addSubview($0) }

        // mian form contraints setup
        NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
                titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),

                coinImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
                coinImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                coinImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                coinImageView.heightAnchor.constraint(equalToConstant: 100),

                nameLabel.topAnchor.constraint(equalTo: coinImageView.bottomAnchor, constant: 24),
                nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                nameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
                nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            tickerLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 24),
            tickerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tickerTextField.topAnchor.constraint(equalTo: tickerLabel.bottomAnchor, constant: 8),
            tickerTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tickerTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            descriptionLabel.topAnchor.constraint(equalTo: tickerTextField.bottomAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionTextField.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 8),
            descriptionTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            initialSupplyLabel.topAnchor.constraint(equalTo: descriptionTextField.bottomAnchor, constant: 24),
            initialSupplyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            initialSupplyTextField.topAnchor.constraint(equalTo: initialSupplyLabel.bottomAnchor, constant: 8),
            initialSupplyTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            initialSupplyTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

                emailLabel.topAnchor.constraint(equalTo: initialSupplyTextField.bottomAnchor, constant: 24),
                emailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                emailTextField.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 8),
                emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            launchButton.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 40),
            launchButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            launchButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            launchButton.heightAnchor.constraint(equalToConstant: 50),
            launchButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    // dismiss on tap
    private func setupTapToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    
//    open image button
private func setupImagePickerTap() {
    coinImageView.isUserInteractionEnabled = true
    let tap = UITapGestureRecognizer(target: self, action: #selector(imagePlaceholderTapped))
    coinImageView.addGestureRecognizer(tap)
}

@objc private func imagePlaceholderTapped() {
    let picker = UIImagePickerController()
    picker.sourceType = .photoLibrary
    picker.delegate = self
    present(picker, animated: true)
}

    
    // launch button tpaped
    @objc private func launchTokenTapped() {
//        print("tapped")
        guard let name = nameTextField.text, !name.isEmpty,
              let ticker = tickerTextField.text, !ticker.isEmpty,
              let description = descriptionTextField.text, !description.isEmpty,
              let initialSupply = initialSupplyTextField.text, !initialSupply.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let image = coinImageView.image else {
            
            // alert for incomplete
//            print("not finished")
            presentAlert(title: "Incomplete Form", message: "Please fill in all fields and add an image.")
            return
        }

            // broken image
        let userId = UserDefaults.standard.string(forKey: "user_id") ?? ""
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            presentAlert(title: "Image Error", message: "Could not process the selected image.")
            return
        }

        // setup data
        let url = "https://crypto-launch-e430d83afb8b.herokuapp.com/cryptolaunch/launchCoin"
        let parameters: [String: String] = [
            "user_id": userId,
            "name": name,
            "ticker": ticker,
            "description": description,
            "initial_supply": initialSupply,
            "email": email
        ]

        activityIndicator.startAnimating()
        launchButton.isEnabled = false

            // send the data
        AF.upload(multipartFormData: { multipartFormData in
            for (key, value) in parameters {
                if let data = value.data(using: .utf8) {
                    multipartFormData.append(data, withName: key)
                }
            }
            multipartFormData.append(imageData, withName: "image", fileName: "coin.jpg", mimeType: "image/jpeg")
        }, to: url, method: .post)
        .validate()
        .responseJSON { response in
            self.activityIndicator.stopAnimating()
            self.launchButton.isEnabled = true

            switch response.result {
            case .success(let json):
//                print("sent")
                print("Launch coin success:", json)
                self.presentAlert(title: "Success", message: "Your coin has been succesfully launched. View it on the My Coins page in the menu to trade it.")
            case .failure(let error):
//                print("broke")
                print("Launch coin error:", error)
                self.presentAlert(title: "Error", message: "Failed to launch coin. Please try again.")
            }
        }
    }

    // alert helper
    private func presentAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// select image extension
extension LaunchCoinViewController {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            coinImageView.image = selectedImage
        }
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
