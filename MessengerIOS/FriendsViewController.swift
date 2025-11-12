
import UIKit

class FriendsViewController: UIViewController {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var containerView: UIView!
    
    private var currentViewController: UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBar()
        setupSegmented()
        
        switchToTab(index: 0) // Load FriendLists
    }
    
    private func setupNavBar() {
        // Thanh search + nút thêm bạn
        let searchBar = UISearchBar()
        searchBar.placeholder = "Tìm bạn bè..."
        navigationItem.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addFriend))
    }
    
    private func setupSegmented() {
        segmentedControl.removeAllSegments()
        segmentedControl.insertSegment(withTitle: "Danh sách bạn bè", at: 0, animated: false)
        segmentedControl.insertSegment(withTitle: "Lời mời kết bạn", at: 1, animated: false)
        segmentedControl.selectedSegmentIndex = 0
    }
    
    @objc private func addFriend() {
        print("Thêm bạn")
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        switchToTab(index: sender.selectedSegmentIndex)
    }
    
    private func switchToTab(index: Int) {
        let storyboard = UIStoryboard(name: "Friend", bundle: nil)
        let newVC: UIViewController
        
        if index == 0 {
            newVC = storyboard.instantiateViewController(withIdentifier: "FriendListViewController") as! FriendListViewController
        } else {
            newVC = storyboard.instantiateViewController(withIdentifier: "FriendRequestsViewController") as! FriendRequestsViewController
        }
        
        let fromLeft = index == 1
        switchChild(to: newVC, fromLeft: fromLeft)
    }
        
    private func switchChild(to newVC: UIViewController, fromLeft: Bool = true) {
        if let current = currentViewController {
            // Nếu đã có child hiện tại → chuyển animation
            let width = containerView.bounds.width
            let offset = fromLeft ? width : -width
            newVC.view.frame = containerView.bounds.offsetBy(dx: offset, dy: 0)
            
            addChild(newVC)
            containerView.addSubview(newVC.view)
            
            UIView.animate(withDuration: 0.3, animations: {
                current.view.frame = current.view.frame.offsetBy(dx: -offset, dy: 0)
                newVC.view.frame = self.containerView.bounds
            }, completion: { _ in
                current.willMove(toParent: nil)
                current.view.removeFromSuperview()
                current.removeFromParent()
                newVC.didMove(toParent: self)
                self.currentViewController = newVC
            })
        } else {
            // Lần đầu load → không cần animation
            addChild(newVC)
            newVC.view.frame = containerView.bounds
            containerView.addSubview(newVC.view)
            newVC.didMove(toParent: self)
            currentViewController = newVC
        }
    }
}

