//
//  ViewController.swift
//  DroneItOut
//
//  Created by Daniel Nguyen on 9/16/17.
//  Copyright © 2017 DJI. All rights reserved.
//

import Foundation
import UIKit
import SpeechKit
import DJISDK
import SpriteKit
import CoreLocation
import CoreBluetooth

/*

let POINT_OFFSET: Double = 0.000179863
//1 = 10m
//1 m = 3.280399 ft
//1 ft = 0.3048 m

//Calculation 1m = GPS point - 0.000284
let MY_POINT_OFFSET: Double = 0.0000181
let ALTITUDE: Float = 2

class ViewController: DJIVisionControlState, DJIBaseViewController, DJISDKManagerDelegate, SKTransactionDelegate, DJIFlightControllerDelegate,DJIMissionManagerDelegate, DJIMissionControl {
    
    enum SKSState {
        case sksIdle
        case sksListening
        case sksProcessing
    }
    
    weak var appDelegate: AppDelegate! = UIApplication.shared.delegate as? AppDelegate
    
    //display whether the drone is connected or not
    @IBOutlet weak var connectionStatus: UILabel!
    
    //display text on screen
    @IBOutlet weak var textDisplay: UILabel!
    
    //SpeechKit variable
    var sksSession: SKSession?
    var sksTransaction: SKTransaction?
    var state = SKSState.sksIdle
    var SKSLanguage = "end-USA"
    
    //DJI variable
    var appkey = "0e40d70b9706d8bb3ae4adfd"
    var connectionProduct: DJIBaseProduct?=nil
    
    //flight Controller
    var fc: DJIFlightController?
    var aircraftLocation: CLLocationCoordinate2D?=nil
    var currentState: DJIFlightControllerState?=nil
    var aircraft: DJIAircraft?=nil
    
    //mission variable
    var missionManager: DJIMissionManger = DJIMissionManger.shareInstance()!
    var hotpointMission: DJIHotpointMission = DJIHotpointMission()
    var mCurrentHotPointCoordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    var locs: [CLLocationCoordinate2D] = []
    var uploadStatus: Float = 0
    var commands: [String] = []
    var speed: Double = 0
    
    //store coordinate that uses to create waypoint mission
    var waypointList: [DJIWaypoint] = []
    var waypointMission: DJIWaypointMission = DJIWaypointMission()
    var waypointMission: DJICustomMission?=nil
    var missionSetup: Bool = false
    var deltaProcess: CGFloat = 0
    var allSteps: [DJIMissionStep] = []
    var stepIndex: Int = 0
    
    //mission status UI bar
    @IBOutlet weak bar missionStatusBar: UIProcessView!
    
    //label name for debugging
    @IBOutlet weak bar atext: UILabel!
    @IBOutlet weak bar btext: UILabel!
    @IBOutlet weak bar ctext: UILabel!
    @IBOutlet weak bar dtext: UILabel!
    @IBOutlet weak bar etext: UILabel!
    @IBOutlet weak bar htext: UILabel!
    @IBOutlet weak bar itext: UILabel!
    
    //Bluetooth
    var simpleBluetoothID: SimpleBluetoothID!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // my nuance sandbox credentials
        let SKSAppKey = "e44c885455471dd09b1cef28fae758e80348e989db7b28e4b794a9608cfbfb714783c59dcae26d66fe5c8ef843e7e0462fc9cf0a44f7eefc8b985c18935789da";         //start a session
        let SKSAppId = "NMDPTRIAL_danieltn91_gmail_com20170911202728";
        let SKSServerHost = "sslsandbox-nmdp.nuancemobility.net";
        let SKSServerPort = "443";
        
        let SKSLanguage = "eng-USA";
        
        let SKSServerUrl = "nmsps://\(SKSAppId)@\(SKSServerHost):\(SKSServerPort)"
        
        
        // start nuance session with my account
        sksSession = SKSession(url: URL(string: SKSServerUrl), appToken: SKSAppKey)
        sksTransaction = nil
        
        //Registered DJI app key
        DJISDKManager.registerApp(appkey, with: self)
        print(DJISDKManager.getSDKVersion)
        
        //Connect to product
        DJISDKManager.startConnectionToProduct()
        connectionProductManager.shareInstance.fetchAirlink()
        
        //mission manner
        self.missionManager = DJIMissionManager.shareInstance()!
        self.missionManager.delegate = self
        
        let aircraft: DJIAircraft? = self.fetchAircraft()
        if aircraft != nil {
            aircraft!.delegate = self
            aircraft!.flightController?.delegate = self
        }
        
        missionStatusBar.setProgress(0, animated: true)
        
        //beign listening to user and this gets called repeatedly to ensure countinue listening
        beginApp()
        
    }
    //conform DJIApp Protocol delegate and check error
    @objc func sdkManagerDidRegisterAppWithError(_ error: Error?){
        print(error)
    }
    
    //auto make transactons
    func beginApp() {
        switch state {
        case .sksIdle:
            recongnize()
        case .sksListening:
            stopRecording()
        case .sksProcessing:
            cancel()
        }
    }
    
    func reconize(){
        //begin to listening to user
        let options = [
            "" : ""
        ]
        sksTransaction = sksSession?.recognize(withType: SKTransactionSpeechTypeDictation, detection: .long, language: "eng-USA", options: options, delegate: self)
        print("starting reconition process")
        
    }
    
    func stopRecording(){
        //Stop recording user
        sksTransaction!.stopRecording()
        beginApp()
        print("Stop Recording")
    }
    
    func cancel (){
        //cancel transactions
        sksTransaction!.cancel()
        print("cancel recongition transactions")
        beginApp()
    }
    
    // SKTransactionDelegate
    func transactionDidBeginRecording(_ transaction: SKTransaction!) {
        //transactions begin recording
        state = .sksListening
        print("begin recording")
    }
    func transactionDidFinishRecording(_ transaction: SKTransaction!) {
        state = .sksProcessing
        print("finished recording")
    }
    func transaction(transaction: SKTransaction!, didFinishWithSuggestion suggestion: String!) {
        state = .sksIdle
        sksTransaction = nil
        print("reset transaction")
    }
    func transaction(transaction: SKTransaction!, didFailWithError error: NSError!, suggestion: String!) {
        print("there is an error in processing speech transaction")
        state = .sksIdle
        sksTransaction = nil
        beginApp()
    }
    
    override func didReceiveMemoryWarning(){
        super.didReceiveMemoryWarning()
    }
    
    // *************This is where the action happens after speech has been reconized!*********** //
    func transaction(_ transaction: SKTransaction!, didReceiveRecognition recognition: SKRecognition!) {
        
        state = .sksIdle
        
        //convert all text to lowercase
        textDisplay.text = recognition.text.lowercased()
        print(recognition.text.lowercased())
        print(state)
        print("recognition recieved")
        
        //make an array of word said
        var words = recognition.text.lowercased()
        
        //nuance catches 1 as "one", so we need to change it
        if words.localizedStandardRange(of: "one") != nil {
            words = words.replacingOccurrences(of: "one", with: "1")
        }
        
        
        // make sure fc is flight controller
        fc = self.fetchFlightController()
        if fc != nil {
            fc?.delegate = self
        }
        
        // use regex for NSEW compass direction
        self.commands = findNSEWComandsFromString(str: words)
        if !commands.isEmpty {
            runNSEWDirectionCommand()
            commands = []
            btext.text = "first"
        }
        
        // use regex for longer commands
        commands = findMovementCommandsString(str: words)
        if !commands.isEmpty {
            itext.text = "\(commands)"
            commands = []
            btext.text = "second"
        }
        
        // use regex for short commands
        commands = findShortMovementCommandsString(str: words)
        itext.text = "\(commands)"
        if !commands.isEmpty {
            itext.text = "\(commands)"
            runShortMovementCommands()
            commands = []
            btext.text = "third"
        }
        
        // if none of those regex are matched, it will go to a String
        var strArr = words.characters.split{$0 == " "}.map(String.init)
        
        if strArr.count > 1 {
            //take off
            if strArr[0] = "take" && strArr[1] == "off" {
                droneTakeOff(fc)
            }
            //say "power on" to start propellers
            if strArr[0] = "power" && strArr[1] == "on" {
                droneStartPropellers(fc)
            }
            //say "power off" to off propellers
            if strArr[0] = "power" && strArr[1] == "off" {
                droneStopPropellers(fc)
            }
        }
        
        //loop through words
        for str in strArr{
            //saying "connection" changes the text to verify the drone is connected
            if str == "connect" {
                if ConnectedProductManager.sharedInstance.connectedProduct != nil {
                    connectionStatus.text = "Connected"
                    connectionStatus.backgroundColor = UIColor.lightgray
                }
                else {
                    connectionStatus.text = "Disconnected"
                    connectionStatus.backgroundColor = UIColor.red
                }
            }
            
            
            // say "land" to make the drone land
            if str == "land" {
                droneLand(fc)
            }
            if str == "enable" {
                enableVirturalStickModeSaid()
            }
            if str == "disable" {
                disableVirtualStickModeSaid()
            }
            if str == "execute" {
                executeMission()
            }
            
            // say "cancel" to cancel mission
            if str == "cancel" {
                cancelMissionSaid()
                atext.text = "Mission cancelled"
            }
            if str == "pause" {
                pauseMissionSaid()
                atext.text = "Mission paused"
            }
            if str == "resume" {
                resumeMissionSaid()
                atext.text = "Mission resume"
            }
            
        }
    }
    
    //*********** REGEX METHOD **************//
    
    //use only for new compass commands
    func findNSEWCommandFromString( str: String ) -> [String] {
        let goCommandRegex = "\\s*(go|fly|move|head|come|)\\s(east|west|north|south)\\s(to|by|for)?\\s?((?:\\d*\\.)?\\d+)?\\s(feet|foot|meters|meter|m|ft)?"
        let matched = matches(for: goCommandRegex,in: str )
        print(matched)
        return matched
    }
    //use for getting direction, distance, and units of measurements
    func findMovementCommandsFromString( str: String ) -> [String] {
        let goCommandRegex = "\\s*(go|fly|move|head|come|)\\s(left|right|up|down|forward|back)\\s(to|by|for)?\\s?((?:\\d*\\.)?\\d+)?\\s(feet|foot|meters|meter|m|ft)?"
        let matched = matches(for: goCommandRegex,in: str )
        print(matched)
        return matched
    }
    //use for getting simple commands like "go left", "go right", "fly high"
    func findShortMovementCommandsFromString( str: String ) -> [String] {
        let goCommandRegex = "\\s*(drone|phantom)?\\s?(go|fly|move|head|come|)\\s(left|right|up|down|forward|back|backward)?"
        let matched = matches(for: goCommandRegex,in: str )
        print(matched)
        return matched
    }
    // matching function
    //use regex to extract matches from string and retrun array of strings
    func matches(for regex: String, in text: String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as String
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.map{ nsString.substring(with: $0.range)
            }
            catch let error {
                print ("invalid regex: \(error.localizedDescription)")
                return []
            }
            
        }
    }
    //******** RUN COMMANDS METHODS **********//
    func runShortMovementCommands() {
        var direction: String = ""
        if commands.count > 0 {
            for comm in commands {
                var commandArr = comm.characters.split{$0 == "" }.map(String.init)
                ctext.text = "command = \(commandArr[0])"
                dtext.text = "direction = \(commandArr[1])"
                
                if commands.count == 3 { //Drone goes left
                    direction = commandArr[2]
                }
                if commands.count == 2 { //Drone goes up
                    direction = commandArr[1]
                    etext.text = "\(direction)"
                }
                //initalize a data object. They have pitch, roll, yaw, and throttle
                var commandCtrlData: DJIVirtualStickFlightControlData? = DJIVirtualStickFlightControlData.init()
                //flightCtrlData?.pitch = 0.5 - make it goes to the right a little bit 0.5m/s
                
                //Here is where data gets changed
                commandCtrlData?.pitch = 0
                commandCtrlData?.roll = 0
                commandCtrlData?.yaw = 0
                commandCtrlData?.verticalThrottle = 0
                
                if direction == "left" {
                    commandCtrlData?.pitch = -1.0
                }
                if direction == "right" {
                    commandCtrlData?.pitch = 1.0
                }
                if direction == "up" {
                    commandCtrlData?.verticalThrottle = 1.0
                }
                if direction == "down" {
                    commandCtrlData?.verticalThrottle = -1.0
                }
                if direction == "forward" {
                    commandCtrlData?.roll = 1.0
                }
                if direction == "backward" || direction == "back" {
                    commandCtrlData?.roll = -1.0
                }
                
                enterVirtualStickMode( newFlightCtrlData: commandCtrlData!)
            }
        }
    }
    func enterVirtualStickMode( newFlightCtrlData: DJIVirtualStickFlightControlData) {
        // x, y , z = forward, right, downward
        
        //cancel the missions just in case they are running
        cancelMissionSaid()
        aircraft = self.fetchAircraft()
        fc = self.fetchFlightController()
        fc?.delegate = self
        if fc != nil {
            //must first enable virtual control stick mode
            fc?.enableVirtualStickControlMode(completion: {(error: Error?) ->Void in
                if error != nil {
                    self.atext.text = "virtual stick mode is not enabled: \(error) "
                }
                else {
                    self.atext.text = "virtual stick mode enabled"
                    
                    self.fc?.yawControlMode = DJIVirtualStickYawControlMode.angularVelocity
                    self.fc?.rollPitchControlMode = DJIVirtualStickRollPitchControlMode.velocity
                    self.fc?.verticalControlMode = DJIVirtualStickVerticalControlMode.velocity
                    self.fc?.rollPitchCoordinateSystem = DJIVirtualStickFlightCoordinateSystem.body
                    
                    var flightCtrlData: DJIVirtualStickFlightControlData? = DJIVirtualStickFlightControlData.init()
                    
                    //Here is where the data gets changed
                    flightCtrlData?.pitch = newFlightCtrlData.pitch
                    flightCtrlData?.roll = newFlightCtrlData.roll
                    flightCtrlData?.yaw = newFlightCtrlData.yaw
                    flightCtrlData?.verticalThrottle = newFlightCtrlData.verticalThrottle
                    
                    self.ctext.text = "\(self.fc?.isVirtualStickControlModeAvailable())"
                    
                    //if VirtualStickControlMode is available, the data will be sent and drone will perfom command
                    if self.fc?.isVirtualStickControlModeAvailable()! {
                        self.dtext.text = "Virtual stick control is available"
                        
                        self.fc?.send(flightCtrlData!, withCompletion: {(error: Error?) -> Void in
                            if error != nil {
                                self.atext.text = "could not send data: \(error)"
                                
                            }
                            else {
                                self.atext.text = "Data was sent"
                            }
                        })
                    }
                    else {
                        self.atext.text = "Virtual stick control mode is unavailable"
                    }
                }
            })
        }
        
    }
    func runNSEWDirectionCommands(){
        //if the recongnition text matchesthe NSEW regex,then this method will execute
        if commands.count > 0 {
            for comm in commands {
                var dist: String
                var direction: String
                var unit: String
                
                var commandArr = comm.characters.split{$0 == " "}.map(String.init)
                
                direction = commandArr[1]
                
                if commandArr[2] == "by" {
                    if commandArr[3] == "to" { commandArr[3] = "2" }
                    if commandArr[3] == "to0" { commandArr[3] = "2" }
                    etext.text = "distance: \(commandArr[3])"
                    dist = commandArr[3]
                    ftext.text = "units: \(commandArr[4])"
                    units = commandArr[4]
                }
                else if commandArr[2] == "for" {
                    if commandArr[3] == "to" { commandArr[3] == "2"}
                    if commandArr[3] == "too" { commandArr[3] == "2"}
                    etext.text = "distance: \(commandArr[3])"
                    dist = commandArr[3]
                    ftext.text = "units: \(commandArr[4])"
                    units = commandArr[4]
                    
                } else {
                    if commandArr[3] == "to" { commandArr[3] == "2"}
                    if commandArr[3] == "too" { commandArr[3] == "2"}
                    etext.text = "distance: \(commandArr[3])"
                    dist = commandArr[3]
                    ftext.text = "units: \(commandArr[4])"
                    units = commandArr[4]
                }
                var distance: Double = Double(dist)!
                //by here, we have each command being seperated into direction, distance, units
                // next steps are find location, distance and direction of drone
                
                //cancel the current mission and remove all waypoints form waypoint list
                cancelMissionSaid()
                self.waypointMission.removeAllWaypoints()
                
                //get drone's direction
                var droneLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
                if self.currentState != nil && CLLocationCoordinate2DIsValid(self.currentState?.aircraftLocation){
                    droneLocation = self.currentState!.aircraftLocation
                    let waypoint: DJIWaypoint = DJIWaypoint(coordinate: droneLocation)
                    waypoint.altitude = ALTITUDE
                    self.waypointMission.add(waypoint)
                }
                var lat: Double = droneLocation.latitude
                var long: Double = droneLocation.longitude
                
                var commLoc: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
                
                //if units are in meters
                if units == "m" || units == "meter" || units == "meters" {
                    if direction == "east" {
                        long = long + convertMetersToPoint(m: distance)
                    }
                    if direction == "west" {
                        long = long + convertMetersToPoint(m: distance)
                    }
                    if direction == "noth" {
                        lat = lat + convertMetersToPoint(m: distance)
                    }
                    if direction == "south" {
                        lat = lat + convertMetersToPoint(m: distance)
                    }
                }
                // if units are in feet
                if units == "ft" || units == "feet" || units == "foot" {
                    if direction == "east" {
                        long = long + convertMetersToPoint(m: distance)
                    }
                    if direction == "west" {
                        long = long + convertMetersToPoint(m: distance)
                    }
                    if direction == "noth" {
                        lat = lat + convertMetersToPoint(m: distance)
                    }
                    if direction == "south" {
                        lat = lat + convertMetersToPoint(m: distance)
                    }
                }
                commLoc.latitude = lat
                commLoc.longitude = long
                
                if CLLocationCoordinate2DisValid(commLoc) {
                    let commWayPoint: DJIWaypoint = DJIWaypoint(coordinate: commLoc)
                    commLoc.altitude = ALTITUDE
                    self.waypointMission.add(commWayPoint)
                    
                }
                // 5 mission paramenter always needed
                self.waypointMission.maxFlightSpeed = 2
                self.waypointMission.autoFlightSpeed = 1
                self.waypointMission.headingMode = DJIWayPointMissionHeadingMode.auto
                self.waypointMission.flightPathMode = DJIWayPointMissionFlightPathMode.curved
                waypointMission.finishedAction = DJIWayPointMissionFinishedAction.noAction
                
                //prepare mission
                prepareMission(missionName: self.waypointMission)
            }
        }
    }
    func enableVirtualStickModeSaid() {
        fc?.enableVirtualStickControlMode(completion: {(error: Error) -> Void in
            if error != nil {
                self.atext.text = "virtual stick mode not enabled: \(error)"
            }
            else {
                self.atext.text = "virtual stick mode enabled"
                //missing some codes
                
            }
        })
    }
    
    //********** missing some functions *****************//
    
    //************ working drone methods *****************//
    func droneStartPropellers(_ fc: DJIFlightController!) {
        if fc != nil {
            fc!.turnOnMotors(completion: {[weak self](error: Error?) -> Void in
                if error != nil {
                    self?.showAlertResult("TurnOn Error: \(error!.localizedDescription)")
                }
                else {
                    self?.showAlertResult("Turnon Succeeded.")
                }
            })
        }
        else {
            self.showAlertResult("Component not existed")
        }
    }
    func droneTakeOff(_ fc: DJIFlightController!) {
        if fc != nil {
            fc!.takeoff(completion: {[weak self](error: Error?) -> Void in
                if error != nil {
                    self?.showAlertResult("TakeOff Error: \(error!.localizedDescription)")
                }
                else {
                    self?.showAlertResult("TakeOff Succeeded.")
                }
            })
        }
        else {
            self.showAlertResult("Component not existed")
        }
    }
    func droneLand(_ fc: DJIFlightController!) {
        if fc != nil {
            fc!.autoLanding(completion: {[weak self](error: Error?) -> Void in
                if error != nil {
                    self?.showAlertResult("Auto Landing Error: \(error!.localizedDescription)")
                }
                else {
                    self?.showAlertResult("Auto Landing Succeeded.")
                }
            })
        }
        else {
            self.showAlertResult("Component not existed")
        }
    }
    func droneStopPropellers(_ fc: DJIFlightController!) {
        if fc != nil {
            fc!.autoLanding(completion: {[weak self](error: Error?) -> Void in
                if error != nil {
                    self?.showAlertResult("Turn Off Error: \(error!.localizedDescription)")
                }
                else {
                    self?.showAlertResult("Turn Off Succeeded.")
                }
            })
        }
        else {
            self.showAlertResult("Component not existed")
        }
    }
    
    func productConnected() {
        guard let newProduct = DJISDKManager.product() else {
            NSLog("Product is connected but DJISDKManager.product is nil -> something is wrong")
            return;
        }
        
        //Updates the product's model
        self.productModel.text = "Model: \((newProduct.model)!)"
        self.productModel.isHidden = false
        
        //Updates the product's firmware version - COMING SOON
        newProduct.getFirmwarePackageVersion{ (version:String?, error:Error?) -> Void in
            
            self.productFirmwarePackageVersion.text = "Firmware Package Version: \(version ?? "Unknown")"
            
            if let _ = error {
                self.productFirmwarePackageVersion.isHidden = true
            }else{
                self.productFirmwarePackageVersion.isHidden = false
            }
            
            NSLog("Firmware package version is: \(version ?? "Unknown")")
        }
        
        //Updates the product's connection status
        self.productConnectionStatus.text = "Status: Product Connected"
        
        self.openComponents.isEnabled = true;
        self.openComponents.alpha = 1.0;
        NSLog("Product Connected")
    }
    
    func productDisconnected() {
        self.productConnectionStatus.text = "Status: No Product Connected"
        
        self.openComponents.isEnabled = false;
        self.openComponents.alpha = 0.8;
        NSLog("Product Disconnected")
    }
    
    
    
}

*/



