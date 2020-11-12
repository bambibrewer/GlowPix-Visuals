// This wraps the Owlet KeyPad in a View Controller so that it can be uses as a popup
import UIKit

// The class that will be using the popup should be assigned as the delegate, so that it knows the number
protocol KeyPadPopupDelegate {
   func numberChanged(number: Int?)
}

class KeyPadViewController: UIViewController, OwletKeypadDelegate {
   
   @IBOutlet var keyPadView: OwletKeypadView!
   
   var keyPadDelegate: KeyPadPopupDelegate?
   
   override func viewDidLoad() {
      super.viewDidLoad()
      keyPadView.delegate = self
   }
   
   func numberChanged(number: Int?) {
      keyPadDelegate?.numberChanged(number: number)
   }
   
}
