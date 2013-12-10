//
//  MyScene.m
//  Myshooter
//
//  Created by qainfotech on 10/12/13.
//  Copyright (c) 2013 qainfotech. All rights reserved.
//
@import CoreMotion;
@import AVFoundation;
#import "MyScene.h"
#import "FMMParallaxNode.h"
#define kNumAsteroids   15
#define kNumLasers      5


@implementation MyScene
{
    SKSpriteNode *tanker;
    FMMParallaxNode *_parallaxNodeBackgrounds;
    FMMParallaxNode *_parallaxSpaceDust;
    CMMotionManager *_motionManager;
    
    NSMutableArray *_asteroids;
    int _nextAsteroid;
    double _nextAsteroidSpawn;
    NSMutableArray *_shipLasers;
    int _nextShipLaser;
    int _lives;
    AVAudioPlayer *_backgroundAudioPlayer;
    
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        NSLog(@"SKSCENE init withSize %f X %f",size.width,size.height);
        self.backgroundColor=[SKColor blackColor];
        
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];

        
        tanker = [SKSpriteNode spriteNodeWithImageNamed:@"SpaceFlier_sm_1.png"];
        tanker.position = CGPointMake(self.frame.size.width * 0.1, CGRectGetMidY(self.frame));
        [self addChild:tanker];
        
        
        
        
        
        [self addChild:[self loadEmitterNode:@"stars1"]];
        [self addChild:[self loadEmitterNode:@"stars2"]];
        [self addChild:[self loadEmitterNode:@"stars3"]];
        [self addChild:[self loadEmitterNode:@"MyParticle"]];

        _motionManager = [[CMMotionManager alloc] init];
        _nextAsteroidSpawn = 0;
        
        for (SKSpriteNode *asteroid in _asteroids) {
            asteroid.hidden = YES;
        }
        [self startBackgroundMusic];
        [self startTheGame];
        
        
        
#pragma mark - Game Backgrounds
        //1
        NSArray *parallaxBackgroundNames = @[@"bg_galaxy.png", @"bg_planetsunrise.png",
                                             @"bg_spacialanomaly.png", @"bg_spacialanomaly2.png"];
        CGSize planetSizes = CGSizeMake(200.0, 200.0);
        //2
        _parallaxNodeBackgrounds = [[FMMParallaxNode alloc] initWithBackgrounds:parallaxBackgroundNames
                                                                           size:planetSizes
                                                           pointsPerSecondSpeed:10.0];
        //3
        _parallaxNodeBackgrounds.position = CGPointMake(size.width/2.0, size.height/2.0);
        //4
        [_parallaxNodeBackgrounds randomizeNodesPositions];
        
        //5
        [self addChild:_parallaxNodeBackgrounds];
        
        //6
        NSArray *parallaxBackground2Names = @[@"bg_front_spacedust.png",@"bg_front_spacedust.png"];
        _parallaxSpaceDust = [[FMMParallaxNode alloc] initWithBackgrounds:parallaxBackground2Names
                                                                     size:size
                                                     pointsPerSecondSpeed:25.0];
        _parallaxSpaceDust.position = CGPointMake(0, 0);
        [self addChild:_parallaxSpaceDust];
        
        
        
        
        
        _asteroids = [[NSMutableArray alloc] initWithCapacity:kNumAsteroids];
        for (int i = 0; i < kNumAsteroids; ++i) {
            SKSpriteNode *asteroid = [SKSpriteNode spriteNodeWithImageNamed:@"asteroid"];
            asteroid.hidden = YES;
            [asteroid setXScale:0.5];
            [asteroid setYScale:0.5];
            [_asteroids addObject:asteroid];
            [self addChild:asteroid];
        }
        
        
        _shipLasers = [[NSMutableArray alloc] initWithCapacity:kNumLasers];
        for (int i = 0; i < kNumLasers; ++i) {
            SKSpriteNode *shipLaser = [SKSpriteNode spriteNodeWithImageNamed:@"laserbeam_blue"];
            shipLaser.hidden = YES;
            [_shipLasers addObject:shipLaser];
            [self addChild:shipLaser];
        }
        
        
    
    }
    return self;
}

- (void)startBackgroundMusic
{
    NSError *err;
    NSURL *file = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"SpaceGame.caf" ofType:nil]];
    _backgroundAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:file error:&err];
    if (err) {
        NSLog(@"error in audio play %@",[err userInfo]);
        return;
    }
    [_backgroundAudioPlayer prepareToPlay];
    
    // this will play the music infinitely
    _backgroundAudioPlayer.numberOfLoops = -1;
    [_backgroundAudioPlayer setVolume:1.0];
    [_backgroundAudioPlayer play];
}
- (SKEmitterNode *)loadEmitterNode:(NSString *)emitterFileName
{
    NSString *emitterPath = [[NSBundle mainBundle] pathForResource:emitterFileName ofType:@"sks"];
    SKEmitterNode *emitterNode = [NSKeyedUnarchiver unarchiveObjectWithFile:emitterPath];
    
    //do some view specific tweaks
    emitterNode.particlePosition = CGPointMake(self.size.width/2.0, self.size.height/2.0);
    emitterNode.particlePositionRange = CGVectorMake(self.size.width+100, self.size.height);
    
    return emitterNode;
}


