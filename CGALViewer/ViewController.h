//
//  ViewController.h
//  CGALViewer
//
//  Created by Paul Agron on 1/13/17.
//  Copyright © 2017 Paul Agron. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SceneKit/SceneKit.h>

@interface MainController : NSViewController
@property (weak)   IBOutlet SCNView  *cubeView;
@property NSNumber* pointsToGenerate;


@property (nonatomic) BOOL showBBox;
@property (nonatomic) BOOL showAxes;
@property (nonatomic) BOOL castShadow;
@property (nonatomic) NSNumber* zNear;
@end

