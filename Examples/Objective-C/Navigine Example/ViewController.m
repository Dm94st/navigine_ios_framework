//
//  ViewController.m
//  Navigine Example
//
//  Created by Dmitry Stavitsky on 01/07/2018.
//  Copyright © 2018 Navigine. All rights reserved.
//

#import "ViewController.h"

static NSString *const userHash = @"2623-C33C-4C13-9258"; // Your user hash
static NSString *const serverName =  @"https://api.navigine.com";
static int const locationId = 2872;

@implementation ViewController

- (void) viewDidLoad {
  [super viewDidLoad];
  _floor = 0;
  _isRouting = NO;
  _scrollView.delegate = self;
  _scrollView.pinchGestureRecognizer.enabled = YES;
  _scrollView.minimumZoomScale = 1.;
  _scrollView.maximumZoomScale = 2.;
  _scrollView.zoomScale = 1.;
  
  // Create gesture regignizers for long tap and single tap
  UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapOnMap:)];
  UILongPressGestureRecognizer *longTapGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longTapOnMap:)];
  [_scrollView addGestureRecognizer:singleTapGesture];
  [_scrollView addGestureRecognizer:longTapGesture];
  
  // Add navigation bar
  _eventView = [[RouteEventView alloc] initWithFrame:CGRectMake(0.,
                                                                self.view.statusBarFrame.size.height,
                                                                self.view.screenFrame.size.width,
                                                                80.)];
  [self.view addSubview:_eventView];
  [_eventView.cancelBtn addTarget:self action:@selector(stopRoute) forControlEvents:UIControlEventTouchUpInside];
  
  // Error view
  const float xPos = 0;
  const float yPos = self.view.screenFrame.size.height - self.view.screenFrame.size.height / 8.;
  const float width = self.view.screenFrame.size.width;
  const float height = self.view.screenFrame.size.height / 8.;
  _errorView = [[ErrorView alloc] initWithFrame:CGRectMake(xPos, yPos, width, height)];
  [self.view addSubview: _errorView];
  
  // Add current position on map
  _curPosition = [[CurrentLocation alloc] init];
  [_imageView addSubview: _curPosition];
  [self.view bringSubviewToFront:_btnStackFloor];
  
  // Add loading progress bar while map is downloading
  MBProgressHUD *spinnerActivity = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  spinnerActivity.mode = MBProgressHUDModeDeterminateHorizontalBar;
  spinnerActivity.label.text = @"Loading";
  spinnerActivity.detailsLabel.text = @"Please Wait!";
  spinnerActivity.userInteractionEnabled = false;
  
  // Initialize navigation core
  _navigineCore = [[NavigineCore alloc] initWithUserHash:userHash server:serverName];
  _navigineCore.delegate = self;
  _navigineCore.navigationDelegate = self;
  
  // Add beacon generators if needed
  [_navigineCore addBeaconGenerator: @"F7826DA6-4FA2-4E98-8024-BC5B71E0893E" major: 65463 minor:38214 timeout:50 rssiMin:-100 rssiMax:-70];
  //[_navigineCore addBeaconGenerator: @"F7826DA6-4FA2-4E98-8024-BC5B71E0893E" major: 63714 minor:8737 timeout:50 rssiMin:-100 rssiMax:-x70];
  //[_navigineCore addBeaconGenerator: @"8EEB497E-4928-44C6-9D92-087521A3547C" major: 9001  minor:36 timeout:10 rssiMin:-90 rssiMax:-70];
  [_navigineCore downloadLocationById: locationId
                          forceReload: true
                         processBlock: ^(NSInteger loadProcess) {
                           NSLog(@"%ld", (long)loadProcess);
                           spinnerActivity.progress = loadProcess;
                         }
                         successBlock: ^(NSDictionary *userInfo) {
                           [self.navigineCore startNavigine];
                           [self.navigineCore startPushManager];
                           [self setupFloor: self.floor];
                           [spinnerActivity hideAnimated:YES];
                           self.imageView.userInteractionEnabled = YES;
                         }
                            failBlock: ^(NSError *error) {
                              NSLog(@"%@", error);
                            }];
}

