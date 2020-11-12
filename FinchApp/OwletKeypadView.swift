/* This custom UIView is an Owlet numberpad. It contains buttons for the numbers 0-9 and a backspace button */
import UIKit

// The delegate is the view controller using this custom UIView. The delegate is notified when the number typed in with the keypad changes.
public protocol OwletKeypadDelegate: class {
   func numberChanged(number: Int?)
}

@IBDesignable
public class OwletKeypadView: UIView {
   
   public weak var delegate: OwletKeypadDelegate?
   
   let nibName = "OwletKeypadView"     // Name of the .xib
   var contentView:UIView?             // This is used by prepareForInterfaceBuilder()
   
   // This is a string representation of the number that the user is entering
   private var numberString = ""
   
   // All the buttons on the keypad
   @IBOutlet var button1: UIButton!
   @IBOutlet var button2: UIButton!
   @IBOutlet var button3: UIButton!
   @IBOutlet var button4: UIButton!
   @IBOutlet var button5: UIButton!
   @IBOutlet var button6: UIButton!
   @IBOutlet var button7: UIButton!
   @IBOutlet var button8: UIButton!
   @IBOutlet var button9: UIButton!
   @IBOutlet var button0: UIButton!
   @IBOutlet var backButton: UIButton!
   
   // This function is called when the user taps the backspace button
   @IBAction func backspacePressed(_ sender: Any) {
      // Remove the last digit
      numberString = String(numberString.dropLast())
      
      // Notify the delegate
      delegate?.numberChanged(number: Int(numberString))
   }
   
   // This function is called when the user taps one of the number buttons
   @IBAction func numberButtonPressed(_ sender: UIButton) {
      // Add the new digit
      numberString.append(sender.title(for: .normal)!)
      // Notify the delegate
      delegate?.numberChanged(number: Int(numberString))
   }
   
   // Can use this function to change the color of the keypad buttons
   public func setButtonColor(color: UIColor) {
      let allButtons = [button1, button2, button3, button4, button5, button6, button7, button8, button9, button0, backButton]
      for button in allButtons {
         button?.backgroundColor = color
      }
   }
   
   // These two initializers are required to create a custom UIView
   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      commonInit()
   }
   
   override init(frame: CGRect) {
      super.init(frame: frame)
      commonInit()
   }
   
   // Set up the buttons
   func commonInit() {
      guard let view = loadViewFromNib() else { return }
      view.frame = self.bounds
      self.addSubview(view)
      contentView = view
      
      /* Make all the buttons round */
      let allButtons = [button1, button2, button3, button4, button5, button6, button7, button8, button9, button0, backButton]
      for button in allButtons {
         button!.layer.cornerRadius = 0.5 * button!.bounds.size.width
         button!.clipsToBounds = true
      }
   }
   
   // The view controller can use this function to reset the number
   public func resetNumber() {
      numberString = ""
   }
   
   // Required to load the view from the .xib file
   func loadViewFromNib() -> UIView? {
      let bundle = Bundle(for: type(of: self))
      let nib = UINib(nibName: nibName, bundle: bundle)
      return nib.instantiate(withOwner: self, options: nil).first as? UIView
   }
   
   // This function enables us to see the view in the interface builder
   public override func prepareForInterfaceBuilder() {
      super.prepareForInterfaceBuilder()
      commonInit()
      contentView?.prepareForInterfaceBuilder()
   }
}
