import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

// MARK: - Simple structs
struct SimpleUser {
    let userId: String
    let userName: String
    let avatarUrl: String
    let allowMessagesFrom: String?
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
        ChatService.shared.fetchPrivateChats(for: userId) { chats in
            self.chats = chats
            self.fetchAllChatUsers()
            self.tableView.reloadData()
        }
    }
    
    private func fetchAllChatUsers() {
        for chat in chats {
            let otherUserId = chat.userIds.first { $0 != currentUserId } ?? ""
            if usersCache[otherUserId] != nil { continue }

            ref.child("users").child(otherUserId).observeSingleEvent(of: .value) { snapshot in
                guard let dict = snapshot.value as? [String: Any] else { return }

                let user = ChatUserInfo(
                    userId: otherUserId,
                    userName: dict["user_name"] as? String ?? "Unknown",
                    avatarUrl: dict["avatarUrl"] as? String ?? "",
                    statusId: dict["statusId"] as? String ?? ""
                )

                self.usersCache[otherUserId] = user
                DispatchQueue.main.async { self.tableView.reloadData() }
            }
        }
    }
    
    // MARK: - Search Users
    private func searchUsers(with text: String) {
        searchResults.removeAll()
        ref.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let allUsers = snapshot.value as? [String: Any] else { return }
            for (userId, value) in allUsers {
                guard userId != self.currentUserId else { continue }
                if let userData = value as? [String: Any],
                   let userName = userData["user_name"] as? String,
                   userName.lowercased().contains(text.lowercased()) {
                    let user = SimpleUser(
                        userId: userId,
                        userName: userName,
                        avatarUrl: userData["avatarUrl"] as? String ?? "",
                        allowMessagesFrom: nil
                    )
                    self.searchResults.append(user)
                }
            }
            DispatchQueue.main.async { self.tableView.reloadData() }
        })
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

        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        guard let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatsViewController") as? ChatsViewController else { return }

        if isSearching {
            let user = searchResults[indexPath.row]
            chatVC.chatTypeId = "type_05" // private chat
            chatVC.otherUser = SimpleUser(userId: user.userId, userName: user.userName, avatarUrl: user.avatarUrl, allowMessagesFrom: nil)

            // Tìm xem user này có chat hiện tại chưa
            if let existingChat = chats.first(where: { $0.userIds.contains(user.userId) && $0.userIds.contains(currentUserId ?? "") }) {
                chatVC.chatId = existingChat.chatId
            } else {
                chatVC.chatId = nil // sẽ tạo khi gửi message lần đầu
            }

        } else {
            let chat = chats[indexPath.row]
            chatVC.chatTypeId = chat.typeId
            chatVC.chatId = chat.chatId

            if chat.typeId == "type_05" {
                let otherUserId = chat.userIds.first { $0 != currentUserId } ?? ""
                if let userInfo = usersCache[otherUserId] {
                    chatVC.otherUser = SimpleUser(userId: userInfo.userId, userName: userInfo.userName, avatarUrl: userInfo.avatarUrl, allowMessagesFrom: nil)
                }
            } else if chat.typeId == "type_06" {
                chatVC.groupName = chat.groupInfo?.groupName
            }
        }

        navigationController?.pushViewController(chatVC, animated: true)
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
