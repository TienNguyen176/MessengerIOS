import UIKit

class FriendTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var statusIndicator: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageView.layer.cornerRadius = 30
        avatarImageView.clipsToBounds = true

        statusIndicator.layer.cornerRadius = 6
        statusIndicator.clipsToBounds = true
    }
}
