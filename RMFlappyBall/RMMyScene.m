//
//  RMMyScene.m
//  RMFlappyBall
//
//  Created by Ryosuke Mihara on 2014/02/22.
//  Copyright (c) 2014年 Ryosuke Mihara. All rights reserved.
//

#import "RMMyScene.h"

enum {
    RMMyScenePhaseGetReady,
    RMMyScenePhaseGame,
    RMMyScenePhaseGameOver,
    RMMyScenePhaseMedal
};
typedef NSUInteger RMMyScenePhase;

// ball
static const CGFloat kBallWidth = 32.0;
static const CGFloat kGravity = -9.8 * 0.9;
static const CGFloat kFlappingVelocityY = 390.0;

// floor
static const CGFloat kFloorHeight = 128.0;

// wall
static const CGFloat kWallWidth = 50.0;
static const CGFloat kHoleHeight = 3.2;
static const int kNumWallDivision = 15;
static const int kUpperWallHeightMin = 3;
static const int kUpperWallHeightMax = 7;
static const CGFloat kIntervalBetweenWallProductions = 1.4;
static const CGFloat kTimeTakenForWallGoThroughScreen = 3.0;

@interface RMMyScene () {
    RMMyScenePhase phase_;
    int points_;
    
    UIColor *ballColor_;
    UIColor *wallColor_;
    UIColor *fontColor_;
    NSString *fontName_;
}
@end

@implementation RMMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        ballColor_ = [UIColor colorWithRed:1.0 green:0.26 blue:0.45 alpha:1.0];
        wallColor_ = [UIColor cyanColor];
        fontColor_ = [UIColor colorWithRed:1.0 green:0.26 blue:0.45 alpha:1.0];
        fontName_ = @"AmericanTypewriter-Bold";
        
        [self setBackgroundColor:[UIColor whiteColor]];
        [self getReady];
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (phase_ == RMMyScenePhaseGame) {
        SKNode *ball = [self childNodeWithName:@"ball"];
        [[ball physicsBody] setVelocity:
         CGVectorMake(0.0, kFlappingVelocityY)];
    }
    else if (phase_ == RMMyScenePhaseMedal) {
        SKSpriteNode *cover =
        [SKSpriteNode spriteNodeWithColor:[UIColor blackColor] size:self.size];
        [cover setAlpha:0.0];
        [cover setName:@"cover"];
        [cover setPosition:CGPointMake(self.size.width/2., self.size.height/2.)];
        [cover setZPosition:10000];
        [self addChild:cover];
        [cover runAction:
         [SKAction sequence:@[[SKAction fadeInWithDuration:0.3],
                              [SKAction runBlock:^{ [self getReady]; }],
                              [SKAction fadeOutWithDuration:0.3],
                              [SKAction removeFromParent]]]];
    }
    else if (phase_ == RMMyScenePhaseGetReady) {
        [self startGame];
        SKNode *ball = [self childNodeWithName:@"ball"];
        [[ball physicsBody] setVelocity:
         CGVectorMake(0.0, kFlappingVelocityY)];
    }
}

#pragma mark - Phase

/**
 *  Moves to "Get Ready" phase.
 */
- (void)getReady {
    for (SKNode *node in [self children]) {
        if (![[node name] isEqualToString:@"cover"]) {
            [node removeFromParent];
        }
    }
    [self putBall];
    
    SKNode *ball = [self childNodeWithName:@"ball"];
    [[ball physicsBody] setAffectedByGravity:NO];
    
    [ball runAction:
     [SKAction repeatActionForever:
      [SKAction sequence:
  @[[SKAction moveBy:CGVectorMake(0.0, kBallWidth*0.35) duration:0.4],
    [SKAction moveBy:CGVectorMake(0.0, -kBallWidth*0.35) duration:0.35]]]]];
    
    [self putFloor];
    
    phase_ = RMMyScenePhaseGetReady;
}

/**
 *  Moves to game over phase.
 */
- (void)gameOver {
    [self removeAllActions];
    for (SKNode *node in [self children]) {
        [node removeAllActions];
    };
    [self putGameOverLabel];
    phase_ = RMMyScenePhaseGameOver;
}

