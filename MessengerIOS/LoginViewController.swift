import UIKit
import FirebaseAuth
import GoogleSignIn

class LoginViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var rememberSwitch: UISwitch!
    @IBOutlet weak var loginWithGoogleButton: UIButton!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigation()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkRememberedUser()
    }

    // MARK: - UI Setup
    private func setupNavigation() {
        let backItem = UIBarButtonItem()
        backItem.title = "Login"
        navigationItem.backBarButtonItem = backItem
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
        loginButton.applyStyle(.custom(background: .systemPurple, textColor: .white),
                               title: "Login")
        loginButton.isExclusiveTouch = true

        // Login with Google Button
        loginWithGoogleButton.applyStyle(.social(platform: .google),
                                         title: "Login with Google",
                                         icon: UIImage(named: "google_icon")?.withRenderingMode(.alwaysOriginal))
        loginWithGoogleButton.isExclusiveTouch = true

        // Remember Switch
        rememberSwitch.transform = CGAffineTransform(scaleX: 0.65, y: 0.65)
        rememberSwitch.onTintColor = .systemPurple
        rememberSwitch.isOn = UserDefaults.standard.bool(forKey: "rememberUser")
    }

    private func checkRememberedUser() {
        if Auth.auth().currentUser != nil,
           UserDefaults.standard.bool(forKey: "rememberUser") {
            navigateToMain()
        }
    }

    // MARK: - Actions
    @IBAction func rememberSwitchClick(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "rememberUser")
        print("Remember me: \(sender.isOn)")
    }

    @IBAction func loginButtonClick(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Thiếu thông tin", message: "Vui lòng nhập email và mật khẩu.")
            return
        }

        toggleLoading(true)

        AuthService.shared.login(email: email, password: password, remember: rememberSwitch.isOn) { [weak self] result in
            guard let self = self else { return }
            self.toggleLoading(false)

            switch result {
            case .success():
                print("Login success: \(email)")
                self.navigateToMain()
            case .failure(let error):
                self.showAlert(title: "Đăng nhập thất bại", message: error.localizedDescription)
            }
        }
    }

    @IBAction func loginGoogleButtonClick(_ sender: UIButton) {
        AuthService.shared.loginWithGoogle(presentingVC: self, remember: rememberSwitch.isOn) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let user):
                print("Google login success: \(user.email ?? "")")
                self.navigateToMain()
            case .failure(let error):
                self.showAlert(title: "Google Login Failed", message: error.localizedDescription)
            }
        }
    }

    @IBAction func registerButtonClick(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Auth", bundle: nil)
        if let registerVC = storyboard.instantiateViewController(withIdentifier: "RegisterViewController") as? RegisterViewController {
            navigationController?.pushViewController(registerVC, animated: true)
        }
    }

    // MARK: - Helper Methods
    private func navigateToMain() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainVC = storyboard.instantiateViewController(withIdentifier: "TabBarViewController")
        mainVC.modalPresentationStyle = .fullScreen
        present(mainVC, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func toggleLoading(_ isLoading: Bool) {
        loginButton.isEnabled = !isLoading
        loginButton.setTitle(isLoading ? "Đang đăng nhập..." : "Login", for: .normal)
    }
}
