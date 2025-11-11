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
        
        // Username Field
        usernameTextField.setBeautifulStyle(
            placeholder: "Username",
            icon: UIImage(systemName: "person.fill")
        )
        usernameTextField.addFocusEffect()
        
        // Email Field
        emailTextField.setBeautifulStyle(
            placeholder: "Email",
            icon: UIImage(systemName: "envelope.fill")
        )
        emailTextField.addFocusEffect()
        
        // DOB Field
        dobTextField.setBeautifulStyle(
            placeholder: "Date of Birth",
            icon: UIImage(systemName: "calendar")
        )
        dobTextField.addFocusEffect()

        // Password Field
        passwordTextField.setBeautifulStyle(
            placeholder: "Password",
            icon: UIImage(systemName: "lock.fill"),
            isPassword: true
        )
        passwordTextField.addFocusEffect()
        
        // Confỉrm Password Field
        prePasswordTextField.setBeautifulStyle(
            placeholder: "Confỉrm Password",
            icon: UIImage(systemName: "lock.fill"),
            isPassword: true
        )
        prePasswordTextField.addFocusEffect()
        
        // Register Button
        registerButton.applyStyle(
            .custom(background: .systemPurple, textColor: .white),
            title: "Register"
        )
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
        datePicker?.maximumDate = Date() // Không cho chọn tương lai
        datePicker?.locale = Locale(identifier: "en_GB") // dd/MM/yyyy
        
        dobTextField.inputView = datePicker
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done,
                                         target: self,
                                         action: #selector(donePressed))
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
        
        dobTextField.resignFirstResponder() // ẩn picker
    }
    
    
    @IBAction func maleTapped(_ sender: UIButton) {
        selectedGender = "male"
        updateGenderUI()
    }
    
    @IBAction func femaleTapped(_ sender: UIButton) {
        selectedGender = "female"
        updateGenderUI()
    }
    
    @IBAction func registerButtonClick(_ sender: UIButton) {
        print("Register Button Click")
    }
    
    @IBAction func loginBackButtonClick(_ sender: UIButton) {
        //print("Back Login Screen")
        navigationController?.popViewController(animated: true)
    }
}
