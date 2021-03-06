//
//  GameScene.swift
//  marbleBall
//
//  Created by Patrick Hayes on 11/2/17.
//  Copyright © 2017 Patrick Hayes. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var starfield: SKEmitterNode!
    var player: SKSpriteNode!
    
    var scoreLabel: SKLabelNode!
    var score:Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var gameTimer: Timer!
    
    var possibleAliens = ["bottle1", "bottle2", "diaper1", "diaper2", "pacifier"]
    
    let alienCategory:UInt32 = 0x1 << 1
    let photonTorpedoCategory:UInt32 = 0x1 << 0
    let itemCategory:UInt32 = 0x1 << 1 //for the items that drop down
    let playerCategory:UInt32 = 0x1 << 0 //for baby
    
    
    let motionManager = CMMotionManager()
    var xAcceleration:CGFloat = 0
    
    
    
    override func didMove(to view: SKView) {
        
        starfield = SKEmitterNode(fileNamed: "Starfield")
        starfield.position = CGPoint(x: 0, y: 1472)
        starfield.advanceSimulationTime(10)
        self.addChild(starfield)
        
        starfield.zPosition = -1
        
        player = SKSpriteNode(imageNamed: "happyBaby")
        
        
        player.position = CGPoint(x: 0.5, y: -UIScreen.main.bounds.height+70)
        
        
        //test code for player collision+++++++
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size) //SET BODY OF PLAYER
        player.physicsBody?.isDynamic = true //MAKE BODY OF PLAYER DYNAMIC OTHERWISE NO COLLISIONS
        //COLLISION LOGIC
        player.physicsBody?.categoryBitMask = playerCategory
        player.physicsBody?.contactTestBitMask = itemCategory
        player.physicsBody?.collisionBitMask = 0
        player.physicsBody?.usesPreciseCollisionDetection = true
        //+++++++
        
        self.addChild(player)
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        
        
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: -250.0, y: 600)
        scoreLabel.fontName = "AmericanTypewriter-Bold" //ios fonts
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = UIColor.white
        score = 0
        
        self.addChild(scoreLabel)
        
        gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        
        
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data:CMAccelerometerData?, error: Error?) in if let accelerometerData = data {
                    let acceleration = accelerometerData.acceleration
            self.xAcceleration = CGFloat(acceleration.x) * 0.75 + self.xAcceleration * 0.25
            }
        }
        
        
        
        
    }
    
    @objc func addAlien(){
        possibleAliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleAliens) as! [String]
        
        let alien = SKSpriteNode(imageNamed: possibleAliens[0])
        
        let randomAlienPosition = GKRandomDistribution(lowestValue: -((Int(UIScreen.main.bounds.width))/2), highestValue: Int(UIScreen.main.bounds.width)/2) //working now
        let position = CGFloat(randomAlienPosition.nextInt())
        
        alien.position = CGPoint(x: position, y: self.frame.size.height + alien.size.height)
        
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        
        alien.physicsBody?.categoryBitMask = itemCategory //before = alienCategory
        alien.physicsBody?.contactTestBitMask = playerCategory  //before = photonTorpedoCategory
        alien.physicsBody?.collisionBitMask = 0
        
        self.addChild(alien)
        
        let animationDuration:TimeInterval = 6
        
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -UIScreen.main.bounds.height), duration: animationDuration)) //need to adjust y
        actionArray.append(SKAction.removeFromParent()) //when it moves off screen we remove it
        
        alien.run(SKAction.sequence(actionArray))
        
    }
    
    
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        fireTorpedo()
//    }
    
//    func fireTorpedo(){
//        self.run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
//
//        let torpedoNode = SKSpriteNode(imageNamed: "torpedo")
//        torpedoNode.position = player.position
//        torpedoNode.position.y += 5
//
//        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width/2)
//        torpedoNode.physicsBody?.isDynamic = true
//
//        torpedoNode.physicsBody?.categoryBitMask = photonTorpedoCategory
//        torpedoNode.physicsBody?.contactTestBitMask = alienCategory
//        torpedoNode.physicsBody?.collisionBitMask = 0
//        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
//        self.addChild(torpedoNode)
//
//        let animationDuration: TimeInterval = 1.0 //this adjusts the "speed" of the bullet on screen
//
//        var actionArray = [SKAction]()
//
//        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x, y: self.frame.size.height+10), duration: animationDuration)) //torpedo position
//        actionArray.append(SKAction.removeFromParent()) //when it moves off screen we remove it
//
//        torpedoNode.run(SKAction.sequence(actionArray))
//
//
//    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        //below, first body was photonTorpedoCategory
        if (firstBody.categoryBitMask & playerCategory) != 0 && (secondBody.categoryBitMask & itemCategory) != 0 {
            babyDidCollideWithItem(babyNode: firstBody.node as! SKSpriteNode, itemNode: secondBody.node as! SKSpriteNode) //was torpedoDidCollideWithAlien
        }
    }
    
//    func torpedoDidCollideWithAlien (torpedoNode: SKSpriteNode, alienNode: SKSpriteNode){
//        let explosion = SKEmitterNode(fileNamed: "Explosion")!
//        explosion.position = alienNode.position
//        self.addChild(explosion)
//
//        self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
//
//        torpedoNode.removeFromParent() //removing from screen
//        alienNode.removeFromParent() //removing from screen
//
//        self.run(SKAction.wait(forDuration: 2)) {
//            explosion.removeFromParent()
//        }
//
//        score += 5
//    }
    
    func babyDidCollideWithItem (babyNode: SKSpriteNode, itemNode: SKSpriteNode){
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = itemNode.position
        self.addChild(explosion)
        
        self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
        
        itemNode.removeFromParent() //removing from screen
        
        self.run(SKAction.wait(forDuration: 2)) {
            explosion.removeFromParent()
        }
        
        score += 5
        
    }
    
    //movement of player
    override func didSimulatePhysics() {
        
        player.position.x += xAcceleration * 50
        
        if player.position.x < -20 {
            player.position = CGPoint(x: self.size.width + 20, y: player.position.y)
        } else if player.position.x > self.size.width + 20{
            player.position = CGPoint(x: -20, y: player.position.y)
        }
        
        
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
