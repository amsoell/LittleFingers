//
//  SPDeepCopy.h
//
//  Created by Sherm Pendley on 3/15/09.
//

#import <Foundation/Foundation.h>
// Deep -copy and -mutableCopy methods for NSArray and NSDictionary

@interface NSDictionary (SPDeepCopy)

- (NSDictionary*) deepCopy;
- (NSMutableDictionary*) mutableDeepCopy;

@end