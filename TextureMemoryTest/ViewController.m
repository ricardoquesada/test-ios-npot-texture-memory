//
//  ViewController.m
//  TextureMemoryTest
//
//  Created by Ricardo Quesada on 4/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_POSITION,
    ATTRIB_TEXCOORDS,
    NUM_ATTRIBUTES
};

@interface ViewController () {
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix;
	
	GLKTextureInfo *_textureInfo;

    float _rotation;    
}
@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation ViewController

@synthesize context = _context;

- (void)dealloc
{
    [_context release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2] autorelease];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
}

- (void)viewDidUnload
{    
    [super viewDidUnload];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc. that aren't in use.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
        
	[_textureInfo release];
	_textureInfo = nil;
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
//    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
//    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
	GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, self.view.bounds.size.width, 0, self.view.bounds.size.height, -1024, 1024 );
        
//    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
//    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
	GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeScale(0.5f, 0.5f, 1);
    
    // Compute the model view matrix for the object rendered with GLKit
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    // Compute the model view matrix for the object rendered with ES2
    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
//    _rotation += self.timeSinceLastUpdate * 0.5f;
			
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
	static float accum = 0;
	static BOOL loaded = NO;
	
	accum += self.timeSinceLastDraw;
	
	if( accum > 5 && ! loaded ) {
//		glPixelStorei(GL_UNPACK_ALIGNMENT,1);
		
		NSError *error = nil;

		// NPOT 16-BIT
		// It allocates 2 Mb initially (OK), but at draw time it allocates 2 more MBs (BUG) (all NPOT 16-bit textures have this bug)
//		NSString *path = [[NSBundle mainBundle] pathForResource:@"test_1023x1023_rgba4444.pvr" ofType:nil];

		// NPOT 32-BIT
		// It allocates 4 Mb initially (OK), and 0 additional Mb at draw time (OK)   (32-bit textures don't have this bug)
//		NSString *path = [[NSBundle mainBundle] pathForResource:@"test_1023x1023_rgba8888.pvr" ofType:nil];

		// NPOT 24-BIT (RGB888)
		// It allocates 3 Mb initially (OK... it seems it was not expanded yet to RGBx), and 4 additional Mb at draw time (BUG #2)   (NPOT RGB888 24-bit textures alloc 133% more!)
		NSString *path = [[NSBundle mainBundle] pathForResource:@"test_1023x1023_rgb888.pvr" ofType:nil];

		// POT 24-BIT (RGB888)
		// It allocates 4 Mb (expanded to RGBx) + 33% (mipmap alloc bug) initially (sort of OK), and 0 additional Mb at draw time (OK)   (valid for all POT textures)
//		NSString *path = [[NSBundle mainBundle] pathForResource:@"test_1024x1024_rgb888.pvr" ofType:nil];

		_textureInfo = [GLKTextureLoader textureWithContentsOfFile:path options:nil error:&error];
		
		[_textureInfo retain];
		
		NSLog(@"Error: %@", error);
		NSLog(@"texture id: %d", _textureInfo.name );
		
//		glBindTexture(GL_TEXTURE_2D, _textureInfo.name);
//		
//		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
//		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
//		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
//		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
//		
//		glBindTexture(GL_TEXTURE_2D, 0);
		
		loaded = YES;
	}
	
	if( accum < 5 )
		glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
	else
		glClearColor(0.65f, 0, 0, 1.0f);

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	if( accum < 10 )
		return;

    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, GL_FALSE, _modelViewProjectionMatrix.m);	
	
	GLfloat		coordinates[] = {
		0,	1,
        1,	1,
        0,	0,
        1,	0,
	};
	GLfloat	width = _textureInfo.width;
	GLfloat height = _textureInfo.height;
	
	GLfloat		vertices[] = {
		0,		0,
        width,	0,
		0,		height,
		width,	height
	};
	
	glBindTexture( GL_TEXTURE_2D, _textureInfo.name );
	
	glEnableVertexAttribArray( 0 );
	glEnableVertexAttribArray( 1 );
	
	glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, vertices);
	glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 0, coordinates);

	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, ATTRIB_POSITION, "a_position");
    glBindAttribLocation(_program, ATTRIB_TEXCOORDS, "a_texCoord");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "u_MVPMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end
