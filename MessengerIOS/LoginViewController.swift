import UIKit

class LoginViewController: UIViewController {
    // MARK: Properties
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var rememberSwitch: UISwitch!
    
    @IBOutlet weak var loginWithGoogleButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backItem = UIBarButtonItem()
        backItem.title = "Login"
        navigationItem.backBarButtonItem = backItem
        
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
        loginButton.isExclusiveTouch = true
        
        // Login with Google Button
        loginWithGoogleButton.applyStyle(
            .social(platform: .google),
            title: "Login with Google",
            icon: UIImage(named: "google_icon")?.withRenderingMode(.alwaysOriginal)
        )
        loginWithGoogleButton.isExclusiveTouch = true
        
        // Remember Switch
        rememberSwitch.transform = CGAffineTransform(scaleX: 0.65, y: 0.65)
        rememberSwitch.onTintColor = .systemPurple
        rememberSwitch.isOn = false
    }
    
    @IBAction func rememberSwitchClick(_ sender: UISwitch) {
        print("Clicked Remember Switch")
    }
    
    @IBAction func loginButtonClick(_ sender: UIButton) {
        //print("Clicked button Login")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainVC = storyboard.instantiateViewController(withIdentifier: "TabBarViewController")
        mainVC.modalPresentationStyle = .fullScreen
        present(mainVC, animated: true)
    }
    
    @IBAction func loginGoogleButtonClick(_ sender: UIButton) {
        print("Clicked button Login with Google")
    }
    
    @IBAction func registerButtonClick(_ sender: UIButton) {
        //print("Clicked button Register")
        let storyboard = UIStoryboard(name: "Auth", bundle: nil)
        if let registerVC = storyboard.instantiateViewController(withIdentifier: "RegisterViewController") as? RegisterViewController {
            navigationController?.pushViewController(registerVC, animated: true)
        }
    }
}
