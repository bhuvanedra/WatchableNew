//
//  MemoryManagement.h
//  Watchable
//
//  Created by Luke LaBonte on 2/1/17.
//  Copyright © 2017 comcast. All rights reserved.
//

#ifndef MemoryManagement_h
#define MemoryManagement_h

#pragma mark - Memory Management Macros

/*
 * A utility macro for declaring a weak reference to self
 */
#define WATCHABLE_DECLARE_WEAK_SELF(name) __typeof(self) __weak name = self

/*
 * A utility macro for declaring a weak reference to |var|.
 */
#define WATCHABLE_DECLARE_WEAK(var, name) __typeof(var) __weak name = var

/*
 * A utility macro for explicitly declaring a strong reference to |var|. This is used in cases where a weak reference
 * would normally be used, but there is a reason why it shouldn't. This macro makes clear in code that a conscious 
 * choice has been made to use a strong reference.
 */
#define WATCHABLE_DECLARE_STRONG(var, name) __typeof(var) name = var

/*
 * Macros to help with the most common use case for memory safety when using self within blocks.
 *
 * Examples:
 *
 * WATCHABLE_DECLARE_WEAK_SELF;
 *
 * [object executeWithCompletion: ^{
 *    WATCHABLE_STRONG_SELF_OR_RETURN;
 *
 *     [strongSelf doStuff];
 *     [strongSelf doMoreStuff];
 * }];
 *
 * Usage of these macros help prevent the following compiler warnings:
 * Apple LLVM 6.0 - Warnings - Objective C and ARC
 * Repeatedly using a __weak reference
 * Sending messages to __weak pointers
 *
 * These warnings indicate the possibility of the block being executed after weakSelf has been released by another 
 * thread or if the block outlives the weak reference. If either of these occur it can lead *to undefined behavior or
 * crashes.
 */
#define WATCHABLE_WEAK_SELF WATCHABLE_DECLARE_WEAK_SELF(weakSelf)
#define WATCHABLE_STRONG_SELF WATCHABLE_DECLARE_STRONG(weakSelf, strongSelf)
#define WATCHABLE_IF_NOT_STRONG_RETURN \
    if (strongSelf == nil)             \
    return
#define WATCHABLE_STRONG_SELF_OR_RETURN \
    WATCHABLE_STRONG_SELF;              \
    WATCHABLE_IF_NOT_STRONG_RETURN

#endif /* MemoryManagement_h */
