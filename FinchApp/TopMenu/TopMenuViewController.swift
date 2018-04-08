//
//  TopMenuViewController.swift
//  FinchApp
//
//  Created by Kristina Lauwers on 3/20/18.
//  Copyright © 2018 none. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol TopMenuViewControllerDelegate {
    func didPressNewProgramButton()
    func didPressRunProgramButton()
}

class TopMenuViewController: UIViewController, UIPopoverPresentationControllerDelegate, RobotTableViewControllerDelegate, BLECentralManagerDelegate {
    
    
    
    @IBOutlet weak var connectionStatusLabel: UILabel!
    
    var delegate: TopMenuViewControllerDelegate?
    
    //let centralQueue = DispatchQueue(label: "ble", attributes: [])
    //var centralManager = CBCentralManager()
    
    //Selected Robot
    //var finch: FinchPeripheral?
    var finchName: String?
    var finchID: String?
    var isConnected: Bool = false
    
    var foundRobots: [(robot:CBPeripheral,ss:NSNumber)] = []
    var header = "Select Robot"
    var robotListVC: RobotsTableViewController?
    
    //TODO: put global variables somewhere
    //BLE adapter
    let deviceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    //UART Service
    let SERVICE_UUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    //sending
    let TX_UUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    //receiving
    let RX_UUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    let RX_CONFIG_UUID = CBUUID(string: "00002902-0000-1000-8000-00805f9b34fb")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        connectionStatusLabel.text = "not connected"
        
        //centralManager = CBCentralManager(delegate: self, queue: centralQueue)
        
        print("Scanning? \(BLECentralManager.shared.scanState)")
        BLECentralManager.shared.delegate = self
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: IBActions
    
    @IBAction func connectToFinch(_ sender: UIButton) {
        let type = BBTRobotType.Finch
        let typeStr = "Finch"
        BLECentralManager.shared.startScan(serviceUUIDs: [type.scanningUUID], updateDiscovered: { (peripherals) in
            //let altName = "Fetching name..."
            //let darray = peripherals.map { (peripheral) in
            //    ["id": peripheral.identifier.uuidString,
            //     "name": BBTgetDeviceNameForGAPName(peripheral.name ?? altName)]
            //}
            print("In the startscan callback")
        BLECentralManager.shared.delegate?.updateDiscoveredRobotList()
        }, scanEnded: {
            BLECentralManager.shared.delegate?.scanHasStopped(typeStr: typeStr)
        })
        
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let robotListVC = storyboard.instantiateViewController(withIdentifier: "robotList") as? RobotsTableViewController {
            
            robotListVC.modalPresentationStyle = .popover
            
            //anchor to a bar button item. Anything else we can anchor it to?
            //robotListVC.popoverPresentationController?.barButtonItem =
            
            robotListVC.popoverPresentationController?.permittedArrowDirections = .any
            robotListVC.popoverPresentationController?.delegate = self
            robotListVC.popoverPresentationController?.sourceView = sender
            robotListVC.popoverPresentationController?.sourceRect = sender.bounds
            
            robotListVC.delegate = self
            robotListVC.header = self.header
            robotListVC.foundRobots = self.foundRobots
            self.robotListVC = robotListVC
            
            self.present(robotListVC, animated: true)
        }
        
    }
    @IBAction func newProgram(_ sender: Any) {
        delegate?.didPressNewProgramButton()
    }
    @IBAction func runProgram(_ sender: Any) {
        delegate?.didPressRunProgramButton()
    }
    
    // MARK: - CBCentralManagerDelegate methods
    /*
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            if !central.isScanning {
                centralManager.scanForPeripherals(withServices: [deviceUUID], options: nil)
            }
            header = "Select Robot"
        } else {
            header = "Bluetooth Unavailable at This Time"
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //TODO: do something with the advertisement data?
        foundRobots.append((peripheral, RSSI))
        foundRobots = foundRobots.sorted(by: {$0.ss.compare( $1.ss ) == .orderedDescending})
        
        if robotListVC != nil {
            //must make all ui updates on main thread
            DispatchQueue.main.async { self.robotListVC?.tableView.reloadData() }
        }
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print ("Did connect to \(peripheral.name ?? "unknown")")
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print ("Did fail to connect to \(peripheral.name ?? "unknown") with error \(String(describing: error))")
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Did disconnect from  \(peripheral.name ?? "unknown") with error \(String(describing: error))")
    }
    */
    
    // MARK: UIPopoverPresentationControllerDelegate methods
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }
    
    //MARK: RobotTableViewControllerDelegate methods
    func connectToRobot(_ robot: CBPeripheral) {
        //centralManager.connect(robot, options: nil)
        finchName = BBTgetDeviceNameForGAPName(robot.name ?? "Fetching name...")
        finchID = robot.identifier.uuidString
        
        
        let status = BLECentralManager.shared.connectToRobot(byID: robot.identifier.uuidString, ofType: .Finch)
        print("Connect to robot by ID returned: \(status)")
    }
    
    //MARK: BLECentralManagerDelegate methods
    
    func robotUpdateStatus(id: String, connected: Bool) {
        
        if id != finchID {
            print("Updating status for another robot.")
            return
        }
        
        guard let finchName = finchName else {
            print("updating status before trying to connect?")
            return
        }
        
        isConnected = connected
        
        performUIUpdatesOnMain {
            if connected {
                self.connectionStatusLabel.text = "Connected to \(finchName)"
                self.showToast(message: "You are now connected to \(finchName).")
                //self.finch = BLECentralManager.shared.robotForID(id) as? FinchPeripheral
            } else {
                self.connectionStatusLabel.text = "Disconnected from \(finchName)"
                self.showToast(message: "You have been disconnected from \(finchName)")
            }
        }
    }
    
    func robotFirmwareIncompatible(id: String, firmware: String) {
        performUIUpdatesOnMain {
            self.connectionStatusLabel.text = "Not Connected"
            self.showToast(message: "Firmware \(firmware) of \(id) incompatible.")
        }
    }
    
    func robotFirmwareStatus(id: String, status: String) {
        //TODO: what?
    }
    
    func updateDiscoveredRobotList() {
        foundRobots = BLECentralManager.shared.displayDevices.sorted(by: {$0.ss.compare( $1.ss ) == .orderedDescending})
        if robotListVC != nil {
            //must make all ui updates on main thread
            robotListVC?.foundRobots = foundRobots
            performUIUpdatesOnMain { self.robotListVC?.tableView.reloadData() }
        }
        print("updating discovered robot list")
    }
    
    func scanHasStopped(typeStr: String) {
        //TODO: What?
    }
    

    //MARK: Other
    
    func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
        DispatchQueue.main.async {
            updates()
        }
    }
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 200, y: 200, width: 400, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    

}