- (void) setupFloor:(NSInteger) floor {
  [_imageView removeFromSuperview];
  [self removeVenuesFromMap]; // Remove venues from map
  [self removeZonesFromMap];  // Remove zones from map
  _scrollView.zoomScale = 1.; // Reset zoom
  _location = _navigineCore.location;
  _sublocation = _navigineCore.location.sublocations[floor];
  _imageView.image = [UIImage imageWithData: _sublocation.pngImage];
  [_scrollView addSubview:_imageView];
  _btnStackFloor.hidden = _location.sublocations.count == 1; // Hide buttons if count of sublocations = 0
  _lblCurrentFloor.text = [NSString stringWithFormat:@"%d", _floor];
  const CGSize imgSize = _imageView.image.size;
  const CGSize viewSize = self.view.frame.size;
  float scale = 1.f;
  if ((imgSize.width / imgSize.height) > (viewSize.width / viewSize.height))
    scale = viewSize.height / imgSize.height;
  else
    scale = imgSize.width / imgSize.width;
  _scrollView.contentSize = CGSizeMake(imgSize.width * scale, imgSize.height * scale);
  // Add constraints
  _imageViewWidthConstraint.constant = imgSize.width * scale;
  _imageViewHeightConstraint.constant = imgSize.height * scale;
  _imageViewTopConstraint.constant = 0;
  _imageViewLeadingConstraint.constant = 0;
  [self.view layoutIfNeeded];
  [self drawZones];
  [self drawVenues];
}

#pragma mark Handlers

- (IBAction) btnIncreaseFloorPressed:(id)sender {
  NSUInteger sublocCnt = _location.sublocations.count - 1;
  if (_floor == sublocCnt)
    return;
  else
    [self setupFloor: ++_floor];
  }

- (IBAction) btnDecreaseFloorPressed:(id)sender {
  if (_floor == 0)
    return;
  else
    [self setupFloor: --_floor];
}

- (void) mapPinTap:(MapPin*)pinBtn {
  if(pinBtn.isSelected)
    pinBtn.selected = NO;
  else {
    _pressedPin.popUp.hidden = YES; // Hide last selected pin
    _pressedPin = pinBtn;
    pinBtn.popUp.hidden = NO; // Show currently selected pin
    pinBtn.popUp.centerX = pinBtn.centerX;
    pinBtn.selected = YES;
    [pinBtn resizeMapPinWithZoom: _scrollView.zoomScale];
    [_imageView addSubview: pinBtn.popUp];
  }
}

// Hide selected pin by tap anywhere
- (void) singleTapOnMap:(UITapGestureRecognizer *)gesture {
  if(_pressedPin.isSelected)
    _pressedPin.popUp.hidden = YES;
  else
    return;
}

// Draw route by long tap
- (void) longTapOnMap:(UITapGestureRecognizer *)gesture {
  if (gesture.state != UIGestureRecognizerStateBegan) return;
  
  [[_imageView viewWithTag:1] removeFromSuperview]; // Remove destination pin from map
  CGPoint touchPtInPx = [gesture locationOfTouch:0 inView: _scrollView]; // Touch point in pixels
  CGPoint touchPtInM = [self convertPixelsToMeters:touchPtInPx.x: touchPtInPx.y withScale:1]; // Touch point in meters
  NCLocationPoint *targetPt = [NCLocationPoint pointWithLocation: _location.id
                                                     sublocation: _sublocation.id
                                                               x: @(touchPtInM.x)
                                                               y: @(touchPtInM.y)];
  [_navigineCore cancelTargets];
  [_navigineCore setTarget:targetPt];
  // Create destination pin on map
  UIImage *imgMarker = [UIImage imageNamed:@"elmMapPin"];
  UIImageView *destinationMarker = [[UIImageView alloc] initWithImage:imgMarker];
  destinationMarker.tag = 1;
  destinationMarker.transform = CGAffineTransformMakeScale(1. / _scrollView.zoomScale,
                                                           1. / _scrollView.zoomScale);
  destinationMarker.centerX = touchPtInPx.x / _scrollView.zoomScale;
  destinationMarker.centerY = (touchPtInPx.y - imgMarker.size.height / 2.) / _scrollView.zoomScale;
  destinationMarker.layer.zPosition = 5.;
  [_imageView addSubview:destinationMarker];
  _isRouting = YES;
}

#pragma mark Helper functions

