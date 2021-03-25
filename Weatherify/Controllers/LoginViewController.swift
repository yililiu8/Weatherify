//
//  LoginViewController.swift
//  Weatherify
//
//  Created by Yili Liu on 3/22/21.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var loadSunScreen: UIImageView!
    var successfullySignedIn = false
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        loginBtn.imageView?.contentMode = .scaleAspectFit
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        //animation
        UIView.animate(withDuration: 3.0, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.loadSunScreen.transform = self.loadSunScreen.transform.rotated(by: .pi * -1.3)
        }, completion: { completed in
            
        })
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { timer in
            if self.successfullySignedIn {
                timer.invalidate()
            } else {
                UIView.animate(withDuration: 3.0, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                    self.loadSunScreen.transform = self.loadSunScreen.transform.rotated(by: .pi * -1.3)
                }, completion: { completed in
                    
                })
            }
        }
    }
    
    func handleSignIn(success: Bool) {
        guard success else {
            let alert = UIAlertController(title: "Error", message: "Unable to perform sign in, something went wrong", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        successfullySignedIn = true
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HomeVC") as! HomeViewController
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
