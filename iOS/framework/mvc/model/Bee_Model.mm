//
//	 ______    ______    ______
//	/\  __ \  /\  ___\  /\  ___\
//	\ \  __<  \ \  __\_ \ \  __\_
//	 \ \_____\ \ \_____\ \ \_____\
//	  \/_____/  \/_____/  \/_____/
//
//
//	Copyright (c) 2013-2014, {Bee} open source community
//	http://www.bee-framework.com
//
//
//	Permission is hereby granted, free of charge, to any person obtaining a
//	copy of this software and associated documentation files (the "Software"),
//	to deal in the Software without restriction, including without limitation
//	the rights to use, copy, modify, merge, publish, distribute, sublicense,
//	and/or sell copies of the Software, and to permit persons to whom the
//	Software is furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//	IN THE SOFTWARE.
//

#import "Bee_Model.h"
#import "NSObject+BeeMessage.h"
#import "NSObject+BeeHTTPRequest.h"

// ----------------------------------
// Source code
// ----------------------------------

#pragma mark -

#undef	__PRELOAD_MODELS__
#define __PRELOAD_MODELS__		(__OFF__)

#pragma mark -

@interface BeeModel()
{
	NSString *			_name;
	NSMutableArray *	_observers;
}
@end

#pragma mark -

@implementation BeeModel

@synthesize name = _name;
@synthesize observers = _observers;

static NSMutableArray *	__models = nil;

+ (BOOL)autoLoad
{
#if defined(__PRELOAD_MODELS__) && __PRELOAD_MODELS__
	
	INFO( @"Loading models ..." );

	[[BeeLogger sharedInstance] indent];
	[[BeeLogger sharedInstance] disable];

	NSArray * availableClasses = [BeeRuntime allSubClassesOf:[BeeModel class]];
	
	for ( Class classType in availableClasses )
	{
		if ( [classType instancesRespondToSelector:@selector(sharedInstance)] )
		{
			[classType sharedInstance];
		}
	}

	[[BeeLogger sharedInstance] unindent];
	[[BeeLogger sharedInstance] enable];

#endif	// #if defined(__PRELOAD_MODELS__) && __PRELOAD_MODELS__
	
	return YES;
}

+ (id)model
{
	return [[[[self class] alloc] init] autorelease];
}

+ (id)modelWithObserver:(id)observer
{
	BeeModel * model = [[[[self class] alloc] init] autorelease];
	if ( model )
	{
		[model addObserver:observer];
	}
	return model;
}

+ (NSMutableArray *)models
{
	return __models;
}

+ (NSMutableArray *)modelsByClass:(Class)clazz
{
	if ( 0 == __models.count )
		return nil;

	NSMutableArray * array = [NSMutableArray array];
	
	for ( BeeModel * model in __models )
	{
		if ( [model isKindOfClass:clazz] )
		{
			[array addObject:model];
		}
	}
	
	return array;
}

+ (NSMutableArray *)modelsByName:(NSString *)name
{
	if ( 0 == __models.count )
		return nil;

	NSMutableArray * array = [NSMutableArray array];
	
	for ( BeeModel * model in __models )
	{
		if ( [model.name isEqualToString:name] )
		{
			[array addObject:model];
		}
	}

	return array;
}

- (id)init
{
	self = [super init];
	if ( self )
	{
		[self initSelf];
		[self load];
	}
	return self;
}

- (void)initSelf
{
	_name = [[[self class] description] retain];
	_observers = [[NSMutableArray nonRetainingArray] retain];
	
	if ( nil == __models )
	{
		__models = [[NSMutableArray nonRetainingArray] retain];
	}

	[__models addObject:self];
}

- (void)dealloc
{
	[self unload];
	[self cancelMessages];
	[self cancelRequests];
	
	[_observers removeAllObjects];
	[_observers release];
	[_name release];
	
	[__models removeObject:self];
	
	[super dealloc];
}

- (void)load
{
	if ( [self respondsToSelector:@selector(unserialize)] )
	{
		[self unserialize];
	}
}

- (void)unload
{
	if ( [self respondsToSelector:@selector(serialize)] )
	{
		[self serialize];
	}
}

- (void)serialize
{	
}

- (void)unserialize
{
}

- (void)addObserver:(id)obj
{
	if ( NO == [_observers containsObject:obj] )
	{
		[_observers addObject:obj];
	}
}

- (void)removeObserver:(id)obj
{
	if ( [_observers containsObject:obj] )
	{
		[_observers removeObject:obj];
	}
}

- (void)posthandleMessage:(BeeMessage *)msg
{
	if ( msg.nextState != msg.state )
		return;

// forward all messages to observers
	
    NSArray * observers = [NSArray arrayWithArray:_observers];
	for ( NSObject * obj in observers )
	{
		[msg forwardResponder:obj];
	}
}

- (void)posthandleRequest:(BeeHTTPRequest *)request
{
// forward all requests to observers

    NSArray * observers = [NSArray arrayWithArray:_observers];    
	for ( NSObject * obj in observers )
	{
		[request forwardResponder:obj];
	}
}

@end

// ----------------------------------
// Unit test
// ----------------------------------

#if defined(__BEE_UNITTEST__) && __BEE_UNITTEST__

#pragma mark -

TEST_CASE( BeeModel )
{
}
TEST_CASE_END

#endif	// #if defined(__BEE_UNITTEST__) && __BEE_UNITTEST__
