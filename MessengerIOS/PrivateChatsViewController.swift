import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

// MARK: - Simple structs
struct SimpleUser {
    let userId: String
    let userName: String
    let avatarUrl: String
}

struct ChatUserInfo {
    let userId: String
    let userName: String
    let avatarUrl: String
    let statusId: String
}

class PrivateChatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    // Chats hiện tại
    var chats: [ChatModel] = []
    var usersCache: [String: ChatUserInfo] = [:]
    var currentUserId: String?
    
    // Search
    var isSearching = false
    var searchResults: [SimpleUser] = []
    
    let ref = Database.database(url: "https://messengerios-b2aa7-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        setupNavBar()
        fetchCurrentUser()
    }
    
    // MARK: - NavBar & Search
    private func setupNavBar() {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Tìm kiếm người dùng..."
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        navigationItem.titleView = searchBar
    }
    
    // MARK: - Fetch Current User
    private func fetchCurrentUser() {
        if let user = Auth.auth().currentUser {
            currentUserId = user.uid
            fetchPrivateChats()
        } else {
            print("User chưa đăng nhập")
        }
    }
    
    // MARK: - Fetch Chats
    private func fetchPrivateChats() {
        guard let userId = currentUserId else { return }
        
        ref.child("users").child(userId).child("chat_ids").observeSingleEvent(of: .value) { snapshot in
            guard let chatIdsDict = snapshot.value as? [String: Bool] else { return }
            
            let group = DispatchGroup()
            
            for chatId in chatIdsDict.keys {
                group.enter()
                self.ref.child("chats").child(chatId).observeSingleEvent(of: .value) { chatSnap in
                    defer { group.leave() }
                    
                    guard let chatData = chatSnap.value as? [String: Any],
                          let typeId = chatData["type_id"] as? String,
                          typeId == "type_05",
                          let updatedAt = chatData["updatedAt"] as? TimeInterval,
                          let lastMessage = chatData["lastMessage"] as? String,
                          let userDict = chatData["users"] as? [String: Bool] else { return }
                    
                    let otherUserId = userDict.keys.first { $0 != userId } ?? ""
                    
                    if let _ = self.usersCache[otherUserId] {
                        let chat = ChatModel(chatId: chatId,
                                             typeId: typeId,
                                             lastMessage: lastMessage,
                                             updatedAt: updatedAt,
                                             userIds: Array(userDict.keys))
                        self.chats.append(chat)
                    } else {
                        self.ref.child("users").child(otherUserId).observeSingleEvent(of: .value) { userSnap in
                            if let userData = userSnap.value as? [String: Any] {
                                let user = ChatUserInfo(
                                    userId: otherUserId,
                                    userName: userData["user_name"] as? String ?? "Unknown",
                                    avatarUrl: userData["avatarUrl"] as? String ?? "",
                                    statusId: (userData["status"] as? [String: Any])?["status_id"] as? String ?? "status_02"
                                )
                                self.usersCache[otherUserId] = user
                                
                                let chat = ChatModel(chatId: chatId,
                                                     typeId: typeId,
                                                     lastMessage: lastMessage,
                                                     updatedAt: updatedAt,
                                                     userIds: Array(userDict.keys))
                                self.chats.append(chat)
                            }
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Search Users
    private func searchUsers(with text: String) {
        searchResults.removeAll()
        ref.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let allUsers = snapshot.value as? [String: Any] else { return }
            for (userId, value) in allUsers {
                guard userId != self.currentUserId else { continue }
                if let userData = value as? [String: Any],
                   let userName = userData["user_name"] as? String,
                   userName.lowercased().contains(text.lowercased()) {
                    let user = SimpleUser(
                        userId: userId,
                        userName: userName,
                        avatarUrl: userData["avatarUrl"] as? String ?? ""
                    )
                    self.searchResults.append(user)
                }
            }
            DispatchQueue.main.async { self.tableView.reloadData() }
        }
    }
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? searchResults.count : chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatTableViewCell", for: indexPath) as! ChatTableViewCell
        
        if isSearching {
            let user = searchResults[indexPath.row]
            cell.chatNameLabel.text = user.userName
            cell.lastMessageLabel.text = ""
            cell.lastTimeMessageLabel.text = ""
            cell.statusIndicator.backgroundColor = .clear
            cell.avatarImageView.image = UIImage(systemName: "person.circle")
            if let url = URL(string: user.avatarUrl), !user.avatarUrl.isEmpty {
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    if let data = data {
                        DispatchQueue.main.async {
                            cell.avatarImageView.image = UIImage(data: data)
                        }
                    }
                }.resume()
            }
        } else {
            let chat = chats[indexPath.row]
            let otherUserId = chat.userIds.first { $0 != currentUserId } ?? ""
            let user = usersCache[otherUserId]
            
            cell.chatNameLabel.text = user?.userName ?? "Unknown"
            cell.lastMessageLabel.text = chat.lastMessage
            cell.lastTimeMessageLabel.text = "\(Int(chat.updatedAt))"
            cell.statusIndicator.backgroundColor = statusColor(for: user?.statusId)
            cell.avatarImageView.image = UIImage(systemName: "person.circle")
            
            if let urlString = user?.avatarUrl, let url = URL(string: urlString) {
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    if let data = data {
                        DispatchQueue.main.async {
                            cell.avatarImageView.image = UIImage(data: data)
                        }
                    }
                }.resume()
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if isSearching {
            let user = searchResults[indexPath.row]
            print("Selected user: \(user.userId)")
        } else {
            let chat = chats[indexPath.row]
            print("Selected chat id: \(chat.chatId)")
        }
    }
    
    // MARK: - Status color
    private func statusColor(for statusId: String?) -> UIColor {
        switch statusId {
        case "status_01": return .green
        case "status_02": return .gray
        default: return .clear
        }
    }
    
    // MARK: - UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        isSearching = !searchText.isEmpty
        if isSearching {
            searchUsers(with: searchText)
        } else {
            tableView.reloadData()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearching = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        tableView.reloadData()
    }
}
