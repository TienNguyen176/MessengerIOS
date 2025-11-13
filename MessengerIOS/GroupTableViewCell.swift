import UIKit

class GroupTableViewCell: UITableViewCell {
    
    static let identifier = "GroupTableViewCell"
    
    // MARK: - UI Elements
    let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 25
        iv.backgroundColor = .lightGray
        return iv
    }()
    
    let groupNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()
    
    let lastMessageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 2
        return label
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .lightGray
        label.textAlignment = .right
        return label
    }()
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(groupNameLabel)
        contentView.addSubview(lastMessageLabel)
        contentView.addSubview(timeLabel)
        
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        groupNameLabel.translatesAutoresizingMaskIntoConstraints = false
        lastMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 50),
            avatarImageView.heightAnchor.constraint(equalToConstant: 50),
            
            groupNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            groupNameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            groupNameLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            
            lastMessageLabel.topAnchor.constraint(equalTo: groupNameLabel.bottomAnchor, constant: 4),
            lastMessageLabel.leadingAnchor.constraint(equalTo: groupNameLabel.leadingAnchor),
            lastMessageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            lastMessageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            timeLabel.widthAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    // MARK: - Configure
    func configure(with chat: ChatModel) {
        if let group = chat.groupInfo {
            groupNameLabel.text = group.groupName
        } else {
            groupNameLabel.text = "Group"
        }
        
        lastMessageLabel.text = chat.lastMessage
        
        // format timestamp
        let date = Date(timeIntervalSince1970: chat.updatedAt)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: date)
        
        // load avatar
        if let group = chat.groupInfo {
            let urlStr = group.avatarGroupUrl
            if !urlStr.isEmpty, let url = URL(string: urlStr) {
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    guard let data = data else { return }
                    DispatchQueue.main.async {
                        self.avatarImageView.image = UIImage(data: data)
                    }
                }.resume()
            } else {
                avatarImageView.image = UIImage(systemName: "person.3.fill")
            }
        }
    }
}
