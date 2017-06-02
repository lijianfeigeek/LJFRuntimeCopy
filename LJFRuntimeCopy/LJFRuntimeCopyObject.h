//
//  LJFRuntimeCopyObject.h
//  LJFRuntimeCopy
//
//  Created by lijianfei on 2017/6/2.
//  Copyright © 2017年 lijianfei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface NSMutableDictionary (Safe)
// 设置Key/Value
- (void)setObjectSafe:(id)anObject forKey:(id < NSCopying >)aKey;
@end

@interface LJFRuntimeCopyBasicObject : NSObject
@end

@interface LJFRuntimeCopyObject : NSObject<NSCopying,NSMutableCopying>

@end
