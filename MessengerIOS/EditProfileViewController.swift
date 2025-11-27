import UIKit
import FirebaseDatabase
import FirebaseAuth

class EditProfileViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var bioTextField: UITextField!
    @IBOutlet weak var genderSegment: UISegmentedControl!
    @IBOutlet weak var dobPicker: UIDatePicker!
    @IBOutlet weak var allowMessagePicker: UIPickerView!

    // MARK: - Firebase
    private var ref: DatabaseReference!

    private var currentUserID: String {
        return Auth.auth().currentUser?.uid ?? ""
    }

    // MARK: - Allow Message Options
    let allowMessageOptions = ["everyone", "friends", "private"]

    let allowMessageMap: [String: String] = [
        "type_03": "everyone",
        "type_04": "friends",
        "type_05": "private"
    ]

    let reverseAllowMessageMap: [String: String] = [
        "everyone": "type_03",
        "friends": "type_04",
        "private": "type_05"
    ]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        ref = Database.database(url: "https://messengerios-b2aa7-default-rtdb.asia-southeast1.firebasedatabase.app/").reference()

        setupUI()
        setupPicker()
        loadUserData()
    }

    // MARK: - UI Setup
    func setupUI() {
        avatarImageView.layer.cornerRadius = avatarImageView.frame.width / 2
        avatarImageView.clipsToBounds = true
    }

    func setupPicker() {
        allowMessagePicker.delegate = self
        allowMessagePicker.dataSource = self
    }

    // MARK: - Load User Data
    func loadUserData() {
        ref.child("users").child(currentUserID).observeSingleEvent(of: .value) { snapshot in

            guard let data = snapshot.value as? [String: Any] else { return }

            self.usernameTextField.text = data["user_name"] as? String ?? ""
            self.emailTextField.text = data["email"] as? String ?? ""
            self.bioTextField.text = data["bio"] as? String ?? ""

            // Gender
            if let genderID = data["gender_id"] as? String {
                self.genderSegment.selectedSegmentIndex = (genderID == "type_02") ? 1 : 0
            }

            // DOB
            if let dobString = data["dob"] as? String,
               let date = self.stringToDate(dobString) {
                self.dobPicker.date = date
            }

            // Allow Messages — Mapping Firebase → Display
            if let firebaseValue = data["allowMessagesFrom"] as? String,
               let readableText = self.allowMessageMap[firebaseValue],
               let index = self.allowMessageOptions.firstIndex(of: readableText) {
                self.allowMessagePicker.selectRow(index, inComponent: 0, animated: false)
            }
        }
    }

    // MARK: - Date Helpers
    func stringToDate(_ isoString: String) -> Date? {
        ISO8601DateFormatter().date(from: isoString)
    }

    func dateToString(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    // MARK: - Save Profile
    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {

        let genderID = genderSegment.selectedSegmentIndex == 0 ? "type_01" : "type_02"

        // Picker → get readable (everyone/friends/private)
        let readable = allowMessageOptions[allowMessagePicker.selectedRow(inComponent: 0)]

        // Convert → Firebase format
        let allow = reverseAllowMessageMap[readable] ?? "type_03"

        let updates: [String: Any] = [
            "user_name": usernameTextField.text ?? "",
            "bio": bioTextField.text ?? "",
            "gender_id": genderID,
            "dob": dateToString(dobPicker.date),
            "allowMessagesFrom": allow
        ]

        ref.child("users").child(currentUserID).updateChildValues(updates) { error, _ in

            if let error = error {
                self.showAlert("Error", error.localizedDescription)
                return
            }

            self.showAlert("Success", "Profile updated!") {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    func showAlert(_ title: String, _ message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        present(alert, animated: true)
    }
}

// MARK: - PickerView
extension EditProfileViewController: UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        allowMessageOptions.count
    }

    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        return allowMessageOptions[row]
    }
}
