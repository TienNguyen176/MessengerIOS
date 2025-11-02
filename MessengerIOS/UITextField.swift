import UIKit

extension UITextField {
    func setBeautifulStyle(
        placeholder: String,
        icon: UIImage? = nil,
        cornerRadius: CGFloat = 12,
        borderColor: UIColor = UIColor.systemGray4,
        backgroundColor: UIColor = UIColor.systemGray6,
        textColor: UIColor = .label,
        isPassword: Bool = false
    ) {
        self.placeholder = placeholder
        self.textColor = textColor
        self.font = UIFont.systemFont(ofSize: 16)
        self.backgroundColor = backgroundColor
        
        // Border + corner
        self.layer.cornerRadius = cornerRadius
        self.layer.borderWidth = 1
        self.layer.borderColor = borderColor.cgColor
        self.clipsToBounds = true
        
        // Left icon setup
        if let icon = icon {
            let iconContainer = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
            let iconView = UIImageView(image: icon)
            iconView.tintColor = .systemGray
            iconView.contentMode = .scaleAspectFit
            iconView.frame = CGRect(x: 10, y: 0, width: 20, height: 20)
            iconView.center.y = iconContainer.center.y
            iconContainer.addSubview(iconView)
            self.leftView = iconContainer
        } else {
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 20))
            self.leftView = paddingView
        }
        self.leftViewMode = .always
        
        // Right eye icon for password
        if isPassword {
            let eyeButton = UIButton(type: .system)
            eyeButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
            eyeButton.tintColor = .systemGray
            eyeButton.frame = CGRect(x: 0, y: 0, width: 40, height: 20)
            eyeButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
            
            let eyeContainer = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 20))
            eyeButton.center = eyeContainer.center
            eyeContainer.addSubview(eyeButton)
            
            self.rightView = eyeContainer
            self.rightViewMode = .always
            self.isSecureTextEntry = true
        }
    }
    
    @objc private func togglePasswordVisibility(_ sender: UIButton) {
        self.isSecureTextEntry.toggle()
        let newImage = self.isSecureTextEntry ? "eye.slash" : "eye"
        sender.setImage(UIImage(systemName: newImage), for: .normal)
        
        // fix bug iOS không refresh khi đổi secureTextEntry
        let currentText = self.text
        self.text = ""
        self.text = currentText
    }

    func addFocusEffect() {
        self.addTarget(self, action: #selector(beginFocus), for: .editingDidBegin)
        self.addTarget(self, action: #selector(endFocus), for: .editingDidEnd)
    }

    @objc private func beginFocus() {
        UIView.animate(withDuration: 0.2) {
            self.layer.borderColor = UIColor.systemBlue.cgColor
            self.layer.shadowColor = UIColor.systemBlue.cgColor
            self.layer.shadowOpacity = 0.3
            self.layer.shadowRadius = 6
            self.layer.shadowOffset = .zero
        }
    }

    @objc private func endFocus() {
        UIView.animate(withDuration: 0.2) {
            self.layer.borderColor = UIColor.systemGray4.cgColor
            self.layer.shadowOpacity = 0
        }
    }
}
