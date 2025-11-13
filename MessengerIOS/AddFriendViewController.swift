import UIKit
import FirebaseAuth
import FirebaseDatabase

class AddFriendViewController: UIViewController {

    @IBOutlet weak var searchEmailTextField: UITextField!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var addFriendButton: UIButton!

    private var ref = Database
        .database(url: "https://messengerios-b2aa7-default-rtdb.asia-southeast1.firebasedatabase.app/")
        .reference()

    private var foundUser: UserModel?

    override func viewDidLoad() {
        super.viewDidLoad()

        nameLabel.text = "Name: "
        emailLabel.text = "Email: "
        addFriendButton.isEnabled = false
        addFriendButton.alpha = 0.5
    }

    // MARK: - ACTION SEARCH USER
    @IBAction func searchUserTapped(_ sender: Any) {
        guard let email = searchEmailTextField.text?.lowercased(), !email.isEmpty else {
            showAlert("Lỗi", "Vui lòng nhập email")
            return
        }

        searchUserByEmail(email)
    }

    // MARK: - SEARCH USER BY EMAIL
    private func searchUserByEmail(_ email: String) {

        ref.child("users").observeSingleEvent(of: .value) { snap in
            guard let allUsers = snap.value as? [String: Any] else {
                self.showAlert("Lỗi", "Không tải được danh sách người dùng")
                return
            }

            var targetId: String?
            var userData: [String: Any]?

            // Tìm theo email
            for (uid, value) in allUsers {
                if let user = value as? [String: Any],
                   let userEmail = user["email"] as? String,
                   userEmail.lowercased() == email {

                    targetId = uid
                    userData = user
                    break
                }
            }

            guard let uid = targetId, var data = userData else {
                self.showAlert("Không tìm thấy", "Không tồn tại người dùng với email này")
                self.clearFoundUserUI()
                return
            }

            // Không cho tìm chính mình
            if uid == Auth.auth().currentUser?.uid {
                self.showAlert("Không hợp lệ", "Bạn không thể thêm chính mình")
                self.clearFoundUserUI()
                return
            }

            // Inject userId + format key để parseUser()
            data["userId"] = uid
            if let v = data["user_name"] { data["userName"] = v }

            do {
                let json = try JSONSerialization.data(withJSONObject: data)
                let user = try JSONDecoder().decode(UserModel.self, from: json)
                self.foundUser = user

                DispatchQueue.main.async {
                    self.updateFoundUserUI(user)
                    self.checkRelationshipStatus(with: user.userId)
                }

            } catch {
                print("Decode error:", error)
            }
        }
    }

    // MARK: - CHECK RELATIONSHIP
    private func checkRelationshipStatus(with otherId: String) {
        guard let myId = Auth.auth().currentUser?.uid else { return }

        let users = ref.child("users")

        // Check bạn bè
        users.child(myId).child("friends").child(otherId)
            .observeSingleEvent(of: .value) { snap in

                if snap.exists() {
                    self.disableAddButton("Đã là bạn bè")
                    return
                }

                // Check sentRequests
                users.child(myId).child("friendRequests").child("sentRequests").child(otherId)
                    .observeSingleEvent(of: .value) { snap in

                        if snap.exists() {
                            self.disableAddButton("Đã gửi lời mời")
                            return
                        }

                        // Check receivedRequests
                        users.child(myId).child("friendRequests").child("receivedRequests").child(otherId)
                            .observeSingleEvent(of: .value) { snap in

                                if snap.exists() {
                                    self.disableAddButton("Người này đã gửi lời mời cho bạn")
                                    return
                                }

                                // OK
                                self.enableAddButton()
                            }
                    }
            }
    }

    // MARK: - ENABLE / DISABLE BUTTON
    private func enableAddButton() {
        DispatchQueue.main.async {
            self.addFriendButton.isEnabled = true
            self.addFriendButton.alpha = 1.0
            self.addFriendButton.setTitle("Add Friend", for: .normal)
        }
    }

    private func disableAddButton(_ title: String) {
        DispatchQueue.main.async {
            self.addFriendButton.isEnabled = false
            self.addFriendButton.alpha = 0.5
            self.addFriendButton.setTitle(title, for: .normal)
        }
    }

    // MARK: - SEND REQUEST
    @IBAction func addFriendTapped(_ sender: Any) {
        guard let target = foundUser else { return }
        guard let myId = Auth.auth().currentUser?.uid else { return }

        let users = ref.child("users")

        // sentRequests (my node)
        users.child(myId).child("friendRequests").child("sentRequests")
            .child(target.userId)
            .setValue([
                "sent_at": Date().timeIntervalSince1970,
                "status_id": "pending"
            ])

        // receivedRequests (target node)
        users.child(target.userId).child("friendRequests").child("receivedRequests")
            .child(myId)
            .setValue([
                "sent_by": myId,
                "sent_at": Date().timeIntervalSince1970,
                "status_id": "pending"
            ])

        showAlert("Thành công", "Đã gửi lời mời kết bạn 🎉")
        disableAddButton("Đã gửi lời mời")
    }

    // MARK: - UPDATE UI
    private func updateFoundUserUI(_ user: UserModel) {
        nameLabel.text = "Name: \(user.userName)"
        emailLabel.text = "Email: \(user.email)"
    }

    private func clearFoundUserUI() {
        nameLabel.text = "Name: "
        emailLabel.text = "Email: "
        addFriendButton.isEnabled = false
        addFriendButton.alpha = 0.5
    }

    // MARK: - ALERT
    private func showAlert(_ title: String, _ msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
