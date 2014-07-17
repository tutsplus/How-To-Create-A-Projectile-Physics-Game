//
//  MyScene.m
//  PhysicsDemoGame
//
//  Created by Richard Yeates on 2014-07-01.
//  Copyright (c) 2014 Richard Yeates. All rights reserved.
//

#import "MyScene.h"

@interface MyScene ()<SKPhysicsContactDelegate>
@end

@implementation MyScene {
    
    //Create Variables
    int currentLevel;
    
    NSDictionary *levelDict;
    
    SKSpriteNode *cannonBase;
    SKSpriteNode *cannon;
    SKSpriteNode *projectile;
    
    BOOL isThereAProjectile;
    CGVector projectileForce;
    int projectileTimer;
    
    BOOL isGameReseting;
    
}

//Create Physics Category Bit-Mask's
static const  uint32_t objectiveMask = 1 << 0;
static const  uint32_t otherMask = 1 << 1;


-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        [self loadLevel];
        
    }
    return self;
}

-(void)loadLevel {
    
    self.physicsWorld.contactDelegate = self; //set the contact delegate to self
    isGameReseting = NO;
    
    //set current level, in this demo we only have one
    currentLevel = 1;
    
    //create an edge-loop physics body for the screen, basically creating a "bounds"
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    
    //Create the Base of the Cannon
    cannonBase = [SKSpriteNode spriteNodeWithImageNamed:@"CannonBase"];
    cannonBase.position = CGPointMake(40, 10);
    cannonBase.zPosition = 100;
    [self addChild:cannonBase];
    
    //Create the Cannon
    cannon = [SKSpriteNode spriteNodeWithImageNamed:@"Cannon"];
    cannon.position = CGPointMake(50, 30);
    cannon.zRotation = 1;
    cannon.zPosition = 50;
    [self addChild:cannon];
    
    //Load the Level Data from the provided Plist file
    [self loadLevelFromPList];
}

-(void)loadLevelFromPList {
    //load the file from the plist
    NSString *fileName = [NSString stringWithFormat:@"Level%i", currentLevel];
    NSString *filePath = [[NSBundle mainBundle]pathForResource:fileName ofType:@"plist"];
    levelDict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    
    //use the level information to build the platform structure
    [self createPlatformStructures:levelDict[@"platforms"]];
    [self addObjectives:levelDict[@"objectives"]];
}

-(void)createPlatformStructures:(NSArray*)platforms {
    
    for (NSDictionary *platform in platforms) {
        //Grab Info From Dictionay and prepare variables
        int type = [platform[@"platformType"] intValue];
        CGPoint position = CGPointFromString(platform[@"platformPosition"]);
        SKSpriteNode *platSprite;
        platSprite.zPosition = 10;
        //Logic to populate level based on the platform type
        if (type == 1) {
            //Square
            platSprite = [SKSpriteNode spriteNodeWithImageNamed:@"SquarePlatform"]; //create sprite
            platSprite.position = position; //position sprite
            platSprite.name = @"Square";
            CGRect physicsBodyRect = platSprite.frame; //build a rectangle variable based on size
            platSprite.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:physicsBodyRect.size]; //build physics body
            platSprite.physicsBody.categoryBitMask = otherMask; //assign a category mask to the physics body
            platSprite.physicsBody.contactTestBitMask = objectiveMask; //create a contact test mask for physics body contact callbacks
            platSprite.physicsBody.usesPreciseCollisionDetection = YES;
            
        } else if (type == 2) {
            //Rectangle
            platSprite = [SKSpriteNode spriteNodeWithImageNamed:@"RectanglePlatform"]; //create sprite
            platSprite.position = position; //position sprite
            platSprite.name = @"Rectangle";
            CGRect physicsBodyRect = platSprite.frame; //build a rectangle variable based on size
            platSprite.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:physicsBodyRect.size]; //build physics body
            platSprite.physicsBody.categoryBitMask = otherMask; //assign a category mask to the physics body
            platSprite.physicsBody.contactTestBitMask = objectiveMask; //create a contact test mask for physics body contact callbacks
            platSprite.physicsBody.usesPreciseCollisionDetection = YES;
            
        } else if (type == 3) {
            //Triangle
            platSprite = [SKSpriteNode spriteNodeWithImageNamed:@"TrianglePlatform"]; //create sprite
            platSprite.position = position; //position sprite
            platSprite.name = @"Triangle";
            
            //Create a mutable path in the shape of a triangle, using the sprite bounds as a guideline
            CGMutablePathRef physicsPath = CGPathCreateMutable();
            CGPathMoveToPoint(physicsPath, nil, -platSprite.size.width/2, -platSprite.size.height/2);
            CGPathAddLineToPoint(physicsPath, nil, platSprite.size.width/2, -platSprite.size.height/2);
            CGPathAddLineToPoint(physicsPath, nil, 0, platSprite.size.height/2);
            CGPathAddLineToPoint(physicsPath, nil, -platSprite.size.width/2, -platSprite.size.height/2);
            
            platSprite.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:physicsPath]; //build physics body
            platSprite.physicsBody.categoryBitMask = otherMask; //assign a category mask to the physics body
            platSprite.physicsBody.contactTestBitMask = objectiveMask; //create a contact test mask for physics body contact callbacks
            platSprite.physicsBody.usesPreciseCollisionDetection = YES;
            CGPathRelease(physicsPath);//release the path now that we are done with it
            
        }
        
        [self addChild:platSprite];
        
    }
    
}

