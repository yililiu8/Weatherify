//
//  LoginViewController.swift
//  Weatherify
//
//  Created by Yili Liu on 3/22/21.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var loginBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        loginBtn.imageView?.contentMode = .scaleAspectFit
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    func handleSignIn(success: Bool) {
        guard success else {
            let alert = UIAlertController(title: "Error", message: "Unable to perform sign in, something went wrong", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HomeVC") as! HomeViewController
//        vc.modalPresentationStyle = .fullScreen
////        navigationController?.setNavigationBarHidden(false, animated: false)
//        navigationController?.pushViewController(vc, animated: true)
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .coverVertical
        self.present(vc, animated:true)
    }
    
    @IBAction func loginBtn(_ sender: Any) {
        print("pushed")
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AuthVC") as! AuthViewController
        vc.completionHandler = { [weak self] success in
            DispatchQueue.main.async {
                self?.handleSignIn(success: success)
            }
        }
//        vc.modalPresentationStyle = .fullScreen
////        navigationController?.setNavigationBarHidden(false, animated: false)
//        navigationController?.pushViewController(vc, animated: true)
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .coverVertical
        self.present(vc, animated:true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
