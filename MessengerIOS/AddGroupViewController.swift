import UIKit
import FirebaseAuth
import FirebaseDatabase

// MARK: - Model
struct SimpleGroupUser {
    let userId: String
    let userName: String
    let avatarUrl: String
    var isSelected: Bool = false
}

// MARK: - AddGroupViewController
class AddGroupViewController: UIViewController {

    // MARK: UI Components
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Tìm người..."
        sb.translatesAutoresizingMaskIntoConstraints = false
        sb.showsCancelButton = true
        return sb
    }()
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "person.3.fill")
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let groupNameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Tên nhóm..."
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.tableFooterView = UIView()
        return tv
    }()
    
    private let createButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Tạo nhóm", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 8
        btn.alpha = 0.5
        btn.isEnabled = false
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    // MARK: Data
    private var users: [SimpleGroupUser] = [] // danh sách search hiện tại
    private var selectedUsers: [SimpleGroupUser] = [] // lưu người đã chọn
    private var currentUserId: String?
    private var ref = Database.database(url: "https://messengerios-b2aa7-default-rtdb.asia-southeast1.firebasedatabase.app").reference()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupActions()
        fetchCurrentUser()
    }

    // MARK: UI Setup
    private func setupUI() {
        view.addSubview(searchBar)
        view.addSubview(avatarImageView)
        view.addSubview(groupNameTextField)
        view.addSubview(tableView)
        view.addSubview(createButton)
        
        avatarImageView.layer.cornerRadius = 40
        avatarImageView.layer.masksToBounds = true
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserSelectTableViewCell.self, forCellReuseIdentifier: "UserSelectTableViewCell")
        
        searchBar.delegate = self
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            avatarImageView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            avatarImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 80),
            avatarImageView.heightAnchor.constraint(equalToConstant: 80),
            
            groupNameTextField.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 16),
            groupNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            groupNameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            groupNameTextField.heightAnchor.constraint(equalToConstant: 40),
            
            tableView.topAnchor.constraint(equalTo: groupNameTextField.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: createButton.topAnchor, constant: -8),
            
            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            createButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: Actions
    private func setupActions() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectAvatar))
        avatarImageView.addGestureRecognizer(tap)
        createButton.addTarget(self, action: #selector(createGroupTapped), for: .touchUpInside)
    }
    
    private func fetchCurrentUser() {
        currentUserId = Auth.auth().currentUser?.uid
    }

    @objc private func selectAvatar() {
        print("Chọn avatar nhóm")
        // Thêm UIImagePickerController nếu muốn
    }
    
    @objc private func createGroupTapped() {
        guard let groupName = groupNameTextField.text, !groupName.isEmpty else {
            showAlert("Nhập tên nhóm")
            return
        }
        guard let currentUserId = currentUserId else { return }
        guard selectedUsers.count >= 2 else {
            showAlert("Cần chọn tối thiểu 2 người + bạn để tạo nhóm")
            return
        }
        let memberIds = selectedUsers.map { $0.userId }
        ChatService.shared.createGroupChat(ownerId: currentUserId, groupName: groupName, memberIds: memberIds) { [weak self] chatId in
            if let chatId = chatId {
                print("Tạo nhóm thành công: \(chatId)")
                self?.navigationController?.popViewController(animated: true)
            } else {
                self?.showAlert("Tạo nhóm thất bại")
            }
        }
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TableView
extension AddGroupViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let user = users[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserSelectTableViewCell", for: indexPath) as! UserSelectTableViewCell
        
        cell.configure(user: user)
        cell.toggleSelection = { [weak self] in
            guard let self = self else { return }
            var u = self.users[indexPath.row]
            u.isSelected.toggle()
            self.users[indexPath.row] = u
            
            if u.isSelected {
                if !self.selectedUsers.contains(where: { $0.userId == u.userId }) {
                    self.selectedUsers.append(u)
                }
            } else {
                self.selectedUsers.removeAll { $0.userId == u.userId }
            }
            
            cell.configure(user: u)
            
            let selectedCount = self.selectedUsers.count
            self.createButton.isEnabled = selectedCount >= 2
            self.createButton.alpha = self.createButton.isEnabled ? 1 : 0.5
        }
        
        return cell
    }
}

// MARK: - SearchBar
extension AddGroupViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.isEmpty else {
            users = []
            tableView.reloadData()
            return
        }
        
        // Firebase search toàn hệ thống
        ref.child("users").observeSingleEvent(of: .value) { snapshot in
            var results: [SimpleGroupUser] = []
            for child in snapshot.children {
                if let snap = child as? DataSnapshot,
                   let dict = snap.value as? [String: Any],
                   let userName = dict["user_name"] as? String {
                    
                    let userId = snap.key
                    if userId == self.currentUserId { continue } // bỏ chính mình
                    if !userName.lowercased().contains(searchText.lowercased()) { continue }
                    
                    var u = SimpleGroupUser(
                        userId: userId,
                        userName: userName,
                        avatarUrl: dict["avatarUrl"] as? String ?? "",
                        isSelected: false
                    )
                    
                    // check xem đã chọn chưa
                    if self.selectedUsers.contains(where: { $0.userId == u.userId }) {
                        u.isSelected = true
                    }
                    
                    results.append(u)
                }
            }
            self.users = results
            DispatchQueue.main.async { self.tableView.reloadData() }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        users = []
        tableView.reloadData()
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
}

// MARK: - User Cell
class UserSelectTableViewCell: UITableViewCell {
    var toggleSelection: (() -> Void)?
    
    func configure(user: SimpleGroupUser) {
        textLabel?.text = user.userName
        accessoryType = user.isSelected ? .checkmark : .none
        imageView?.image = UIImage(systemName: "person.circle")
        if let url = URL(string: user.avatarUrl), !user.avatarUrl.isEmpty {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data {
                    DispatchQueue.main.async {
                        self.imageView?.image = UIImage(data: data)
                        self.setNeedsLayout()
                    }
                }
            }.resume()
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        let tap = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        addGestureRecognizer(tap)
    }
    
    @objc private func cellTapped() {
        toggleSelection?()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