- (void)startTheGame
{
    tanker.hidden = NO;
    //reset ship position for new game
    tanker.position = CGPointMake(self.frame.size.width * 0.1, CGRectGetMidY(self.frame));
    
    
    //move the ship using Sprite Kit's Physics Engine
    //1
    tanker.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:tanker.frame.size];
    
    //2
    tanker.physicsBody.dynamic = YES;
    
    //3
    tanker.physicsBody.affectedByGravity = NO;
    
    //4
    tanker.physicsBody.mass = 0.02;
    
    
    
    for (SKSpriteNode *laser in _shipLasers) {
        laser.hidden = YES;
    }
    
    //setup to handle accelerometer readings using CoreMotion Framework
    [self startMonitoringAcceleration];
    
}

- (void)startMonitoringAcceleration
{
    if (_motionManager.accelerometerAvailable) {
        [_motionManager startAccelerometerUpdates];
        NSLog(@"accelerometer updates on...");
    }
}

- (void)stopMonitoringAcceleration
{
    if (_motionManager.accelerometerAvailable && _motionManager.accelerometerActive) {
        [_motionManager stopAccelerometerUpdates];
        NSLog(@"accelerometer updates off...");
    }
}

- (void)updateShipPositionFromMotionManager
{
    CMAccelerometerData* data = _motionManager.accelerometerData;
    if (fabs(data.acceleration.x) > 0.2) {
        NSLog(@"acceleration value = %f",data.acceleration.x);
        [tanker.physicsBody applyForce:CGVectorMake(0, 30 * data.acceleration.x)];

    }

}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    SKSpriteNode *shipLaser = [_shipLasers objectAtIndex:_nextShipLaser];
    _nextShipLaser++;
    if (_nextShipLaser >= _shipLasers.count) {
        _nextShipLaser = 0;
    }
    
    //2
    shipLaser.position = CGPointMake(tanker.position.x+shipLaser.size.width/2,tanker.position.y+0);
    shipLaser.hidden = NO;
    [shipLaser removeAllActions];
    
    //3
    CGPoint location = CGPointMake(self.frame.size.width, tanker.position.y);
    SKAction *laserFireSoundAction = [SKAction playSoundFileNamed:@"laser_ship.caf" waitForCompletion:NO];
    SKAction *laserMoveAction = [SKAction moveTo:location duration:0.5];
    //4
    
    
    SKAction *laserDoneAction = [SKAction runBlock:(dispatch_block_t)^() {
        //NSLog(@"Animation Completed");
        shipLaser.hidden = YES;
    }];
    
    //5
    SKAction *moveLaserActionWithDone = [SKAction sequence:@[laserFireSoundAction, laserMoveAction,laserDoneAction]];
    //6
    [shipLaser runAction:moveLaserActionWithDone withKey:@"laserFired"];}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    //Update background (parallax) position
    [_parallaxSpaceDust update:currentTime];
    [_parallaxNodeBackgrounds update:currentTime];
    [self updateShipPositionFromMotionManager];
    
    double curTime = CACurrentMediaTime();
    if (curTime > _nextAsteroidSpawn) {
        //NSLog(@"spawning new asteroid");
        float randSecs = [self randomValueBetween:0.20 andValue:1.0];
        _nextAsteroidSpawn = randSecs + curTime;
        
        float randY = [self randomValueBetween:0.0 andValue:self.frame.size.height];
        float randDuration = [self randomValueBetween:2.0 andValue:10.0];
        
        SKSpriteNode *asteroid = [_asteroids objectAtIndex:_nextAsteroid];
        _nextAsteroid++;
        
        if (_nextAsteroid >= _asteroids.count) {
            _nextAsteroid = 0;
        }
        
        [asteroid removeAllActions];
        asteroid.position = CGPointMake(self.frame.size.width+asteroid.size.width/2, randY);
        asteroid.hidden = NO;
        
        CGPoint location = CGPointMake(-self.frame.size.width-asteroid.size.width, randY);
        
        SKAction *moveAction = [SKAction moveTo:location duration:randDuration];
        SKAction *doneAction = [SKAction runBlock:(dispatch_block_t)^() {
            //NSLog(@"Animation Completed");
            asteroid.hidden = YES;
        }];
        
        SKAction *moveAsteroidActionWithDone = [SKAction sequence:@[moveAction, doneAction ]];
        [asteroid runAction:moveAsteroidActionWithDone withKey:@"asteroidMoving"];
        
        
        
        //check for laser collision with asteroid
        for (SKSpriteNode *asteroid in _asteroids) {
            if (asteroid.hidden) {
                continue;
            }
            for (SKSpriteNode *shipLaser in _shipLasers) {
                if (shipLaser.hidden) {
                    continue;
                }
                
                if ([shipLaser intersectsNode:asteroid]) {
                    
                    
                    SKAction *asteroidExplosionSound = [SKAction playSoundFileNamed:@"explosion_small.caf" waitForCompletion:NO];
                    [asteroid runAction:asteroidExplosionSound];
                    shipLaser.hidden = YES;
                    asteroid.hidden = YES;
                    
                    NSLog(@"you just destroyed an asteroid");
                    continue;
                }
            }
            if ([tanker intersectsNode:asteroid]) {
                asteroid.hidden = YES;
                SKAction *blink = [SKAction sequence:@[[SKAction fadeOutWithDuration:0.1],
                                                       [SKAction fadeInWithDuration:0.1]]];
                SKAction *blinkForTime = [SKAction repeatAction:blink count:4];
                SKAction *shipExplosionSound = [SKAction playSoundFileNamed:@"explosion_large.caf" waitForCompletion:NO];
                [tanker runAction:[SKAction sequence:@[shipExplosionSound,blinkForTime]]];
                _lives--;
                NSLog(@"your ship has been hit!");
            }
        }
    }
}

- (float)randomValueBetween:(float)low andValue:(float)high {
    return (((float) arc4random() / 0xFFFFFFFFu) * (high - low)) + low;
}

@end
