import UIKit
import FirebaseDatabase
import FirebaseAuth

import FirebaseDatabase

func parseUser(snapshot: DataSnapshot) -> UserModel? {
    guard var data = snapshot.value as? [String: Any] else {
        print("❌ Snapshot không đúng định dạng User")
        return nil
    }

    // Inject userId
    data["userId"] = snapshot.key

    // Remap keys để match UserModel
    if let v = data["user_name"] { data["userName"] = v }
    if let v = data["gender_id"] { data["genderId"] = v }
    if let v = data["chat_ids"] { data["chatIds"] = v }

    // Status
    if let status = data["status"] as? [String: Any] {
        var s = status
        if let v = status["status_id"] { s["statusId"] = v }
        if let v = status["last_seen"] { s["lastSeen"] = v }
        data["status"] = s
    }

    // Friend Requests
    if let fr = data["friendRequests"] as? [String: Any] {
        var newFr = fr

        // Sent
        if let sent = fr["sentRequests"] as? [String: Any] {
            var formatted = [String: Any]()
            for (k, v) in sent {
                if var s = v as? [String: Any] {
                    if let v = s["sent_at"] { s["sentAt"] = v }
                    if let v = s["status_id"] { s["statusId"] = v }
                    formatted[k] = s
                }
            }
            newFr["sentRequests"] = formatted
        }

        // Received
        if let received = fr["receivedRequests"] as? [String: Any] {
            var formatted = [String: Any]()
            for (k, v) in received {
                if var r = v as? [String: Any] {
                    if let v = r["sent_by"] { r["sentBy"] = v }
                    if let v = r["sent_at"] { r["sentAt"] = v }
                    if let v = r["status_id"] { r["statusId"] = v }
                    formatted[k] = r
                }
            }
            newFr["receivedRequests"] = formatted
        }

        data["friendRequests"] = newFr
    }

    // Decode
    do {
        let json = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(UserModel.self, from: json)
    } catch {
        print("❌ Decode UserModel lỗi:", error)
        return nil
    }
}
class FriendListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private var ref = Database
        .database(url: "https://messengerios-b2aa7-default-rtdb.asia-southeast1.firebasedatabase.app/")
        .reference()

    var friends: [UserModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self

        loadFriends()
    }

    // MARK: - Load danh sách bạn bè
    func loadFriends() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ Không tìm thấy UID đăng nhập")
            return
        }

        ref.child("users").child(uid).child("friends")
            .observeSingleEvent(of: .value) { snap in

                guard let friendIds = snap.value as? [String: Bool] else {
                    print("⚠️ Bạn chưa có bạn bè nào")
                    self.friends.removeAll()
                    self.tableView.reloadData()
                    return
                }

                self.friends.removeAll()

                for (friendId, _) in friendIds {
                    self.ref.child("users").child(friendId)
                        .observeSingleEvent(of: .value) { userSnap in

                            if let model = parseUser(snapshot: userSnap) {
                                self.friends.append(model)
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                }
                            }
                        }
                }
            }
    }

    // MARK: - Huỷ kết bạn
    func removeFriend(friendId: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        ref.child("users").child(uid).child("friends").child(friendId).removeValue()
        ref.child("users").child(friendId).child("friends").child(uid).removeValue()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.loadFriends()
        }
    }
}

// MARK: - TABLEVIEW
extension FriendListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "friendCell",
            for: indexPath
        ) as! FriendTableViewCell

        let user = friends[indexPath.row]

        // Tên
        cell.usernameLabel.text = user.userName

        // Avatar
        if !user.avatarUrl.isEmpty, let url = URL(string: user.avatarUrl) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data {
                    DispatchQueue.main.async {
                        cell.avatarImageView.image = UIImage(data: data)
                    }
                }
            }.resume()
        } else {
            cell.avatarImageView.image = UIImage(systemName: "person.circle.fill")
        }

        // Trạng thái
        let online = user.status.statusId == "status_01"
        cell.statusIndicator.backgroundColor = online ? .green : .lightGray

        return cell
    }

    // Swipe để xóa bạn
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {

        let remove = UIContextualAction(style: .destructive, title: "Remove") { _, _, complete in
            let friend = self.friends[indexPath.row]
            self.removeFriend(friendId: friend.userId)
            complete(true)
        }

        return UISwipeActionsConfiguration(actions: [remove])
    }
}
