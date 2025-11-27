import UIKit

class FriendsViewController: UIViewController {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var containerView: UIView!

    private var currentVC: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        switchTab(index: 0)
    }

    private func setupUI() {
        // Đặt tên 2 tab
        segmentedControl.removeAllSegments()
        segmentedControl.insertSegment(withTitle: "Danh sách bạn bè", at: 0, animated: false)
        segmentedControl.insertSegment(withTitle: "Lời mời kết bạn", at: 1, animated: false)
        segmentedControl.selectedSegmentIndex = 0

        // Search bar ở navigation bar
        let searchBar = UISearchBar()
        searchBar.placeholder = "Tìm kiếm..."
        navigationItem.titleView = searchBar

        // Nút thêm bạn
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addFriendTapped)
        )
    }

    @objc private func addFriendTapped() {
        print("Nhấn thêm bạn")
        
        let storyboard = UIStoryboard(name: "Friend", bundle: nil)
        if let addFriendVC = storyboard.instantiateViewController(withIdentifier: "AddFriendViewController") as? AddFriendViewController {
            navigationController?.pushViewController(addFriendVC, animated: true)
        }
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        switchTab(index: sender.selectedSegmentIndex)
    }

    private func switchTab(index: Int) {
        let storyboard = UIStoryboard(name: "Friend", bundle: nil)
        let newVC: UIViewController

        if index == 0 {
            // Chuyển sang danh sách bạn bè
            newVC = storyboard.instantiateViewController(withIdentifier: "FriendListViewController")
        } else {
            // Chuyển sang lời mời kết bạn
            newVC = storyboard.instantiateViewController(withIdentifier: "FriendRequestsViewController")
        }

        changeChild(to: newVC)
    }

    private func changeChild(to newVC: UIViewController) {
        // Xóa view cũ nếu có
        if let oldVC = currentVC {
            oldVC.willMove(toParent: nil)
            oldVC.view.removeFromSuperview()
            oldVC.removeFromParent()
        }

        // Add view mới
        addChild(newVC)
        newVC.view.frame = containerView.bounds
        containerView.addSubview(newVC.view)
        newVC.didMove(toParent: self)

        currentVC = newVC
    }
}
