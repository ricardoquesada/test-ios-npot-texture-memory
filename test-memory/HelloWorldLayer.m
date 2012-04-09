//
//  HelloWorldLayer.m
//  test-memory
//
//  Created by Ricardo Quesada on 4/4/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

#pragma mark - HelloWorldLayer

// HelloWorldLayer implementation
@implementation HelloWorldLayer

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super's" return value
	if( (self=[super init])) {

		CGSize s = [[CCDirector sharedDirector] winSize];
	
//		CCSprite *sprite = [CCSprite spriteWithFile:@"texture2048x2048_rgba8888.pvr"];
//		CCSprite *sprite = [CCSprite spriteWithFile:@"texture2048x2048_rgba4444.pvr"];
//		CCSprite *sprite = [CCSprite spriteWithFile:@"texture2048x2048_rgb888.pvr"];
//		CCSprite *sprite = [CCSprite spriteWithFile:@"texture2047x2047_rgba8888.pvr"];
//		CCSprite *sprite = [CCSprite spriteWithFile:@"texture1536x1536_rgba8888.png"];
//		CCSprite *sprite = [CCSprite spriteWithFile:@"texture1025x1025_rgba8888.png"];
		CCSprite *sprite = [CCSprite spriteWithFile:@"texture2047x2047_rgba8888.png"];

		[sprite setPosition:ccp( s.width/2, s.height/2)];
		[sprite setScale:0.25f];
		
		[self addChild:sprite z:0 tag:1];
		
		[self scheduleOnce:@selector(removeSprite:) delay:10];

	}
	return self;
}

-(void) removeSprite:(id)sender
{
	[self removeChildByTag:1 cleanup:YES];
	[[CCTextureCache sharedTextureCache] removeUnusedTextures];
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
