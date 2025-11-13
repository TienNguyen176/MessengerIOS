
import UIKit

class ChatTableViewCell: UITableViewCell {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var chatNameLabel: UILabel!
    @IBOutlet weak var statusIndicator: UIView!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var lastTimeMessageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        avatarImageView.layer.cornerRadius = avatarImageView.frame.width / 2
        avatarImageView.clipsToBounds = true
        
        statusIndicator.layer.cornerRadius = statusIndicator.frame.width / 2
        statusIndicator.clipsToBounds = true
    }
    
    func configure(with chat: ChatModel,
                   userName: String,
                   avatar: UIImage?,
                   statusColor: UIColor,
                   lastMessage: String,
                   lastMessageTime: TimeInterval) {
        chatNameLabel.text = userName
        avatarImageView.image = avatar ?? UIImage(systemName: "person.circle")
        statusIndicator.backgroundColor = statusColor
        lastMessageLabel.text = lastMessage
        let date = Date(timeIntervalSince1970: lastMessageTime / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        lastTimeMessageLabel.text = formatter.string(from: date) }

}
