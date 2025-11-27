import UIKit
import FirebaseAuth
import FirebaseDatabase

class FriendRequestsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private var ref = Database
        .database(url: "https://messengerios-b2aa7-default-rtdb.asia-southeast1.firebasedatabase.app/")
        .reference()

    private var requests: [(user: UserModel, requestId: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FriendRequestCell")

        loadFriendRequests()
    }

    // MARK: - Load Friend Requests
    func loadFriendRequests() {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        // Lấy danh sách receivedRequests
        ref.child("users").child(uid).child("friendRequests").child("receivedRequests")
            .observeSingleEvent(of: .value) { snap in

                guard let data = snap.value as? [String: Any] else {
                    print("⚠️ Không có lời mời kết bạn")
                    self.requests.removeAll()
                    self.tableView.reloadData()
                    return
                }

                self.requests.removeAll()

                for (senderId, _) in data {
                    // Tải thông tin người gửi
                    self.ref.child("users").child(senderId)
                        .observeSingleEvent(of: .value) { userSnap in

                            if let user = parseUser(snapshot: userSnap) {
                                self.requests.append((user, senderId))
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                }
                            }
                        }
                }
            }
    }

    // MARK: - Accept Friend
    func acceptFriend(senderId: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let users = ref.child("users")

        // Thêm bạn bè 2 chiều
        users.child(uid).child("friends").child(senderId).setValue(true)
        users.child(senderId).child("friends").child(uid).setValue(true)

        // Xóa request
        users.child(uid).child("friendRequests").child("receivedRequests").child(senderId).removeValue()
        users.child(senderId).child("friendRequests").child("sentRequests").child(uid).removeValue()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.loadFriendRequests()
        }
    }

    // MARK: - Decline Friend
    func declineFriend(senderId: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let users = ref.child("users")

        // Xóa request 2 chiều
        users.child(uid).child("friendRequests").child("receivedRequests").child(senderId).removeValue()
        users.child(senderId).child("friendRequests").child("sentRequests").child(uid).removeValue()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.loadFriendRequests()
        }
    }
}

// MARK: - TABLEVIEW
extension FriendRequestsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return requests.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "FriendRequestCell",
            for: indexPath
        )

        let user = requests[indexPath.row].user

        // MARK: - Populate UI
        cell.textLabel?.text = user.userName

        if !user.avatarUrl.isEmpty, let url = URL(string: user.avatarUrl) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data {
                    DispatchQueue.main.async {
                        cell.imageView?.image = UIImage(data: data)
                        cell.imageView?.layer.cornerRadius = 25
                        cell.imageView?.clipsToBounds = true
                    }
                }
            }.resume()
        } else {
            cell.imageView?.image = UIImage(systemName: "person.circle.fill")
        }

        return cell
    }

    // MARK: - Row Actions Accept / Decline
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {

        let senderId = requests[indexPath.row].requestId

        let accept = UIContextualAction(style: .normal, title: "Accept") { _, _, done in
            self.acceptFriend(senderId: senderId)
            done(true)
        }
        accept.backgroundColor = .systemGreen

        let decline = UIContextualAction(style: .destructive, title: "Decline") { _, _, done in
            self.declineFriend(senderId: senderId)
            done(true)
        }

        return UISwipeActionsConfiguration(actions: [decline, accept])
    }
}