// Convert from pixels to meters
- (CGPoint) convertPixelsToMeters:(float)srcX :(float)srcY withScale :(float)scale {
  const CGFloat dstX = srcX / (_imageView.width / scale) * _sublocation.width;
  const CGFloat dstY = (1. - srcY / (_imageView.height / scale)) * _sublocation.height;
  return CGPointMake(dstX, dstY);
}

// Convert from meters to pixels
- (CGPoint) convertMetersToPixels:(float)srcX :(float)srcY withScale :(float)scale {
  const CGFloat dstX = (_imageView.width / scale) * srcX / _sublocation.width;
  const CGFloat dstY = (_imageView.height / scale) * (1. - srcY / _sublocation.height);
  return CGPointMake(dstX, dstY);
}

- (void) drawRouteWithPath: (NSArray *)path andDistance: (float)distance {
  if (distance <= 3.) { // Check that we are close to the finish point of the route
    [self stopRoute];
  }
  else {
    [_routeLayer removeFromSuperlayer];
    [_routePath removeAllPoints];
    _routeLayer = [CAShapeLayer layer];
    _routePath = [[UIBezierPath alloc] init];
    for (NCLocationPoint *point in path) {
      if (point.sublocation != _sublocation.id) // If path between different sublocations
        continue;
      else {
        CGPoint cgPoint = [self convertMetersToPixels:point.x.floatValue:point.y.floatValue withScale:_scrollView.zoomScale];
        if (_routePath.empty)
          [_routePath moveToPoint:cgPoint];
        else
          [_routePath addLineToPoint:cgPoint];
      }
    }
  }
  _routeLayer.hidden = NO;
  _routeLayer.path = _routePath.CGPath;
  _routeLayer.strokeColor = kColorFromHex(0x4AADD4).CGColor;
  _routeLayer.lineWidth = 2.0;
  _routeLayer.lineJoin = kCALineJoinRound;
  _routeLayer.fillColor = UIColor.clearColor.CGColor;
  
  [_imageView.layer addSublayer: _routeLayer]; // Add route layer on map
  [_imageView bringSubviewToFront: _curPosition];
}

- (void) stopRoute {
  [[_imageView viewWithTag:1] removeFromSuperview]; // Remove current pin from map
  [_routeLayer removeFromSuperlayer];
  [_routePath removeAllPoints];
  [_navigineCore cancelTargets];
  _isRouting = NO;
  _eventView.hidden = YES;
}

- (void) drawVenues {
  for (NCVenue *curVenue in _sublocation.venues) {
    MapPin *mapPin = [[MapPin alloc] initWithVenue:curVenue];
    const CGFloat xPt = curVenue.x.floatValue;
    const CGFloat yPt = curVenue.y.floatValue;
    CGPoint venCentre = [self convertMetersToPixels:xPt :yPt withScale: 1];
    [mapPin addTarget:self action:@selector(mapPinTap:) forControlEvents:UIControlEventTouchUpInside];
    [mapPin sizeToFit];
    mapPin.center = venCentre;
    [_imageView addSubview:mapPin];
    [_scrollView bringSubviewToFront:mapPin];
  }
}

- (void) drawZones {
  for (NCZone *zone in _sublocation.zones) {
    UIBezierPath *zonePath  = [[UIBezierPath alloc] init];
    CAShapeLayer *zoneLayer = [CAShapeLayer layer];
    CGPoint firstPoint = CGPointMake(0, 0);
    for(NCLocationPoint *point in zone.points) {
      const float xPt = point.x.floatValue;
      const float yPt = point.y.floatValue;
      CGPoint cgCurPoint = [self convertMetersToPixels:xPt :yPt withScale:1];
      if(zonePath.empty) {
        firstPoint = cgCurPoint;
        [zonePath moveToPoint:cgCurPoint];
      }
      else {
        [zonePath addLineToPoint:cgCurPoint];
      }
    }
    [zonePath addLineToPoint:firstPoint]; // Add first point again to close path
    uint hexColor = [self stringToHex: zone.color]; // Parse zone color
    zoneLayer.name            = @"Zone";
    zoneLayer.path            = [zonePath CGPath];
    zoneLayer.strokeColor     = [kColorFromHex(hexColor) CGColor];
    zoneLayer.lineWidth       = 2.;
    zoneLayer.lineJoin        = kCALineJoinRound;
    zoneLayer.fillColor       = [[kColorFromHex(hexColor) colorWithAlphaComponent: .5] CGColor];
    [_imageView.layer addSublayer:zoneLayer];
  }
}