-(void)addObjectives:(NSArray*)objectives {
    
    for (NSDictionary* objective in objectives) {
        
        //Grab the position information from the dictionary provided from the plist
        CGPoint position = CGPointFromString(objective[@"objectivePosition"]);
        
        //create a sprite based on the info from the dictionary above
        SKSpriteNode *objSprite = [SKSpriteNode spriteNodeWithImageNamed:@"star"];
        objSprite.position = position;
        objSprite.name = @"objective";
        
        //Assign a physics body and physic properties to the sprite
        objSprite.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:objSprite.size.width/2];
        objSprite.physicsBody.categoryBitMask = objectiveMask;
        objSprite.physicsBody.contactTestBitMask = otherMask;
        objSprite.physicsBody.usesPreciseCollisionDetection = YES;
        objSprite.physicsBody.affectedByGravity = NO;
        objSprite.physicsBody.allowsRotation = NO;
        
        //add the child to the scene
        [self addChild:objSprite];
        
        //Create an action to make the objective more interesting
        SKAction *turn = [SKAction rotateByAngle:1 duration:1];
        SKAction *repeat = [SKAction repeatActionForever:turn];
        [objSprite runAction:repeat];
    }
    
}


-(void) addProjectile {
    //Create a sprite based on our image, give it a position and name
    projectile = [SKSpriteNode spriteNodeWithImageNamed:@"ball"];
    projectile.position = cannon.position;
    projectile.zPosition = 20;
    projectile.name = @"Projectile";
    
    //Assign a physics body to the sprite
    projectile.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:projectile.size.width/2];
    
    //Assign properties to the physics body (these all exist and have default values upon the creation of the body)
    projectile.physicsBody.restitution = 0.5;
    projectile.physicsBody.density = 5;
    projectile.physicsBody.friction = 1;
    projectile.physicsBody.dynamic = YES;
    projectile.physicsBody.allowsRotation = YES;
    projectile.physicsBody.categoryBitMask = otherMask;
    projectile.physicsBody.contactTestBitMask = objectiveMask;
    projectile.physicsBody.usesPreciseCollisionDetection = YES;
    
    //Add the sprite to the scene, with the physics body attached
    [self addChild:projectile];
    
}




-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches) {
        
        CGPoint location = [touch locationInNode:self];
        NSLog(@"Touched x:%f, y:%f", location.x, location.y);
        
        //Check if there is already a projectile in the scene
        if (!isThereAProjectile) {
            
            //If not, add it
            isThereAProjectile = YES;
            [self addProjectile];
            
            //Create a Vector to use as a 2D force value
            projectileForce = CGVectorMake(18, 18);
        
        
            for (SKSpriteNode *node in self.children){
            
                if ([node.name isEqualToString:@"Projectile"]) {
                    
                    //Apply an impulse to the projectile, overtaking gravity and friction temporarily
                    [node.physicsBody applyImpulse:projectileForce];
                }
            
            }
        }
   
        
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
    //This gets rid of the ball after it has been sitting for awhile so that we can shoot another
    if (isThereAProjectile) {
        projectileTimer++;
        if (projectileTimer>=300) {
            [projectile removeFromParent];
            projectileTimer = 0;
            isThereAProjectile = NO;
        }
    }
}

-(void)didBeginContact:(SKPhysicsContact *)contact
{
    //this is the contact listener method, we give it the contact assignments we care about and then perform actions based on the collision
    
    uint32_t collision = (contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask); //define a collision between two category masks
    if (collision == (otherMask| objectiveMask)) {
        //handle the collision from the above if statement, you can create more if/else statements for more categories
        if (!isGameReseting) {
            
            NSLog(@"You Win!");
            isGameReseting = YES;
            
            //Set up a little action/animation for when an objective is hit
            SKAction *scaleUp = [SKAction scaleTo:1.25 duration:0.5];
            SKAction *tint = [SKAction colorizeWithColor:[UIColor redColor] colorBlendFactor:1 duration:0.5];
            SKAction *blowUp = [SKAction group:@[scaleUp, tint]];
            SKAction *scaleDown = [SKAction scaleTo:0.2 duration:0.75];
            SKAction *fadeOut = [SKAction fadeAlphaTo:0 duration:0.75];
            SKAction *blowDown = [SKAction group:@[scaleDown, fadeOut]];
            SKAction *remove = [SKAction removeFromParent];
            SKAction *sequence = [SKAction sequence:@[blowUp, blowDown, remove]];
            
            //Figure out which of the contact bodies is an objective by checking it's name, and then run the action on it
            if ([contact.bodyA.node.name isEqualToString:@"objective"]) {
                    
                [contact.bodyA.node runAction:sequence];
                    
            } else if ([contact.bodyB.node.name isEqualToString:@"objective"]) {
                
                [contact.bodyB.node runAction:sequence];
                
            }
            
            //after a few seconds, restart the level
            [self performSelector:@selector(gameOver) withObject:nil afterDelay:3.0f];
        }

    }
}

-(void) gameOver {
    //start over
    [self removeAllChildren];
    [self loadLevel];
}

@end
