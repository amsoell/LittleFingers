//
//  NSData+Gzip.h
//  LittleFingers
//
//  Created by Andy Soell on 8/31/12.
//  Copyright (c) 2012 The Institute for Justice. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Gzip)

// gzip compression utilities
- (NSData *)gzipInflate;
- (NSData *)gzipDeflate;

@end