- (void) removeVenuesFromMap {
  for (UIView *obj in _imageView.subviews) {
    if ([obj isKindOfClass:[MapPin class]]) {
      const MapPin *pin = ((MapPin *)obj);
      [pin removeFromSuperview];
      [pin.popUp removeFromSuperview];
    }
  }
}

- (void) removeZonesFromMap {
  for (CALayer *layer in _imageView.layer.sublayers.copy) {
    if ([[layer name] isEqualToString:@"Zone"]) {
      [layer removeFromSuperlayer];
    }
  }
}

- (uint) stringToHex: (NSString *) srcStr {
  uint hexStr = 0;
  NSScanner *strScanner = [NSScanner scannerWithString: srcStr];
  [strScanner setScanLocation: 1];
  [strScanner scanHexInt: &hexStr];
  return hexStr;
}

# pragma mark NavigineCoreDelegate methods

- (void) navigineCore: (NavigineCore *)navigineCore didUpdateDeviceInfo: (NCDeviceInfo *)deviceInfo {
  NSError *navError = deviceInfo.error;
  //NSError *customError = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:4 userInfo:navError.userInfo];
  if (navError.code == 0) {
    _errorView.hidden = YES;
    _curPosition.hidden = deviceInfo.sublocation != _sublocation.id; // Hide current position pin
    if(!_curPosition.hidden) {
      const float radScale = _imageView.width / _sublocation.width;
      _curPosition.center = [self convertMetersToPixels: deviceInfo.x: deviceInfo.y withScale: _scrollView.zoomScale];
      _curPosition.radius = deviceInfo.r * radScale;
    }
  }
  else {
    _curPosition.hidden = YES;
    _errorView.error = navError;
    _errorView.hidden = NO;
  }
  if (_isRouting) {
    NCRoutePath *devicePath = deviceInfo.paths.firstObject;
    if (devicePath) {
      NCLocalPoint *lastPoint = devicePath.points.lastObject;
      [_imageView viewWithTag:1].hidden = lastPoint.sublocation != _sublocation.id; // Hide destination pin
      _eventView.hidden = deviceInfo.sublocation != _sublocation.id; // Hide event bar
      NSArray *path = devicePath.points;
      NSArray *eventsArr = devicePath.events;
      float distance = devicePath.lenght;
      if(distance < 1)
        [_eventView setFinishTitle];
      else
        _eventView.event = eventsArr.firstObject;
      [self drawRouteWithPath:path andDistance:distance];
    }
  }
}

#pragma mark UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
  return _imageView;
}

- (void) scrollViewDidZoom:(UIScrollView *)scrollView {
  const float currentZoom = _scrollView.zoomScale;
  if(currentZoom < _scrollView.minimumZoomScale || currentZoom > _scrollView.maximumZoomScale)
    return;
  else {
    // Stay pins at same sizes while zooming
    for (UIView *obj in self.imageView.subviews) {
      if ([obj isKindOfClass:[MapPin class]]) {
        const MapPin *pin = ((MapPin *)obj);
        [pin resizeMapPinWithZoom:currentZoom];
      }
    }
    [_curPosition resizeLocationPinWithZoom:currentZoom]; // Stay current position pin at same sizes while zooming
    // Stay destination marker pin at same sizes while zooming
    UIImageView *destMarker = [_imageView viewWithTag: 1];
    destMarker.transform = CGAffineTransformMakeScale(1. / currentZoom, 1. / currentZoom);
    destMarker.centerX = _routePath.currentPoint.x;
    destMarker.centerY = _routePath.currentPoint.y - (destMarker.image.size.height / 2) / currentZoom;
  }
  // Another way to resize pins accordingly zoom
  /* CGAffineTransform transform = _imageView.transform; // Get current matrix
   CGAffineTransform invertedTransform = CGAffineTransformInvert(transform); // Inverse matrix
   _pressedPin.transform = invertedTransform; // Apply transformation to button
   _pressedPin.popUp.transform = invertedTransform; // Apply transformation to popup */
}

#pragma mark NavigineCoreDelegate methods
- (void) didRangePushWithTitle:(NSString *)title
                       content:(NSString *)content
                         image:(NSString *)image
                            id:(NSInteger)id {
  // Your code
}
@end
