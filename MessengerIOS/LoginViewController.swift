import UIKit

class LoginViewController: UIViewController {
    // MARK: Properties
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var rememberSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
    }
    
    private func setupUI() {
        
        // Email Field
        emailTextField.setBeautifulStyle(
            placeholder: "Email",
            icon: UIImage(systemName: "envelope.fill")
        )
        emailTextField.addFocusEffect()

        // Password Field
        passwordTextField.setBeautifulStyle(
            placeholder: "Password",
            icon: UIImage(systemName: "lock.fill"),
            isPassword: true
        )
        passwordTextField.addFocusEffect()
        
        // Login Button
        loginButton.applyStyle(
            .custom(background: .systemPurple, textColor: .white),
            title: "Login"
        )
        
        // Remember Switch
        rememberSwitch.transform = CGAffineTransform(scaleX: 0.65, y: 0.65)
        rememberSwitch.onTintColor = .systemPurple
        rememberSwitch.isOn = false
    }

    @IBAction func loginButtonClick(_ sender: UIButton) {
        print("Clicked button Login")
    }
    
}
