/*
 * Copyright (c) 2011, The Iconfactory. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of The Iconfactory nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <UIKit/UIImageView-private.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIGraphics.h>
#import <UIKit/UIColor.h>
#import <CoreGraphics/CoreGraphics-private.h>
#import <QuartzCore/QuartzCore-private.h>

static NSArray *CGImagesWithUIImages(NSArray *images)
{
    NSMutableArray *CGImages = [NSMutableArray arrayWithCapacity:[images count]];
    for (UIImage *img in images) {
        [CGImages addObject:(__bridge id)[img CGImage]];
    }
    return CGImages;
}

@implementation UIImageView

@synthesize image=_image;
@synthesize animationImages=_animationImages;
@synthesize animationDuration=_animationDuration;
@synthesize highlightedImage=_highlightedImage;
@synthesize highlighted=_highlighted;
@synthesize animationRepeatCount=_animationRepeatCount;
@synthesize highlightedAnimationImages=_highlightedAnimationImages;

#pragma mark - Life cycle

- (id)initWithFrame:(CGRect)frame
{
    if ((self=[super initWithFrame:frame])) {
        _drawMode = _UIImageViewDrawModeNormal;
        //self.userInteractionEnabled = NO;
        self.opaque = NO;
    }
    return self;
}

- (id)initWithImage:(UIImage *)theImage
{
    CGSize imageSize = theImage.size;
    //DLog(@"imageSize: %@", NSStringFromCGSize(imageSize));
    if ((self = [self initWithFrame:CGRectMake(0,0,imageSize.width,imageSize.height)])) {
        self.image = theImage;
        //_layer.backgroundColor = CGColorCreateGenericRGB(0,0,0,0); // clear color
    }
    return self;
}

- (void)dealloc
{
    [_animationImages release];
    [_image release];
    [_highlightedImage release];
    [_highlightedAnimationImages release];
    [super dealloc];
}

#pragma mark - Accessors

- (CGSize)sizeThatFits:(CGSize)size
{
    return _image.size;
}

- (void)setHighlighted:(BOOL)h
{
    if (h != _highlighted) {
        _highlighted = h;
        [self _updateContent];

        if ([self isAnimating]) {
            [self startAnimating];
        }
    }
}

- (void)setImage:(UIImage *)newImage
{
    if (_image != newImage) {
        //DLog();
        [_image release];
        _image = [newImage retain];
        if (!_highlighted || !_highlightedImage) {
            //DLog();
            [self _updateContent];
        }
    }
}

- (void)_updateContent
{
    //DLog();
    _UIImageViewUpdateContent(self);
    [super _updateContent];
}

- (void)setHighlightedImage:(UIImage *)newImage
{
    if (_highlightedImage != newImage) {
        [_highlightedImage release];
        _highlightedImage = [newImage retain];
        if (_highlighted) {
            [self _updateContent];
        }
    }
}

- (void)setFrame:(CGRect)newFrame
{
    _UIImageViewDisplayIfNeededChangingFromOldSize(self, self.frame.size, newFrame.size);
    [super setFrame:newFrame];
}

- (void)setBounds:(CGRect)newBounds
{
    _UIImageViewDisplayIfNeededChangingFromOldSize(self, self.bounds.size, newBounds.size);
    [super setBounds:newBounds];
}

#pragma mark - Public methods

- (void)startAnimating
{
    NSArray *images = _highlighted? _highlightedAnimationImages : _animationImages;

    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    animation.calculationMode = kCAAnimationDiscrete;
    animation.duration = self.animationDuration ?: ([images count] * (1/30.0));
    animation.repeatCount = self.animationRepeatCount ?: HUGE_VALF;
    animation.values = CGImagesWithUIImages(images);

    [self.layer addAnimation:animation forKey:@"contents"];
}

- (void)stopAnimating
{
    [self.layer removeAnimationForKey:@"contents"];
}

- (BOOL)isAnimating
{
    return ([self.layer animationForKey:@"contents"] != nil);
}

@end

BOOL _UIImageViewHasResizableImage(UIImageView *imageView)
{
    return (imageView->_image.topCapHeight > 0 || imageView->_image.leftCapWidth > 0);
}

void _UIImageViewSetDrawMode(UIImageView *imageView, NSInteger drawMode)
{
    if (!imageView) {
        return;
    }
    if (drawMode != imageView->_drawMode) {
        imageView->_drawMode = drawMode;
        [imageView _updateContent];
    }
}

void _UIImageViewDisplayIfNeededChangingFromOldSize(UIImageView *imageView, CGSize oldSize, CGSize newSize)
{
    if (!CGSizeEqualToSize(newSize,oldSize) && _UIImageViewHasResizableImage(imageView)) {
        [imageView _updateContent];
    }
}

void _UIImageViewUpdateContent(UIImageView *imageView)
{
    //DLog();
    UIImage *contentImage = imageView->_highlighted ? imageView->_highlightedImage : imageView->_image;
    if (contentImage) {
        //DLog();
        CGRect rect = CGRectZero;
        rect.size = contentImage.size;
        CGContextRef ctx = _CGBitmapContextCreateWithOptions(rect.size, true, 1);

        CGContextSaveGState(ctx);
        CGContextTranslateCTM(ctx, 0, rect.size.height);
        CGContextScaleCTM(ctx, 1, -1.0);
        CGContextDrawImage(ctx, rect, contentImage->_image);
        CGContextRestoreGState(ctx);
        
        imageView->_layer.contents = CGBitmapContextCreateImage(ctx);
        [imageView->_layer->_contents release];
        CGContextRelease(ctx);
    } else {
        imageView->_layer.contents = nil;
    }
}

