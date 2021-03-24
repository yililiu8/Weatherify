//
//  SettingsViewController.swift
//  Weatherify
//
//  Created by Yili Liu on 3/22/21.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var logoutBtn: UIButton!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logoutBtn.imageView?.contentMode = .scaleAspectFit
        usernameLabel.text = Constants.user?.display_name
        emailLabel.text = Constants.user?.email
        countryLabel.text = Constants.user?.country
        self.modalPresentationStyle = .fullScreen
    }
    
    @IBAction func backBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func logoutBtn(_ sender: Any) {
        AuthManager.shared.signOut { [weak self](signedOut) in
            if signedOut {
                DispatchQueue.main.async {
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginVC") as! LoginViewController
                    vc.modalPresentationStyle = .fullScreen
                    vc.modalTransitionStyle = .coverVertical
                    self?.present(vc, animated:true, completion: { 
                        self?.navigationController?.popToRootViewController(animated: false)
                    })
                }
            }
        }
        
    }

}
