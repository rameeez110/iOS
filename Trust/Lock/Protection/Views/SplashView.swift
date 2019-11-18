// Copyright DApps Platform Inc. All rights reserved.

import UIKit

final class SplashView: UIView {
    init() {
        super.init(frame: CGRect.zero)
//        self.backgroundColor = .white
        if #available(iOS 13.0, *) {
            // use the feature only available in iOS 9
            // for ex. UIStackView
            self.backgroundColor = UIColor.systemBackground
        } else {
            // or use some work around
            backgroundColor = .white
        }
        let logoImageView = UIImageView(image: R.image.launch_screen_logo())
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(logoImageView)
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        ])
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
