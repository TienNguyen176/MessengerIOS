import UIKit

enum ButtonStyle {
    case primary
    case outlined
    case gradient(colors: [UIColor])
    case social(platform: SocialPlatform)
    case custom(background: UIColor, textColor: UIColor)
}

enum SocialPlatform {
    case google
    case facebook
    case apple
}

extension UIButton {

    func applyStyle(
        _ style: ButtonStyle,
        title: String,
        icon: UIImage? = nil
    ) {
        switch style {
        case .primary:
            configureModernButton(
                title: title,
                background: .systemBlue,
                foreground: .white,
                icon: icon
            )

        case .outlined:
            configureModernButton(
                title: title,
                background: .clear,
                foreground: .systemBlue,
                icon: icon,
                borderColor: .systemBlue,
                borderWidth: 1.2
            )

        case .gradient(let colors):
            configureModernButton(
                title: title,
                background: .clear,
                foreground: .white,
                icon: icon
            )
            applyGradient(colors: colors)

        case .social(let platform):
            setSocialStyle(for: platform, title: title, icon: icon)

        case .custom(let background, let textColor):
            configureModernButton(
                title: title,
                background: background,
                foreground: textColor,
                icon: icon
            )
        }
    }

    // MARK: - Base Button
    private func configureModernButton(
        title: String,
        background: UIColor,
        foreground: UIColor,
        icon: UIImage? = nil,
        borderColor: UIColor? = nil,
        borderWidth: CGFloat = 0
    ) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = icon?.withRenderingMode(.alwaysOriginal)
        config.imagePlacement = .leading
        config.imagePadding = icon == nil ? 0 : 8
        config.baseBackgroundColor = background
        config.baseForegroundColor = foreground
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)

        self.configuration = config
        layer.cornerRadius = 10
        layer.masksToBounds = false

        if let borderColor = borderColor {
            layer.borderColor = borderColor.cgColor
            layer.borderWidth = borderWidth
        }

        // Shadow nhẹ
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4

        // Animation nhấn
        addTarget(self, action: #selector(pressDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(pressUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
    }

    // MARK: - Social Buttons
    private func setSocialStyle(for platform: SocialPlatform, title: String, icon: UIImage?) {
        var config = UIButton.Configuration.filled()
        config.title = title
        if let icon = icon {
            let resizedIcon = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24)).image { _ in
                icon.draw(in: CGRect(origin: .zero, size: CGSize(width: 24, height: 24)))
            }
            config.image = resizedIcon.withRenderingMode(.alwaysOriginal)
        }
        config.imagePlacement = .leading
        config.imagePadding = 10
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18)

        switch platform {
        case .google:
            config.baseBackgroundColor = .white
            config.baseForegroundColor = .black
            layer.borderColor = UIColor.systemGray4.cgColor
            layer.borderWidth = 1

        case .facebook:
            config.baseBackgroundColor = UIColor(red: 24/255, green: 119/255, blue: 242/255, alpha: 1)
            config.baseForegroundColor = .white

        case .apple:
            config.baseBackgroundColor = .black
            config.baseForegroundColor = .white
        }

        self.configuration = config
        layer.cornerRadius = 10
        layer.masksToBounds = false

        // Shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
    }

    // MARK: - Gradient
    func applyGradient(colors: [UIColor], cornerRadius: CGFloat = 12) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = cornerRadius

        layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        layer.insertSublayer(gradientLayer, at: 0)
    }

    // MARK: - Animation
    @objc private func pressDown() {
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            self.alpha = 0.9
        }
    }

    @objc private func pressUp() {
        UIView.animate(withDuration: 0.15) {
            self.transform = .identity
            self.alpha = 1.0
        }
    }
}
