//
//  ViewController.m
//  CGALViewer
//
//  Created by Paul Agron on 1/13/17.
//  Copyright © 2017 Paul Agron. All rights reserved.
//

#import "ViewController.h"
#import "PointGenerator.hpp"

#import <GLKit/GLKit.h>
#import <SceneKit/ModelIO.h>


@interface IntValueTransformer: NSValueTransformer {}
@end
@implementation IntValueTransformer
+ (Class)transformedValueClass { return [NSString class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(NSNumber*)value {
    
    return (value == nil) ? @"-" : [NSString stringWithFormat:@"%d", [value intValue] ];
}
@end



NSColor* randomColor()
{
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) - 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    NSColor *color = [NSColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    return color;
}


static SCNNode* addVoroCell(adb::VoroCellRepresentation& rep, NSColor* color, NSString* name, bool showCorners,  SCNNode* rootNode)
{
    static SCNMaterial *pointMaterial3 = [SCNMaterial material];
    pointMaterial3.diffuse.contents = [NSColor greenColor];
    pointMaterial3.locksAmbientWithDiffuse = YES;
    pointMaterial3.cullMode = SCNCullModeBack;
    
    static SCNSphere* sphere3 = [SCNSphere sphereWithRadius:0.15];
    sphere3.geodesic = YES;
    sphere3.materials = @[pointMaterial3];
    
    std::vector<SCNVector3> voroV(rep.vertices.size());
    
    
    // copy vertices
    for (int j=0;j<rep.vertices.size();j++) {
        auto& v = rep.vertices[j];
        
        auto vx = CGAL::to_double(v.x());
        auto vy = CGAL::to_double(v.y());
        auto vz = CGAL::to_double(v.z());
        voroV[j] = SCNVector3Make(vx, vy, vz);
    }
  
    // compute the center of mass
    SCNVector3 c = SCNVector3Make(0, 0, 0);
    for (int j=0;j<rep.vertices.size();j++) {
        c.x += voroV[j].x;
        c.y += voroV[j].y;
        c.z += voroV[j].z;
    }
    
    c.x /= rep.vertices.size();
    c.y /= rep.vertices.size();
    c.z /= rep.vertices.size();
    
    // translate everything so center of mass is at origin
    
    for (int j=0;j<rep.vertices.size();j++) {
        voroV[j].x -= c.x;
        voroV[j].y -= c.y;
        voroV[j].z -= c.z;
    }
    
    
    
    
    auto& voroF = rep.triangle_indexes;
    
    // Generate geometry from vertices and faces
    SCNGeometrySource* voroVSource = [SCNGeometrySource geometrySourceWithVertices:voroV.data() count:voroV.size()];
    NSData* voroIndexData = [NSData dataWithBytes:voroF.data() length:sizeof(SCNVector3)*voroF.size()];
    SCNGeometryElement* voroElement = [SCNGeometryElement geometryElementWithData:voroIndexData
                                                                    primitiveType:SCNGeometryPrimitiveTypeTriangles
                                                                   primitiveCount:(voroF.size() / 3)
                                                                    bytesPerIndex:sizeof(unsigned)];
    
    SCNGeometry *voroGeom = [SCNGeometry geometryWithSources:@[voroVSource] elements:@[voroElement]];
    
    
    SCNMaterial *voroMataterial = [SCNMaterial material];
    voroMataterial.diffuse.contents = color;
    voroMataterial.locksAmbientWithDiffuse = YES;
    //voroMataterial.transparent.contents = [NSColor colorWithRed:0 green:0 blue:0 alpha:0.5 ];
    voroMataterial.cullMode = SCNCullModeBack;
    //voroMataterial.doubleSided = YES;
    voroGeom.materials = @[voroMataterial];
    
    // Generate normals per face
    MDLMesh* mesh = [MDLMesh meshWithSCNGeometry:voroGeom];
    [mesh makeVerticesUnique];
    [mesh addNormalsWithAttributeNamed:@"normal" creaseThreshold:1.0]; //(withAttributeNamed: "normal", creaseThreshold: 1.0)
    SCNGeometry* flattenedGeom = [SCNGeometry geometryWithMDLMesh:mesh];
    
    SCNNode* nn = [SCNNode nodeWithGeometry:flattenedGeom];
    //nn.physicsBody = [SCNPhysicsBody ]
    nn.castsShadow = YES;
    
    if (name) {
        nn.name = name;
    }
    
    [rootNode addChildNode:nn];
    
    // corners of cell
    if (showCorners)
        for (auto p : voroV) {
            SCNNode* n = [SCNNode nodeWithGeometry:sphere3];
            n.position = p;
            [rootNode addChildNode:n];
        }
    
    nn.position = c;
    nn.physicsBody = [SCNPhysicsBody dynamicBody];
    
    return nn;
    
}




// A great example of doing similar things to what we are doing here:
//         https://github.com/CGAL/cgal/blob/master/Convex_hull_3/examples/Convex_hull_3/lloyd_algorithm.cpp


static NSString* kSpotLightNodeName = @"spot light";
static NSString* kAxisNodeName = @"axis";
static NSString* kCellNodeName = @"cell";
static NSString* kBoxNodeName = @"box";

@implementation MainController
{
    SCNNode* _spotLightNode;
    SCNNode* _cameraNode;
    SCNNode* _bboxNode;
    NSArray* _axisNodes;
    
    NSMutableArray* _shards;
}

- (SCNNode*) makeAxisOfColor:(NSColor*)color {
	SCNMaterial *solidMataterial = [SCNMaterial material];
	solidMataterial.diffuse.contents = color;
	solidMataterial.locksAmbientWithDiffuse = YES;
	solidMataterial.doubleSided = YES;
	
	SCNCylinder* cylinder = [SCNCylinder cylinderWithRadius:0.5 height:100];
	cylinder.materials = @[solidMataterial];
	
	
	SCNNode* node = [SCNNode nodeWithGeometry:cylinder];
	return node;
}


- (SCNNode*) makeLineOfColor:(NSColor*)color from:(SCNVector3)v to:(SCNVector3)u {
    SCNMaterial *solidMataterial = [SCNMaterial material];
    solidMataterial.diffuse.contents = color;
    solidMataterial.locksAmbientWithDiffuse = YES;
    solidMataterial.doubleSided = YES;
    
    GLKVector3 vv = SCNVector3ToGLKVector3(v);
    GLKVector3 uu = SCNVector3ToGLKVector3(u);
    float height = GLKVector3Distance(vv, uu);
    GLKVector3 r = GLKVector3Subtract(vv, uu);
    r = GLKVector3Normalize(r);
    
    GLKVector3 k = GLKVector3Make(0,1,0);
    GLKVector3 axis = GLKVector3CrossProduct(k,r);
    
    double dotProduct = GLKVector3DotProduct(k,r);

    //SCNMatrix4 initR = SCNMatrix4MakeRotation(M_PI_2, 0, 0, -1);
    

    
    // mr should be replaced by a matrix that orients the vector properly
    SCNMatrix4 mr = SCNMatrix4MakeRotation(acos(dotProduct), axis.x, axis.y, axis.z);

    SCNMatrix4 ta = SCNMatrix4MakeTranslation(0, height / 2, 0);
    SCNMatrix4 tb = SCNMatrix4MakeTranslation(u.x, u.y, u.z);
    
    //SCNMatrix4 tt = SCNMatrix4Mult(SCNMatrix4Mult(SCNMatrix4Mult(ta, initR), mr), tb);
    
    SCNMatrix4 tt = SCNMatrix4Mult(SCNMatrix4Mult(ta, mr), tb);
    //tt = SCNMatrix4Mult(SCNMatrix4Mult(SCNMatrix4Mult(ta, initR), mr), tb);
    
    SCNCylinder* cylinder = [SCNCylinder cylinderWithRadius:0.1 height:height];
    cylinder.materials = @[solidMataterial];
    
    SCNNode* node = [SCNNode nodeWithGeometry:cylinder];
//    node.position = SCNVector3Make(u.x, u.y+height/2, u.z);
//    node.orientation = SCNVector4Make(r.x, r.y, r.z, 0);
    
    node.transform = tt;
    //node.rotation = SCNVector4Make(r.x, r.y, r.z, 0);
    return node;
    
}



- (void)viewDidLoad {
	[super viewDidLoad];
    //[self regenerate];
    
    // trigger stuff
    
    self.showAxes = _showAxes;
    self.showBBox = _showBBox;
    self.castShadow = _castShadow;
    self.zNear = _zNear;
    
    self.pointsToGenerate = @20;
}

-(void)regenerate
{
    _cubeView.scene.paused = YES;
    _shards = [NSMutableArray new];
    
	// An empty scene
	SCNScene *scene = [SCNScene scene];
    scene.paused = YES;
    self.cubeView.scene = scene;
	
	
	_cameraNode = [SCNNode node];
	_cameraNode.camera   = [SCNCamera camera];
    _cameraNode.camera.zNear = 5;
    _cameraNode.camera.zFar = 1000;
    
	_cameraNode.position = SCNVector3Make(0, 12, 30);
	_cameraNode.rotation = SCNVector4Make(1, 0, 0,  -sin(12.0/30.0));
	
	
	[scene.rootNode addChildNode:_cameraNode];
	
	
	// Custom geometry data for a cube
	// --------------------------
	CGFloat cubeSide = 21.0;
	CGFloat halfSide = cubeSide/2.0;
	
	SCNVector3 vertices[] = {
		SCNVector3Make(-halfSide, -halfSide,  halfSide),
		SCNVector3Make( halfSide, -halfSide,  halfSide),
		SCNVector3Make(-halfSide, -halfSide, -halfSide),
		SCNVector3Make( halfSide, -halfSide, -halfSide),
		SCNVector3Make(-halfSide,  halfSide,  halfSide),
		SCNVector3Make( halfSide,  halfSide,  halfSide),
		SCNVector3Make(-halfSide,  halfSide, -halfSide),
		SCNVector3Make( halfSide,  halfSide, -halfSide),
		
		// repeat exactly the same
		SCNVector3Make(-halfSide, -halfSide,  halfSide),
		SCNVector3Make( halfSide, -halfSide,  halfSide),
		SCNVector3Make(-halfSide, -halfSide, -halfSide),
		SCNVector3Make( halfSide, -halfSide, -halfSide),
		SCNVector3Make(-halfSide,  halfSide,  halfSide),
		SCNVector3Make( halfSide,  halfSide,  halfSide),
		SCNVector3Make(-halfSide,  halfSide, -halfSide),
		SCNVector3Make( halfSide,  halfSide, -halfSide),
		
		// repeat exactly the same
		SCNVector3Make(-halfSide, -halfSide,  halfSide),
		SCNVector3Make( halfSide, -halfSide,  halfSide),
		SCNVector3Make(-halfSide, -halfSide, -halfSide),
		SCNVector3Make( halfSide, -halfSide, -halfSide),
		SCNVector3Make(-halfSide,  halfSide,  halfSide),
		SCNVector3Make( halfSide,  halfSide,  halfSide),
		SCNVector3Make(-halfSide,  halfSide, -halfSide),
		SCNVector3Make( halfSide,  halfSide, -halfSide)
	};
	
	SCNVector3 normals[] = {
		// up and down
		SCNVector3Make( 0, -1, 0),
		SCNVector3Make( 0, -1, 0),
		SCNVector3Make( 0, -1, 0),
		SCNVector3Make( 0, -1, 0),
		
		SCNVector3Make( 0, 1, 0),
		SCNVector3Make( 0, 1, 0),
		SCNVector3Make( 0, 1, 0),
		SCNVector3Make( 0, 1, 0),
		
		// back and front
		SCNVector3Make( 0, 0,  1),
		SCNVector3Make( 0, 0,  1),
		SCNVector3Make( 0, 0, -1),
		SCNVector3Make( 0, 0, -1),
		
		SCNVector3Make( 0, 0, 1),
		SCNVector3Make( 0, 0, 1),
		SCNVector3Make( 0, 0, -1),
		SCNVector3Make( 0, 0, -1),
		
		// left and right
		SCNVector3Make(-1, 0, 0),
		SCNVector3Make( 1, 0, 0),
		SCNVector3Make(-1, 0, 0),
		SCNVector3Make( 1, 0, 0),
		
		SCNVector3Make(-1, 0, 0),
		SCNVector3Make( 1, 0, 0),
		SCNVector3Make(-1, 0, 0),
		SCNVector3Make( 1, 0, 0),
	};
	
	CGPoint UVs[] = {
		CGPointMake(0, 0), // bottom
		CGPointMake(1, 0), // bottom
		CGPointMake(0, 1), // bottom
		CGPointMake(1, 1), // bottom
		
		CGPointMake(0, 1), // top
		CGPointMake(1, 1), // top
		CGPointMake(0, 0), // top
		CGPointMake(1, 0), // top
		
		CGPointMake(0, 1), // front
		CGPointMake(1, 1), // front
		CGPointMake(1, 1), // back
		CGPointMake(0, 1), // back
		
		CGPointMake(0, 0), // front
		CGPointMake(1, 0), // front
		CGPointMake(1, 0), // back
		CGPointMake(0, 0), // back
		
		CGPointMake(1, 1), // left
		CGPointMake(0, 1), // right
		CGPointMake(0, 1), // left
		CGPointMake(1, 1), // right
		
		CGPointMake(1, 0), // left
		CGPointMake(0, 0), // right
		CGPointMake(0, 0), // left
		CGPointMake(1, 0), // right
	};
	
	// Indices that turn the source data into triangles and lines
	// ----------------------------------------------------------
	
	int solidIndices[] = {
		// bottom
		0, 2, 1,
		1, 2, 3,
		// back
		10, 14, 11,  // 2, 6, 3,   + 8
		11, 14, 15,  // 3, 6, 7,   + 8
		// left
		16, 20, 18,  // 0, 4, 2,   + 16
		18, 20, 22,  // 2, 4, 6,   + 16
		// right
		17, 19, 21,  // 1, 3, 5,   + 16
		19, 23, 21,  // 3, 7, 5,   + 16
		// front
		8,  9, 12,  // 0, 1, 4,   + 8
		9, 13, 12,  // 1, 5, 4,   + 8
		// top
		4, 5, 6,
		5, 7, 6
	};
	
	int lineIndices[] = {
		// bottom
		0, 1,
		0, 2,
		1, 3,
		2, 3,
		// top
		4, 5,
		4, 6,
		5, 7,
		6, 7,
		// sides
		0, 4,
		1, 5,
		2, 6,
		3, 7,
		// diagonals
		0, 5,
		1, 7,
		2, 4,
		3, 6,
		1, 2,
		4, 7
	};
	
	// Creating the custom geometry object
	// ----------------------------------
	
	// Sources for the vertices, normals, and UVs
	SCNGeometrySource *vertexSource =
	[SCNGeometrySource geometrySourceWithVertices:vertices
											count:24];
	SCNGeometrySource *normalSource =
	[SCNGeometrySource geometrySourceWithNormals:normals
										   count:24];
	
	SCNGeometrySource *uvSource =
	[SCNGeometrySource geometrySourceWithTextureCoordinates:UVs count:24];
	
	
	
	NSData *solidIndexData = [NSData dataWithBytes:solidIndices
											length:sizeof(solidIndices)];
	
	NSData *lineIndexData = [NSData dataWithBytes:lineIndices
										   length:sizeof(lineIndices)];
	
	// Create one element for the triangles and one for the lines
	// using the two different buffers defined above
	SCNGeometryElement *solidElement =
	[SCNGeometryElement geometryElementWithData:solidIndexData
								  primitiveType:SCNGeometryPrimitiveTypeTriangles
								 primitiveCount:12
								  bytesPerIndex:sizeof(int)];
	
	SCNGeometryElement *lineElement =
	[SCNGeometryElement geometryElementWithData:lineIndexData
								  primitiveType:SCNGeometryPrimitiveTypeLine
								 primitiveCount:18
								  bytesPerIndex:sizeof(int)];
	
	
	
	// Create a geometry object from the sources and the two elements
	SCNGeometry *geometry =
	[SCNGeometry geometryWithSources:@[vertexSource, normalSource, uvSource]
							elements:@[solidElement, lineElement]];
	
	
	// Give the cube a light blue colored material for the solid part ...
	NSColor *lightBlueColor = [NSColor colorWithCalibratedRed:  4.0/255.0
														green:120.0/255.0
														 blue:255.0/255.0
														alpha:1.0];
	
	SCNMaterial *solidMataterial = [SCNMaterial material];
	solidMataterial.diffuse.contents = lightBlueColor;
	solidMataterial.locksAmbientWithDiffuse = YES;
	solidMataterial.transparent.contents = [NSColor colorWithRed:0 green:0 blue:0 alpha:0.5 ];
	solidMataterial.cullMode = SCNCullModeBack;
	//solidMataterial.doubleSided = YES;
	

	// ... and a white constant material for the lines
	SCNMaterial *lineMaterial = [SCNMaterial material];
	lineMaterial.diffuse.contents  = [NSColor blackColor];
	lineMaterial.lightingModelName = SCNLightingModelConstant;
	lineMaterial.cullMode=SCNCullModeBack;
	
	geometry.materials = @[solidMataterial, lineMaterial];
	
	
	// Attach the cube (solid + lines) to a node and add it to the scene
    _bboxNode = [SCNNode nodeWithGeometry:geometry];
    _bboxNode.name = kBoxNodeName;
	//cubeNode.opacity = 0.5;
    
    // Create a floor
    SCNNode* floorNode = [SCNNode node];
    SCNFloor* floor = [SCNFloor floor];
    
    floorNode.geometry = floor;
    floorNode.physicsBody = [SCNPhysicsBody staticBody];
    

    
    floor.firstMaterial.diffuse.contents = @"wood.png";
    floor.firstMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(2, 2, 1); //scale the wood texture
    floor.firstMaterial.locksAmbientWithDiffuse = YES;
    
    floor.reflectivity = 0.5;
    floor.reflectionFalloffEnd = 10;
    floorNode.position = SCNVector3Make(0, -21.0, 0);
    
    
    // Create a spotlight
    _spotLightNode = [SCNNode node];
    _spotLightNode.light = [SCNLight light];
    _spotLightNode.light.castsShadow = YES;
    _spotLightNode.light.type = SCNLightTypeSpot;
//    omniLightNode.light.color = UIColor(white: 0.75, alpha: 1.0)
    _spotLightNode.position = SCNVector3Make(0, 80, 20);
    _spotLightNode.rotation = SCNVector4Make(1, 0, 0, -0.9*M_PI_2);  // by default light's direction is down the negative Z
    
    
    SCNNode* omniLightNode = [SCNNode node];
    omniLightNode.light = [SCNLight light];
    omniLightNode.light.castsShadow = NO;
    omniLightNode.light.type = SCNLightTypeOmni;
    //    omniLightNode.light.color = UIColor(white: 0.75, alpha: 1.0)
    omniLightNode.position = SCNVector3Make(0, 250, 0);
    omniLightNode.rotation = SCNVector4Make(1, 0, 0, M_PI_2);  // by default light's direction is down the negative Z
    omniLightNode.light.intensity = 200;  // out of 1000 - full intensity
    
    SCNNode* ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.castsShadow = NO;
    ambientLightNode.light.type = SCNLightTypeAmbient;
    //    ambientLightNode.light.color = UIColor(white: 0.75, alpha: 1.0)
    ambientLightNode.position = SCNVector3Make(0, 250, 0);
    ambientLightNode.rotation = SCNVector4Make(1, 0, 0, M_PI_2);  // by default light's direction is down the negative Z
    ambientLightNode.light.intensity = 50;  // out of 1000 - full intensity
    

    _spotLightNode.name = kSpotLightNodeName;
    
	
	
	
	SCNNode* xAxis = [self makeAxisOfColor:[NSColor orangeColor]];
	SCNNode* yAxis = [self makeAxisOfColor:[NSColor redColor]];
	SCNNode* zAxis = [self makeAxisOfColor:[NSColor yellowColor]];
    
    _axisNodes = @[xAxis, yAxis, zAxis];
    xAxis.name = kAxisNodeName;
    yAxis.name = kAxisNodeName;
    zAxis.name = kAxisNodeName;
    
	zAxis.rotation = SCNVector4Make(1, 0, 0, M_PI_2);
	xAxis.rotation = SCNVector4Make(0, 0,-1, M_PI_2);
    
    
    scene.physicsWorld.speed = 0.7;

	[scene.rootNode addChildNode:_bboxNode];
	//[scene.rootNode addChildNode:sphereNode];
	[scene.rootNode addChildNode:yAxis];
	[scene.rootNode addChildNode:zAxis];
	[scene.rootNode addChildNode:xAxis];
    [scene.rootNode addChildNode:floorNode];
    [scene.rootNode addChildNode:_spotLightNode];
    [scene.rootNode addChildNode:omniLightNode];
    [scene.rootNode addChildNode:ambientLightNode];
    
    ////
    
    SCNMaterial *pointMaterial = [SCNMaterial material];
    pointMaterial.diffuse.contents = [NSColor redColor];
    pointMaterial.locksAmbientWithDiffuse = YES;
    pointMaterial.cullMode = SCNCullModeBack;
    
    SCNMaterial *pointMaterial2 = [SCNMaterial material];
    pointMaterial2.diffuse.contents = [NSColor yellowColor];
    pointMaterial2.locksAmbientWithDiffuse = YES;
    pointMaterial2.cullMode = SCNCullModeBack;
    
    SCNMaterial *pointMaterial3 = [SCNMaterial material];
    pointMaterial3.diffuse.contents = [NSColor greenColor];
    pointMaterial3.locksAmbientWithDiffuse = YES;
    pointMaterial3.cullMode = SCNCullModeBack;
    
    SCNSphere* sphere3 = [SCNSphere sphereWithRadius:0.15];
    sphere3.geodesic = YES;
    sphere3.materials = @[pointMaterial3];


    
    using namespace adb;
    using namespace std;
    
    PointGenerator pgen(self.pointsToGenerate.unsignedIntegerValue);
    
    SCNSphere* sphere = [SCNSphere sphereWithRadius:0.15];
    sphere.geodesic = YES;
    sphere.materials = @[pointMaterial];
    
    

#if 0
    auto points = pgen.points();
    for (auto i=points.begin(); i!=points.end(); i++) {
        auto p=*i;
               SCNNode* n = [SCNNode nodeWithGeometry:sphere];
        
        auto vx = CGAL::to_double(p.x());
        auto vy = CGAL::to_double(p.y());
        auto vz = CGAL::to_double(p.z());

        n.position = SCNVector3Make(vx, vy, vz);
        [scene.rootNode addChildNode:n];
    }
#endif
    
    
#if 0
    SCNSphere* bigSphere = [SCNSphere sphereWithRadius:0.3];
    bigSphere.geodesic = YES;
    bigSphere.materials = @[pointMaterial2];
    
    
    auto innerPoints = pgen.innerVertices();
    for (auto i : innerPoints) {
        auto p=i->point();
        SCNNode* n = [SCNNode nodeWithGeometry:bigSphere];
        auto vx = CGAL::to_double(p.x());
        auto vy = CGAL::to_double(p.y());
        auto vz = CGAL::to_double(p.z());
        
        n.position = SCNVector3Make(vx, vy, vz);
        [scene.rootNode addChildNode:n];
    }
#endif
    
    
#if 0
    auto edges = pgen.triangulationEdges();
    
    for (auto e : edges) {
        auto p = e.first;
        auto q = e.second;
        SCNVector3 pp = SCNVector3Make(p.x(), p.y(), p.z());
        SCNVector3 qq = SCNVector3Make(q.x(), q.y(), q.z());
        
        SCNNode* edgeRep = [self makeLineOfColor:randomColor() from:pp to:qq];
        [scene.rootNode addChildNode:edgeRep];
    }
#endif
    
    list<Polyhedron_3> vcells = pgen.generateVoroCells();
    
    int counter = 0;
    for (auto& p : vcells) {
        VoroCellRepresentation rep;
        pgen.processVoroCell(p, rep);
        
        //NSColor* clr = randomColor();
        NSColor* clr = [NSColor orangeColor];
        SCNNode* n = addVoroCell(rep, clr , [NSString stringWithFormat:@"%@%d", kCellNodeName, counter], false, scene.rootNode);
        [_shards addObject:n];
        counter++;
    }
    
    
    
    
//    scene.paused = NO;

}




- (void)setRepresentedObject:(id)representedObject {
	[super setRepresentedObject:representedObject];

	// Update the view, if already loaded.
}



-(void) setShowBBox:(BOOL)showBBox {
    _showBBox = showBBox;
    _bboxNode.hidden = !showBBox;
}

-(void) setShowAxes:(BOOL)showAxes {
    _showAxes = showAxes;
    for (SCNNode* n in _axisNodes) {
        n.hidden = !showAxes;
    }
}

-(void) setCastShadow:(BOOL)castShadow {
    _castShadow = castShadow;
    _spotLightNode.light.castsShadow = castShadow;
    [self.cubeView setNeedsDisplay:YES];
}

-(void) setZNear:(NSNumber *)zNear {
    _zNear = zNear;
    //_cameraNode.camera.zNear = [zNear doubleValue];
    _cubeView.pointOfView.camera.zNear = [zNear doubleValue];
    //self.cubeView.sceneTime += 1;
    [self.cubeView setNeedsDisplay:YES];
}



-(IBAction)animateSimple:(id)sender {
    _cubeView.scene.paused = NO;
    return;
    for (SCNNode* n in _shards) {
        double d = 1.0; //drand48() * 3;
        SCNVector3 p = n.position;
        SCNAction* action = [SCNAction moveBy:SCNVector3Make(d * p.x , d*p.y, d*p.z) duration:3.0];
        [n runAction:action];
    }
}


-(IBAction)animateQuadraticXBiased:(id)sender {
    for (SCNNode* n in _shards) {
        double d = 1.0; //drand48() * 3;
        SCNVector3 p = n.position;
        
        double m1 = d * p.x * fabs(p.x);
        
        
        SCNAction* action = [SCNAction moveBy:SCNVector3Make(m1 , d*p.y, d*p.z) duration:3.0];
        [n runAction:action];
    }
}

-(IBAction)animateQuadraticUnbiased:(id)sender {
    for (SCNNode* n in _shards) {
        double d = 1.0; //drand48() * 3;
        SCNVector3 p = n.position;
        
        double m1 = d * p.x * fabs(p.x);
        double m2 = d * p.y * fabs(p.y);
        double m3 = d * p.z * fabs(p.z);
        
        SCNAction* action = [SCNAction moveBy:SCNVector3Make(m1 , m2, m3) duration:3.0];
        [n runAction:action];
    }
}

-(IBAction)regenerateScene:(id)sender {
    [self regenerate];
    
    // trigger bindings;
    self.showBBox = _showBBox;
    self.showAxes = _showAxes;
    self.castShadow = _castShadow;
    self.zNear = _zNear;
}


// Flow from firstResponder
-(IBAction)saveDocument:(id)sender
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setAllowedFileTypes:@[@"scn"]];
    panel.allowsOtherFileTypes = NO;
    [panel beginWithCompletionHandler:^(NSInteger result) {
        //OK button pushed
        if (result == NSFileHandlingPanelOKButton) {
            [panel orderOut:self];
            NSURL* url = [panel URL];
            
            [_cubeView.scene writeToURL:url options:nil delegate:nil progressHandler:^(float totalProgress, NSError * _Nullable error, BOOL * _Nonnull stop) {
                NSLog(@"%f", totalProgress);
            }];
        }
        
        //[NSApp replyToApplicationShouldTerminate:YES];
    }];
    
}

-(IBAction)openDocument:(id)sender {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    panel.allowedFileTypes = @[@"scn"];
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [panel orderOut:self];
            // Do what you need to do with the selected path
            NSError* err = nil;
            NSURL* url = [panel URL];
            SCNScene* scene = [SCNScene sceneWithURL:url options:nil error:&err];
            _cubeView.scene = scene;
            
            _shards = [[scene.rootNode childNodesPassingTest:^BOOL(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
                return [child.name hasPrefix:kCellNodeName];
            }] mutableCopy];
            
            _spotLightNode = [scene.rootNode childNodeWithName:kSpotLightNodeName recursively:NO];
            _bboxNode = [scene.rootNode childNodeWithName:kBoxNodeName recursively:NO];
            _axisNodes = [scene.rootNode childNodesPassingTest:^BOOL(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
                return [child.name hasPrefix:kAxisNodeName];
            }];
        }
        
    }];

}

-(IBAction)saveDocumentAs:(id)sender {
    NSLog(@"SaveAs");
}




@end