/**
 *  Starts game.
 */
- (void)startGame {
    for (SKNode *node in [self children]) {
        if (![[node name] isEqualToString:@"floor"]) {
            [node removeFromParent];
        }
    }
    
    [[self physicsWorld] setGravity:CGVectorMake(0.0, kGravity)];
    [[self physicsWorld] setContactDelegate:self];
    [self putBall];
    [self putWallsPeriodically];
    [self putPointsLabel];

    points_ = 0;
    phase_ = RMMyScenePhaseGame;
}

#pragma mark - 1. Ball

/**
 *  Returns a ball image.
 *
 *  @param size Size of ball image.
 *
 *  @return Ball image.
 */
UIImage *ballImage(CGSize size, CGColorRef color) {
    UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 2.0);
    CGContextSetFillColorWithColor(context, color);
    CGContextFillEllipseInRect(context, (CGRect){CGPointZero, size});
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

/**
 *  Puts the ball.
 */
- (void)putBall {
    CGSize size = CGSizeMake(kBallWidth, kBallWidth);
    
    SKSpriteNode *ball =
    [SKSpriteNode spriteNodeWithTexture:
     [SKTexture textureWithImage:ballImage(size, [ballColor_ CGColor])]];
    [ball setSize:size];
    [ball setPosition:CGPointMake(self.size.width / 4., self.size.height / 2.)];
  
    SKPhysicsBody *body = [SKPhysicsBody bodyWithCircleOfRadius:kBallWidth / 2.];
    [body setContactTestBitMask:1];
    [ball setPhysicsBody:body];

    [ball setName:@"ball"];
    [self addChild:ball];
}

#pragma mark - 2. Floor

/**
 *  Returns a floor image.
 *
 *  @param size Size of the floor image.
 *
 *  @return Floor image.
 */
