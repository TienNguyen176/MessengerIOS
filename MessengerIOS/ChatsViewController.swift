import UIKit
import FirebaseAuth
import FirebaseDatabase

class ChatsViewController: UIViewController {

    @IBOutlet weak var inputContainerView: UIView!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!

    var chatId: String?
    var chatTypeId: String?
    var otherUser: SimpleUser?
    var groupName: String?

    private var messages: [MessageModel] = []
    private var messageHandle: DatabaseHandle?
    private var currentUserId: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.alwaysBounceVertical = true

        setupNavigationBar()
        setupUI()
        setupKeyboardObservers()
        loadCurrentUser()
    }

    private func loadCurrentUser() {
        if let user = Auth.auth().currentUser {
            currentUserId = user.uid
        } else {
            currentUserId = "user_01"
        }

        if let chatId = chatId {
            observeMessages(chatId: chatId)
        }
    }

    private func setupUI() {
        inputTextField.placeholder = "Tin nhắn..."
        inputTextField.layer.cornerRadius = 8
        inputTextField.layer.borderWidth = 1
        inputTextField.layer.borderColor = UIColor.lightGray.cgColor
        inputTextField.clipsToBounds = true
    }

    private func setupNavigationBar() {
        navigationItem.title = chatTypeId == "type_05" ? otherUser?.userName ?? "Tin nhắn" :
                               chatTypeId == "type_06" ? groupName ?? "Nhóm" : "Tin nhắn"
    }

    @IBAction func sendMessageButtonClick(_ sender: UIButton) {
        guard let text = inputTextField.text, !text.isEmpty,
              let currentUserId = currentUserId else { return }
        inputTextField.text = ""

        if chatTypeId == "type_05", let otherUser = otherUser,
           otherUser.allowMessagesFrom == "type_04" {
            showCannotSendAlert()
            return
        }

        if chatId == nil, chatTypeId == "type_05", let otherUser = otherUser {
            ChatService.shared.createPrivateChat(currentUserId: currentUserId,
                                                 otherUserId: otherUser.userId,
                                                 firstMessage: text) { [weak self] newChatId in
                guard let self = self, let newChatId = newChatId else { return }
                self.chatId = newChatId
                self.observeMessages(chatId: newChatId)
                MessageService.shared.sendMessage(chatId: newChatId, senderId: currentUserId, text: text)
            }
        } else if let chatId = chatId {
            MessageService.shared.sendMessage(chatId: chatId, senderId: currentUserId, text: text)
        }
    }

    private func showCannotSendAlert() {
        let label = UILabel()
        label.text = "Người dùng không nhận tin nhắn từ người lạ"
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.alpha = 0

        let width = view.frame.width - 40
        label.frame = CGRect(x: 20, y: view.frame.height / 2 - 20, width: width, height: 40)
        view.addSubview(label)

        UIView.animate(withDuration: 0.3, animations: { label.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.5, options: [], animations: { label.alpha = 0 }) { _ in
                label.removeFromSuperview()
            }
        }
    }

    private func observeMessages(chatId: String) {
        messageHandle = MessageService.shared.observeMessages(chatId: chatId) { [weak self] message in
            DispatchQueue.main.async {
                self?.messages.append(message)
                self?.tableView.reloadData()
                self?.adjustTableViewContent()
                self?.scrollToBottom()
            }
        }
    }

    private func scrollToBottom() {
        guard messages.count > 0 else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
    // Tin nhan nam cuoi khi it
    private func adjustTableViewContent() {
        tableView.layoutIfNeeded()
        let contentHeight = tableView.contentSize.height
        let tableHeight = tableView.bounds.height

        if contentHeight < tableHeight {
            // nếu ít tin nhắn, đẩy content xuống đáy
            tableView.contentInset.top = tableHeight - contentHeight
        } else {
            tableView.contentInset.top = 0
        }
    }
}

// MARK: - TableView
extension ChatsViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]

        if message.senderId == currentUserId {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyMessageCell", for: indexPath) as! MyMessageTableViewCell
            cell.configure(with: message.text)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "OtherMessageCell", for: indexPath) as! OtherMessageTableViewCell
            cell.configure(with: message.text)
            return cell
        }
    }
}

// MARK: - Keyboard Handling
extension ChatsViewController {

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }

        let keyboardHeight = keyboardFrame.height
        let curve = UIView.AnimationOptions(rawValue: curveValue << 16)

        UIView.animate(withDuration: duration, delay: 0, options: curve, animations: {
            self.inputContainerView.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight)
            self.tableView.contentInset.bottom = keyboardHeight + self.inputContainerView.frame.height
            self.tableView.scrollIndicatorInsets.bottom = keyboardHeight + self.inputContainerView.frame.height
        }, completion: { _ in
            self.scrollToBottom()
        })
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }

        let curve = UIView.AnimationOptions(rawValue: curveValue << 16)

        UIView.animate(withDuration: duration, delay: 0, options: curve, animations: {
            self.inputContainerView.transform = .identity
            self.tableView.contentInset.bottom = self.inputContainerView.frame.height
            self.tableView.scrollIndicatorInsets.bottom = self.inputContainerView.frame.height
        }, completion: nil)
    }
}

