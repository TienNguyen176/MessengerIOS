import UIKit

class RegisterViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var dobTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var prePasswordTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var maleButton: UIButton!
    @IBOutlet weak var femaleButton: UIButton!
    
    private var datePicker: UIDatePicker?
    private var selectedGender: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backImage = UIImage(systemName: "chevron.left")
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.backIndicatorImage = backImage
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = backImage
        
        setupUI()
        setupDatePicker()
        updateGenderUI()
    }
    
    private func setupUI() {
        usernameTextField.setBeautifulStyle(placeholder: "Username", icon: UIImage(systemName: "person.fill"))
        usernameTextField.addFocusEffect()
        
        emailTextField.setBeautifulStyle(placeholder: "Email", icon: UIImage(systemName: "envelope.fill"))
        emailTextField.addFocusEffect()
        
        dobTextField.setBeautifulStyle(placeholder: "Date of Birth", icon: UIImage(systemName: "calendar"))
        dobTextField.addFocusEffect()
        
        passwordTextField.setBeautifulStyle(placeholder: "Password", icon: UIImage(systemName: "lock.fill"), isPassword: true)
        passwordTextField.addFocusEffect()
        
        prePasswordTextField.setBeautifulStyle(placeholder: "Confirm Password", icon: UIImage(systemName: "lock.fill"), isPassword: true)
        prePasswordTextField.addFocusEffect()
        
        registerButton.applyStyle(.custom(background: .systemPurple, textColor: .white), title: "Register")
        registerButton.isExclusiveTouch = true
    }
    
    private func updateGenderUI() {
        let selectedImage = UIImage(systemName: "largecircle.fill.circle")
        let unselectedImage = UIImage(systemName: "circle")

        maleButton.setImage(selectedGender == "male" ? selectedImage : unselectedImage, for: .normal)
        femaleButton.setImage(selectedGender == "female" ? selectedImage : unselectedImage, for: .normal)
    }
    
    private func setupDatePicker() {
        datePicker = UIDatePicker()
        datePicker?.datePickerMode = .date
        datePicker?.preferredDatePickerStyle = .wheels
        datePicker?.maximumDate = Date()
        datePicker?.locale = Locale(identifier: "en_GB")
        
        dobTextField.inputView = datePicker
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePressed))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([space, doneButton], animated: false)
        dobTextField.inputAccessoryView = toolbar
    }
    
    @objc private func donePressed() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        
        if let date = datePicker?.date {
            dobTextField.text = formatter.string(from: date)
        }
        
        dobTextField.resignFirstResponder()
    }
    
    // MARK: - Gender selection
    @IBAction func maleTapped(_ sender: UIButton) {
        selectedGender = "male"
        updateGenderUI()
    }
    
    @IBAction func femaleTapped(_ sender: UIButton) {
        selectedGender = "female"
        updateGenderUI()
    }

    // MARK: - Register button
    @IBAction func registerButtonClick(_ sender: UIButton) {
        guard let name = usernameTextField.text, !name.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let dobText = dobTextField.text, !dobText.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirm = prePasswordTextField.text, !confirm.isEmpty else {
            showAlert(title: "Thiếu thông tin", message: "Vui lòng nhập đầy đủ các trường.")
            return
        }

        guard password == confirm else {
            showAlert(title: "Mật khẩu không khớp", message: "Vui lòng nhập lại mật khẩu.")
            return
        }

        guard let selectedGender = selectedGender else {
            showAlert(title: "Chưa chọn giới tính", message: "Vui lòng chọn Nam hoặc Nữ.")
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        guard let dob = formatter.date(from: dobText) else {
            showAlert(title: "Ngày sinh không hợp lệ", message: "Vui lòng chọn lại ngày sinh.")
            return
        }

        let genderId = (selectedGender == "male") ? "type_01" : "type_02"

        registerButton.isEnabled = false
        registerButton.setTitle("Đang đăng ký...", for: .normal)
        
        AuthService.shared.register(
            name: name,
            email: email,
            password: password,
            dob: dob,
            genderId: genderId
        ) { result in
            DispatchQueue.main.async {
                self.registerButton.isEnabled = true
                self.registerButton.setTitle("Register", for: .normal)
                
                switch result {
                case .success:
                    self.showAlert(title: "Thành công", message: "Đăng ký thành công!") {
                        self.navigationController?.popViewController(animated: true)
                    }
                case .failure(let error):
                    self.showAlert(title: "Lỗi", message: error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func loginBackButtonClick(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Alert helper
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completion?()
            })
            self.present(alert, animated: true)
        }
    }
}
