
import UIKit

class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTabs()
    }

    private func setupTabs() {
        let chatVC = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "PrivateChatsViewController")
        let friendVC = UIStoryboard(name: "Friend", bundle: nil).instantiateViewController(withIdentifier: "FriendsViewController")
        let groupVC = UIStoryboard(name: "Group", bundle: nil).instantiateViewController(withIdentifier: "GroupChatsViewController")
        let profileVC = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "ProfileViewController")
        
        chatVC.tabBarItem = UITabBarItem(title: "Chat", image: UIImage(systemName: "message"), tag: 0)
        friendVC.tabBarItem = UITabBarItem(title: "Friends", image: UIImage(systemName: "person.2"), tag: 1)
        groupVC.tabBarItem = UITabBarItem(title: "Groups", image: UIImage(systemName: "person.3"), tag: 2)
        profileVC.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person.crop.circle"), tag: 3)
        
        viewControllers = [
            UINavigationController(rootViewController: chatVC),
            UINavigationController(rootViewController: friendVC),
            UINavigationController(rootViewController: groupVC),
            UINavigationController(rootViewController: profileVC)
        ]
    }
}

