import UIKit
import FirebaseAuth
import FirebaseDatabase

class ProfileViewController: UIViewController {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!

    private var ref: DatabaseReference!
    private var handle: DatabaseHandle?

    private var currentUserID: String {
        return Auth.auth().currentUser?.uid ?? ""
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("🔥 CURRENT UID:", currentUserID)


        ref = Database.database().reference()

        checkLoginState()
        setupUI()
        loadUserProfile()
    }
    

    // Nếu user chưa login → quay về Login
    func checkLoginState() {
        if Auth.auth().currentUser == nil {
            navigateToLogin()
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        avatarImageView.layer.cornerRadius = avatarImageView.frame.width / 2
        avatarImageView.clipsToBounds = true
    }

    func setupUI() {
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
    }


    func loadUserProfile() {
        guard !currentUserID.isEmpty else { return }

        handle = ref.child("users").child(currentUserID)
            .observe(.value) { snapshot in

                guard let userData = snapshot.value as? [String: Any] else {
                    print("❌ Không tìm thấy dữ liệu user")
                    return
                }

                let username = userData["user_name"] as? String ?? "Unknown User"
                let bio = userData["bio"] as? String ?? ""
                let avatarUrl = userData["avatarUrl"] as? String ?? ""

                self.usernameLabel.text = username
                self.infoLabel.text = bio.isEmpty ? "User information" : bio

                if avatarUrl.isEmpty {
                    // Dùng ảnh mặc định
                    self.avatarImageView.image = UIImage(systemName: "person.circle.fill")
                } else {
                    // Load ảnh từ URL
                    self.loadAvatar(from: avatarUrl)
                }
            }
    }

    func loadAvatar(from url: String) {
        guard let imageURL = URL(string: url) else { return }

        URLSession.shared.dataTask(with: imageURL) { data, _, _ in
            if let data = data {
                DispatchQueue.main.async {
                    self.avatarImageView.image = UIImage(data: data)
                }
            }
        }.resume()
    }

    @IBAction func logoutButtonClick(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.set(false, forKey: "rememberUser")
            navigateToLogin()

        } catch {
            print("❌ Logout error: \(error.localizedDescription)")
        }
    }

    func navigateToLogin() {
        let storyboard = UIStoryboard(name: "Auth", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}
