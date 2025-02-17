// Copyright DApps Platform Inc. All rights reserved.

import UIKit

struct OnboardingPageStyle {
    var titleFont: UIFont {
        return UIFont(name: "Trenda-Regular", size: 23) ?? UIFont.systemFont(ofSize: 23, weight: UIFont.Weight.medium)
    }

    var titleColor: UIColor {
        return UIColor(hex: "438FCA")
    }

    var subtitleFont: UIFont {
        return UIFont(name: "Trenda-Regular", size: 15) ?? UIFont.systemFont(ofSize: 15)
    }

    var subtitleColor: UIColor {
        return UIColor(hex: "69A5D5")
    }
}
