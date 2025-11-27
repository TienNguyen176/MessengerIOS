import UIKit
import FirebaseAuth

class GroupChatsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private var groupChats: [ChatModel] = []
    private var currentUserId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        tableView.register(GroupTableViewCell.self, forCellReuseIdentifier: GroupTableViewCell.identifier)
        
        setupNavBar()
        
        loadCurrentUser()
    }
    
    private func setupNavBar() {
        // Thanh search + nút thêm nhóm
        let searchBar = UISearchBar()
        searchBar.placeholder = "Tìm kiếm..."
        navigationItem.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addGroup))
    }
    
    @objc private func addGroup() {
        if let addGroupVC = self.storyboard?.instantiateViewController(withIdentifier: "AddGroupViewController") as? AddGroupViewController {
            navigationController?.pushViewController(addGroupVC, animated: true)
        }
    }
    
    private func loadCurrentUser() {
        if let user = Auth.auth().currentUser {
            currentUserId = user.uid
        } else {
            // fallback test
            currentUserId = "user_01"
        }
        loadGroupChats()
    }
    
    private func loadGroupChats() {
        guard let userId = currentUserId else { return }
        
        ChatService.shared.fetchGroupChats(for: userId) { [weak self] chats in
            // sort theo updatedAt giảm dần
            self?.groupChats = chats.sorted { $0.updatedAt > $1.updatedAt }
            self?.tableView.reloadData()
        }
    }
}

extension GroupChatsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupChats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let chat = groupChats[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GroupTableViewCell.identifier, for: indexPath) as? GroupTableViewCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: chat)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chat = groupChats[indexPath.row]
        let vc = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "ChatsViewController") as! ChatsViewController
        vc.chatId = chat.chatId
        vc.chatTypeId = chat.typeId
        vc.groupName = chat.groupInfo?.groupName
        navigationController?.pushViewController(vc, animated: true)
    }
}
