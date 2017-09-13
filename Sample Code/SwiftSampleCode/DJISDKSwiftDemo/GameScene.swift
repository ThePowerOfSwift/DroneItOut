//
//  GameScene.swift
//  DroneItOut
//
//  Created by Daniel Nguyen on 9/7/17.
//  Copyright © 2017 DJI. All rights reserved.
//
import UIKit
import SpriteKit
import SpeechKit

var backgroundColorCustom = UIColor.white

class GameScene: SKScene, SKTransactionDelegate {
    
    var skSession: SKSession?
    var skTransaction: SKTransaction?
    
    var Drone = SKSpriteNode()
    var myLabel: SKLabelNode!
    var TextureAtlas = SKTextureAtlas()
    var TextureArray = [SKTexture]()
    var flightWobble = [SKAction]()
    
    override func didMove(to view: SKView) {
        self.backgroundColor = backgroundColorCustom
        
        myLabel = SKLabelNode(fontNamed: "Arial")
        myLabel.text = "tap and command"
        myLabel.fontSize = 20
        myLabel.position = CGPoint(x: self.size.width / 2, y: 50)
        myLabel.fontColor = UIColor.black
        
        self.addChild(myLabel)
        
        TextureAtlas = SKTextureAtlas(named: "droneflight")
        
        NSLog("\(TextureAtlas.textureNames)")
        
        //adding animation images to texture array
        TextureArray.append(SKTexture(imageNamed: "2drone.png"))
        TextureArray.append(SKTexture(imageNamed: "3drone.png"))
        TextureArray.append(SKTexture(imageNamed: "4drone.png"))
        TextureArray.append(SKTexture(imageNamed: "1drone.png"))
        
        flightWobble.append(SKAction.move(by: CGVector(dx: 15, dy: 0), duration: 3))
        flightWobble.append(SKAction.move(by: CGVector(dx: -15, dy: 0), duration: 3))
        flightWobble.append(SKAction.move(by: CGVector(dx: -15, dy: 0), duration: 3))
        flightWobble.append(SKAction.move(by: CGVector(dx: 15, dy: 0), duration: 3))
        flightWobble.append(SKAction.move(by: CGVector(dx: 15, dy: 0), duration: 3))
        flightWobble.append(SKAction.move(by: CGVector(dx: -15, dy: 0), duration: 3))
        flightWobble.append(SKAction.move(by: CGVector(dx: -15, dy: 0), duration: 3))
        flightWobble.append(SKAction.move(by: CGVector(dx: 15, dy: 0), duration: 3))
        
        //positioning drone animation and adding child node to the view
        Drone = SKSpriteNode(imageNamed: TextureAtlas.textureNames[1])
        Drone.size = CGSize(width: 330, height: 355)
        Drone.position = CGPoint(x: self.size.width / 2, y: 150 )
        self.addChild(Drone)
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { //neeed to have developer sandbox credentials to
        let SKSAppKey = "58a9d765dc6825c013e1bbbee16c7d7564e6263b3a285e7dd8a9b840282bcf80d5a6e5b10e0a7222ec2de0cd9a5d42fe4468397e9098fc6841b4a86adf77eab4";         //start a session
        let SKSAppId = "NMDPPRODUCTION_daniel_nguyen_DroneItOut_20170912190938";
        let SKSServerHost = "lij.nmdp.nuancemobility.net 443";
        let SKSServerPort = "443";
        
        let SKSLanguage = "eng-USA";
        
        let SKSServerUrl = "nmsps://NMDPTRIAL_danieltn91_gmail_com20170911202728@sslsandbox-nmdp.nuancemobility.net:433"
        
        
        
        let session = SKSession(url: URL(string: SKSServerUrl), appToken: SKSAppKey)
        

        skTransaction = session?.recognize(withType: SKTransactionSpeechTypeDictation, detection: .short, language: SKSLanguage, delegate: self)
    
    }
    
    
    private func transaction(transaction: SKTransaction!, didReceiveRecognition recognition: SKRecognition!) {
        
        myLabel.text = recognition.text.lowercased()
        
        let words = recognition.text.lowercased()
        print(recognition.text.lowercased())
        
        var strArr = words.characters.split{$0 == " "}.map(String.init)
        
        var distance: CGFloat = 0
        var direction: String = " "
        var goCalled: Bool = false
        var inFlight: Bool = false
        
        //set up animation actions that can be run using a key to activate/deactivate them
        let land: SKAction = SKAction.move(to: CGPoint(x: self.size.width / 2, y: 150 ), duration: 2.0 )
        let propellers: SKAction = SKAction.repeatForever(SKAction.animate(with: TextureArray, timePerFrame: 0.05))
        let wobble: SKAction = SKAction.sequence(flightWobble)
        
        //start the propellers
        if strArr[0] == "power"{
            if strArr[1] == "on" {
                //                Drone.paused = false
                Drone.run(propellers, withKey: "action1")
            }
            if strArr[1] == "off" {
                //                Drone.paused = true
                Drone.removeAction(forKey: "action1")
                Drone.texture = SKTexture(imageNamed: "2drone.png")
            }
        }
        
        // for simple flight commands
        for str in strArr{
            if str == "land" {
                inFlight = false
                Drone.run(land)
                Drone.removeAction(forKey: "wobbleAction")
            }
            // go command
            if str == "go" {
                goCalled = true
                inFlight = true
            }
            //get distance from array
            if let number = Int(str){
                distance = CGFloat(number)
                print("distance = " + String(describing: distance))
            }
            //get direction from array
            if str == "up" {
                direction = str
                print("direction = " + direction)
            }
            if str == "down" {
                direction = str
                print("direction = " + direction)
            }
            //just for fun!
            if str == "charleston" {
                Drone.size.width += 100
                Drone.size.height += 100
                backgroundColor = UIColor(red: 0.6863, green: 0, blue: 0.0431, alpha: 1.0) /* #af000b */
                myLabel.fontColor = UIColor.white
            }
            //turn it back to normal
            if str == "normal" {
                Drone.size.width -= 100
                Drone.size.height -= 100
                backgroundColor = UIColor.white
                myLabel.fontColor = UIColor.black
            }
        }
        
        if goCalled {
            let upSequence = SKAction.moveBy(x: 0, y: distance * 10, duration: 1.2 )
            let downSequence = SKAction.moveBy(x: 0, y: -(distance * 10), duration: 1.2)
            
            if direction == "up" {
                Drone.run(upSequence)
            }
            if direction == "down" {
                Drone.run(downSequence)
            }
        }
        //if drone is in flight, run the wobble animation sequence
        if inFlight{
            Drone.run(wobble, withKey: "wobbleAction")
        }
    }
    
    override func update(_ currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    


}

