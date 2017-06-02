//
//  LJFRuntimeCopyObject.m
//  LJFRuntimeCopy
//
//  Created by lijianfei on 2017/6/2.
//  Copyright © 2017年 lijianfei. All rights reserved.
//

#import "LJFRuntimeCopyObject.h"
#import <objc/runtime.h>

//字符串是否为空
#define IsStrEmpty(_ref)    (((_ref) == nil) || ([(_ref) isEqual:[NSNull null]]) ||([(_ref)isEqualToString:@""]))

//数组是否为空
#define IsArrEmpty(_ref)    (((_ref) == nil) || ([(_ref) isEqual:[NSNull null]]) ||([(_ref) count] == 0))

@implementation NSMutableDictionary (Safe)

// 设置Key/Value
- (void)setObjectSafe:(id)anObject forKey:(id < NSCopying >)aKey
{
    if (aKey == nil)
    {
        return;
    }
    
    if(anObject != nil)
    {
        [self setObject:anObject forKey:aKey];
    }
    else
    {
        if ([self objectForKey:aKey])
        {
            [self removeObjectForKey:aKey];
        }
    }
}

@end
@implementation LJFRuntimeCopyBasicObject
@end

@implementation LJFRuntimeCopyObject
- (id)copyWithZone:(NSZone *)zone
{
    id objCopy = [[[self class] allocWithZone:zone] init];
    NSMutableArray *propertyArray = [self getPropertyArray];
    NSUInteger count = [propertyArray count];
    for (int i = 0; i < count ; i++)
    {
        NSDictionary *dic = [propertyArray objectAtIndex:i];
        NSString *name = [dic objectForKey:@"name"];
        Class typeClass = [dic objectForKey:@"Class"];
        id value=[self valueForKey:name];
        if([value respondsToSelector:@selector(copyWithZone:)])
            [objCopy setValue:[value copy] forKey:name];
        else if([typeClass class] == [LJFRuntimeCopyBasicObject class])
            [objCopy setValue:value forKey:name];
        else
        {
            if (value != nil)
            {
                [self assertWithReason:[NSString stringWithFormat:@"Not responds copyWithZone:%@",[typeClass class]]];
                [objCopy setValue:value  forKey:name];
            }
        }
    }
    return objCopy;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    id objCopy = [[[self class] allocWithZone:zone] init];
    NSMutableArray *propertyArray = [self getPropertyArray];
    NSUInteger count = [propertyArray count];
    for (int i = 0; i < count ; i++)
    {
        NSDictionary *dic = [propertyArray objectAtIndex:i];
        NSString *name = [dic objectForKey:@"name"];
        Class typeClass = [dic objectForKey:@"Class"];
        id value = [self valueForKey:name];
        
        if ([typeClass class] == [NSArray class] || [typeClass class] == [NSMutableArray class])
        {
            if(!IsArrEmpty(value))
            {
                [objCopy setValue:[[[typeClass class] alloc] initWithArray:[self deepCopyArrayWithValue:value]] forKey:name];
            }
        }
        else if ([typeClass class] == [NSDictionary class] || [typeClass class] == [NSMutableDictionary class])
        {
            if(value != nil)
            {
                NSArray *allKey = [value allKeys];
                if (!IsArrEmpty(allKey))
                {
                    [objCopy setValue:[[[typeClass class] alloc] initWithDictionary:[self deepCopyDictionaryWithValue:value]] forKey:name];
                }
            }
        }
        else if ([typeClass class] == [NSSet class] || [typeClass class] == [NSMutableSet class])
        {
            if(value != nil)
            {
                NSArray *allObjects = [value allObjects];
                if (!IsArrEmpty(allObjects))
                {
                    [objCopy setValue:[[[typeClass class] alloc] initWithSet:[self deepCopySetWithValue:value]] forKey:name];
                }
            }
        }
        else if([typeClass class] == [NSNumber class])// NSNumber 不支持深拷贝，同时也不可以更改
        {
            [objCopy setValue:[value copy] forKey:name];
        }
        else if([typeClass class] == [LJFRuntimeCopyBasicObject class])
        {
            [objCopy setValue:value forKey:name]; // 基本数据类型直接赋值
        }
        else
        {
            if (value != nil)
            {
                if([value respondsToSelector:@selector(mutableCopyWithZone:)])
                    [objCopy setValue:[value mutableCopy] forKey:name];
                else
                {
                    [self assertWithReason:[NSString stringWithFormat:@"Not responds mutableCopyWithZone:%@",[typeClass class]]];
                    [objCopy setValue:value forKey:name];
                }
            }
        }
    }
    return objCopy;
}

