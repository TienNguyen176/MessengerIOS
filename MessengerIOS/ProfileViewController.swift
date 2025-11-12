
import UIKit
import Firebase
import FirebaseDatabase

class ProfileViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func logoutButtonClick(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.set(false, forKey: "rememberUser")
            
            let storyboard = UIStoryboard(name: "Auth", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
            loginVC.modalPresentationStyle = .fullScreen
            present(loginVC, animated: true)
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
}
