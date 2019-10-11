// Copyright DApps Platform Inc. All rights reserved.
// Copyright Ether-1 Developers. All rights reserved.
// Copyright Xerom Developers. All rights reserved.

import UIKit

final class SplashView: UIView {
    init() {
        super.init(frame: CGRect.zero)
        backgroundColor = .white
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