// 数组深拷贝
- (NSArray *)deepCopyArrayWithValue:(NSArray*)value
{
    NSMutableArray *temp = [[NSMutableArray alloc] initWithCapacity:[value count]];
    for (id obj in value)
    {
        if([obj respondsToSelector:@selector(mutableCopyWithZone:)])
            [temp addObject:[obj mutableCopy]];
        else
        {
            // NSNumber 不支持深拷贝，同时也不可以更改
            if([obj isKindOfClass:[NSNumber class]])
                [temp addObject:[obj copy]];
            else
            {
                [self assertWithReason:[NSString stringWithFormat:@"Not responds mutableCopyWithZone:%@",[obj class]]];
                [temp addObject:obj];
            }
            
        }
    }
    return temp;
}

// 字典深拷贝
- (NSDictionary *)deepCopyDictionaryWithValue:(NSDictionary *)value
{
    NSArray *allKey = [value allKeys];
    NSMutableDictionary *temp = [[NSMutableDictionary alloc] initWithCapacity:[allKey count]];
    for (id key in allKey)
    {
        id obj = [value objectForKey:key];
        if([obj respondsToSelector:@selector(mutableCopyWithZone:)])
            [temp setObjectSafe:[obj mutableCopy] forKey:key];
        else
        {
            // NSNumber 不支持深拷贝，同时也不可以更改
            if([obj isKindOfClass:[NSNumber class]])
                [temp setObjectSafe:[obj copy] forKey:key];
            else
            {
                [self assertWithReason:[NSString stringWithFormat:@"Not responds mutableCopyWithZone:%@",[obj class]]];
                [temp setObjectSafe:obj forKey:key];
            }
        }
    }
    return temp;
}

// 集合深拷贝
- (NSSet *)deepCopySetWithValue:(NSSet *)value
{
    NSArray *allObjects = [value allObjects];
    NSMutableSet *temp = [[NSMutableSet alloc] initWithCapacity:[allObjects count]];
    for (id obj in allObjects)
    {
        if([obj respondsToSelector:@selector(mutableCopyWithZone:)])
            [temp addObject:[obj mutableCopy]];
        else
        {
            // NSNumber 不支持深拷贝，同时也不可以更改
            if([obj isKindOfClass:[NSNumber class]])
                [temp addObject:[obj copy]];
            else
            {
                [self assertWithReason:[NSString stringWithFormat:@"Not responds mutableCopyWithZone:%@",[obj class]]];
                [temp addObject:obj];
            }
        }
    }
    return temp;
}

- (NSMutableArray *)getPropertyArray
{
    Class clazz = [self class];
    u_int count;
    objc_property_t* properties = class_copyPropertyList(clazz, &count);
    NSMutableArray* propertyArray = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count ; i++)
    {
        const char* propertyName = property_getName(properties[i]);
        const char* propertyAttributes = property_getAttributes(properties[i]);
        NSString * typeString = [NSString stringWithUTF8String:propertyAttributes];
        // 自定义类型        @property Car *car; >>>>>> T@"Car",&,N,V_car
        // Foundation类型   @property NSString *name; >>>>>> T@"NSString",C,N,V_name
        // 基本数据类型      @property NSInteger age; >>>>>> Tq,N,V_age
        NSArray * attributes = [typeString componentsSeparatedByString:@","];
        // T@"Car"
        // T@"NSString"
        // Tq
        NSString * typeAttribute = [attributes objectAtIndex:0];
        Class typeClass = [LJFRuntimeCopyBasicObject class];// 默认为基本数据类型
        // 对象类型
        if ([typeAttribute hasPrefix:@"T@"] && [typeAttribute length] > 2)
        {
            // T@"Car" --> Car
            NSString * typeClassName = [typeAttribute substringWithRange:NSMakeRange(3, [typeAttribute length]-4)];
            if (NSClassFromString(typeClassName) != Nil)
                typeClass = NSClassFromString(typeClassName);
        }
        NSDictionary *dic = @{@"Class":typeClass,@"name":[NSString stringWithCString:propertyName encoding:NSUTF8StringEncoding]};
        [propertyArray addObject:dic];
    }
    free(properties);
    return propertyArray;
}

- (void)assertWithReason:(NSString*)reason
{
#if(BETA_BUILD == 1 || DEBUG)
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"警告" message:reason delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
    [alertView show];
#endif
}

@end
