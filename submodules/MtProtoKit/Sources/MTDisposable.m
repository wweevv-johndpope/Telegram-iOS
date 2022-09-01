#import <MtProtoKit/MTDisposable.h>

#import <libkern/OSAtomic.h>
#import <objc/runtime.h>
#import <os/lock.h>
#include <stdatomic.h>


@interface MTBlockDisposable () {
    // A copied block of type void (^)(void) containing the logic for disposal,
    // a pointer to `self` if no logic should be performed upon disposal, or
    // NULL if the receiver is already disposed.
    //
    // This should only be used atomically.
    void * volatile _disposeBlock;
}

@end


@implementation MTBlockDisposable

#pragma mark Properties

- (BOOL)isDisposed {
    return _disposeBlock == NULL;
}

#pragma mark Lifecycle

- (id)init {
    self = [super init];
    if (self == nil) return nil;

    _disposeBlock = (__bridge void *)self;
    atomic_thread_fence(memory_order_seq_cst);

    return self;
}

- (id)initWithBlock:(void (^)(void))block {
    NSCParameterAssert(block != nil);

    self = [super init];
    if (self == nil) return nil;

    _disposeBlock = (void *)CFBridgingRetain([block copy]);
    atomic_thread_fence(memory_order_seq_cst);

    return self;
}

+ (instancetype)disposableWithBlock:(void (^)(void))block {
    return [[self alloc] initWithBlock:block];
}

- (void)dealloc {
    if (_disposeBlock == NULL || _disposeBlock == (__bridge void *)self) return;

    CFRelease(_disposeBlock);
    _disposeBlock = NULL;
}

#pragma mark Disposal

- (void)dispose {
    void (^disposeBlock)(void) = NULL;

    while (YES) {
        void *blockPtr = _disposeBlock;
        if (atomic_compare_exchange_strong((volatile _Atomic(void*)*)&_disposeBlock, &blockPtr, NULL)) {
            if (blockPtr != (__bridge void *)self) {
                disposeBlock = CFBridgingRelease(blockPtr);
            }

            break;
        }
    }

    if (disposeBlock != nil) disposeBlock();
}

@end

@interface MTMetaDisposable ()
{
    os_unfair_lock _lock;
    bool _disposed;
    id<MTDisposable> _disposable;
}

@end

@implementation MTMetaDisposable

- (void)setDisposable:(id<MTDisposable>)disposable
{
    id<MTDisposable> previousDisposable = nil;
    bool dispose = false;
    
    os_unfair_lock_lock(&_lock);
    dispose = _disposed;
    if (!dispose)
    {
        previousDisposable = _disposable;
        _disposable = disposable;
    }
    os_unfair_lock_unlock(&_lock);
    
    if (previousDisposable != nil)
        [previousDisposable dispose];
    
    if (dispose)
        [disposable dispose];
}

- (void)dispose
{
    id<MTDisposable> disposable = nil;
    
    os_unfair_lock_lock(&_lock);
    if (!_disposed)
    {
        disposable = _disposable;
        _disposed = true;
    }
    os_unfair_lock_unlock(&_lock);
    
    if (disposable != nil)
        [disposable dispose];
}

@end

@interface MTDisposableSet ()
{
    os_unfair_lock _lock;
    bool _disposed;
    id<MTDisposable> _singleDisposable;
    NSArray *_multipleDisposables;
}

@end

@implementation MTDisposableSet

- (void)add:(id<MTDisposable>)disposable
{
    if (disposable == nil)
        return;
    
    bool dispose = false;
    
    os_unfair_lock_lock(&_lock);
    dispose = _disposed;
    if (!dispose)
    {
        if (_multipleDisposables != nil)
        {
            NSMutableArray *multipleDisposables = [[NSMutableArray alloc] initWithArray:_multipleDisposables];
            [multipleDisposables addObject:disposable];
            _multipleDisposables = multipleDisposables;
        }
        else if (_singleDisposable != nil)
        {
            NSMutableArray *multipleDisposables = [[NSMutableArray alloc] initWithObjects:_singleDisposable, disposable, nil];
            _multipleDisposables = multipleDisposables;
            _singleDisposable = nil;
        }
        else
        {
            _singleDisposable = disposable;
        }
    }
    os_unfair_lock_unlock(&_lock);
    
    if (dispose)
        [disposable dispose];
}

- (void)remove:(id<MTDisposable>)disposable {
    os_unfair_lock_lock(&_lock);
    if (_multipleDisposables != nil)
    {
        NSMutableArray *multipleDisposables = [[NSMutableArray alloc] initWithArray:_multipleDisposables];
        [multipleDisposables removeObject:disposable];
        _multipleDisposables = multipleDisposables;
    }
    else if (_singleDisposable == disposable)
    {
        _singleDisposable = nil;
    }
    os_unfair_lock_unlock(&_lock);
}

- (void)dispose
{
    id<MTDisposable> singleDisposable = nil;
    NSArray *multipleDisposables = nil;
    
    os_unfair_lock_lock(&_lock);
    if (!_disposed)
    {
        _disposed = true;
        singleDisposable = _singleDisposable;
        multipleDisposables = _multipleDisposables;
        _singleDisposable = nil;
        _multipleDisposables = nil;
    }
    os_unfair_lock_unlock(&_lock);
    
    if (singleDisposable != nil)
        [singleDisposable dispose];
    if (multipleDisposables != nil)
    {
        for (id<MTDisposable> disposable in multipleDisposables)
        {
            [disposable dispose];
        }
    }
}

@end
