# Change Log
All notable changes to this project will be documented in this file.
`Navigine.framework` adheres to [Semantic Versioning](http://semver.org/).

## [0.9.1](https://github.com/Navigine/navigine_ios_framework/releases/tag/v.1.0.34) / 2018-04-12

#### Added
* `NCLocationPoint *locationPoint` and `NCGlobalPoint *globalPoint` properties of NCDeviceInfo class
* `NSArray *events` properties of NCRoutePath class

#### Removed
* `float azimuth`, `float latitude`, `float longitude` properties of NCSublocation class
* `NSString *archiveFile` property of NCLocation and NCSublocation classes


## [0.9.0](https://github.com/Navigine/navigine_ios_framework/releases/tag/v.1.0.26) / 2017-12-10

#### Added
* `isValid` function to all public SDK classes
* Static initializers of `NCLocationPoint` and `NCGlobalPoint`
* `Navigine.h` header file
* Center point of `NCZone`

#### Updated
* `NCLocationPoint` and `NCGlobalPoint` all properties are readonly

#### Removed
* `kX`  and `kY` properties from `NCBeacon`, `NCVenue` and `NCLocationPoint` classes