UIImage *floorImage(CGSize size)
{
    UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
    
    CGFloat dashes[] = {16.0, 16.0};
    CGContextSetRGBFillColor(context, 0.8, 0.8, 0.8, 1.0);
    CGContextFillRect(context, (CGRect){CGPointZero, size});
    CGContextSetRGBStrokeColor(context, 0.5, 0.5, 0.5, 1.0);
    CGContextSetLineDash(context, 0, dashes, 2);
    CGContextSetLineWidth(context, 2.0);
    for (int i = 0; i < 3; i++) {
        CGContextMoveToPoint(context, 0.0, i * 2);
        CGContextAddLineToPoint(context, size.width, i * 2);
    }
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

/**
 *  Puts floor.
 */
- (void)putFloor {
    CGSize size = CGSizeMake(self.size.width * 2., kFloorHeight);

    SKSpriteNode *floor =
    [SKSpriteNode spriteNodeWithTexture:
     [SKTexture textureWithImage:floorImage(size)]];
    [floor setSize:size];
    [floor setPosition:CGPointMake(self.size.width, size.height/2.)];
    [floor setName:@"floor"];
    [floor setZPosition:4000];
    
    CGFloat speed =
    kTimeTakenForWallGoThroughScreen / (self.size.width+kWallWidth);
    NSTimeInterval interval =  self.size.width * speed;
    
    SKPhysicsBody *body = [SKPhysicsBody bodyWithRectangleOfSize:floor.size];
    [body setAffectedByGravity:NO];
    [body setDynamic:NO];
    [floor setPhysicsBody:body];
    [floor runAction:[SKAction repeatActionForever:
                      [SKAction sequence:
  @[[SKAction moveTo:CGPointMake(0.0, size.height/2.)
            duration:interval],
    [SKAction moveTo:CGPointMake(self.size.width, size.height/2.) duration:0.0]]]]];
    
    [self addChild:floor];
}

#pragma mark - 3. Wall

/**
 *  Puts wall.
 *
 *  @param height Height of the wall.
 *  @param y      Y-ordinate position of the wall.
 */
- (void)putWallWithHeight:(CGFloat)height y:(CGFloat)y {
    SKSpriteNode *wall =
    [SKSpriteNode spriteNodeWithColor:wallColor_
                                 size:CGSizeMake(kWallWidth, height)];
    [wall setPosition:CGPointMake(self.size.width + kWallWidth / 2., y)];
    
    SKPhysicsBody *body = [SKPhysicsBody bodyWithRectangleOfSize:wall.size];
    [body setAffectedByGravity:NO];
    [body setDynamic:NO];
    [wall setPhysicsBody:body];
    
    [wall runAction:[SKAction sequence:
  @[[SKAction moveTo:
     CGPointMake(-kWallWidth / 2., y) duration:kTimeTakenForWallGoThroughScreen],
    [SKAction removeFromParent]]]];
    
    [self addChild:wall];
}

/**
 *  Puts 2 walls at the right edge of the screen.
 */
- (void)putWalls {
    CGFloat unit = self.size.height / 15.0;
    
    CGFloat upperWallHeight =
    unit * (arc4random() % (kUpperWallHeightMax - kUpperWallHeightMin)
            + kUpperWallHeightMin);
    
    CGFloat bottomWallHeight =
    self.size.height - upperWallHeight - unit * kHoleHeight;
    
    [self putWallWithHeight:upperWallHeight
                          y:self.size.height - upperWallHeight / 2.];
    [self putWallWithHeight:bottomWallHeight
                          y:bottomWallHeight / 2.];
}

/**
 *  Puts walls periodically forever.
 */
- (void)putWallsPeriodically {
    [self runAction:
     [SKAction repeatActionForever:
      [SKAction sequence:
  @[[SKAction waitForDuration:kIntervalBetweenWallProductions],
    [SKAction runBlock:^{
          [self putWalls];
          
          [self runAction:
           [SKAction sequence:
  @[[SKAction waitForDuration:kTimeTakenForWallGoThroughScreen * 0.75],
    [SKAction runBlock:^{
               SKNode *ball = [self childNodeWithName:@"ball"];
               if ([ball position].y > self.size.height) {
                   [self gameOver];
               }
               else {
                   [self incrementPoints];
               }
           }]]]];
      }]]]]];
}

#pragma mark - 4. Points

/**
 *  Puts the points label.
 */
- (void)putPointsLabel {
    SKLabelNode *label =
    [SKLabelNode labelNodeWithFontNamed:fontName_];
    [label setName:@"points"];
    [label setFontSize:36.0];
    [label setFontColor:fontColor_];
    [label setText:@"0"];
    [label setPosition:CGPointMake(self.size.width/2., self.size.height*0.75)];
    [label setZPosition:5000];
    [self addChild:label];
}

/**
 *  Increments points and updates the points label.
 */
- (void)incrementPoints {
    SKLabelNode *label = (SKLabelNode *)[self childNodeWithName:@"points"];
    [label setText:[NSString stringWithFormat:@"%d", ++points_]];
}

#pragma mark - 5. Game Over

/**
 *  Puts the game over label.
 */
- (void)putGameOverLabel {
    SKLabelNode *label =
    [SKLabelNode labelNodeWithFontNamed:fontName_];

    [label setFontSize:36.0];
    [label setFontColor:fontColor_];
    [label setText:@"0"];
    [label setZPosition:5000];
    [label setText:@"Game Over"];
    
    [label setPosition:CGPointMake(self.size.width/2., self.size.height-36.0)];
    [label runAction:
     [SKAction sequence:
  @[[SKAction moveTo:CGPointMake(self.size.width/2., self.size.height/2.)
            duration:0.1],
    [SKAction runBlock:^{
         phase_ = RMMyScenePhaseMedal;
     }]]]];
    
    [self addChild:label];
}


#pragma mark - SKPhysicsContactDelegate methods

/**
 *  Moves to game over phase when the ball contacts with any other objects.
 *
 *  @param contact An object that describes the contact.
 */
- (void)didBeginContact:(SKPhysicsContact *)contact {
    if (phase_ == RMMyScenePhaseGame) {
        [self gameOver];
    }
}

@end
