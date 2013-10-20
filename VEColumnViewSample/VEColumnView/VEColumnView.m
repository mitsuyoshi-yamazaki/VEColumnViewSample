//
//  VEColumnView.m
//  VEColumnViewSample
//
//  Created by Yamazaki Mitsuyoshi on 6/18/13.
//  Copyright (c) 2013 Mitsuyoshi Yamazaki. All rights reserved.
//

#import "VEColumnView.h"

@interface VEColumnView () {
	
	NSMutableArray *_reuseableViews;
	
	NSInteger _columnCount;
	NSInteger _itemCount;
	NSArray *_itemSizes;
	NSIndexSet *_previousVisibleIndices;
	NSMutableDictionary *_allViews;
	BOOL _reloadData;
	
	NSArray *_defaultSubviews;
}

- (void)initialize;
- (void)prepareViews;
- (void)getDatas;

- (void)enqueueVisibleViews;
- (void)enqueueReuseableViewAtIndex:(NSInteger)index;

- (void)viewDidSelect:(UITapGestureRecognizer *)gestureRecognizer;

NSInteger shortestLine(CGFloat *lineHeights, NSInteger columnCount);
NSInteger longestLine(CGFloat *lineHeights, NSInteger columnCount);

@end

@implementation VEColumnView

@synthesize datasource = _datasource;
@synthesize delegate = _columnViewDelegate;

#pragma mark - Accessor
- (void)setDatasource:(id<VEColumnViewDatasource>)datasource {
	
	if ([datasource conformsToProtocol:@protocol(VEColumnViewDatasource)] == NO) {
		[NSException raise:NSInvalidArgumentException format:@"Datasource %@ must conform to the VEColumnViewDatasource protocol", datasource];
	}
	_datasource = datasource;
}

- (void)setDelegate:(id<VEColumnViewDelegate>)delegate {
	
	if (delegate != nil && [delegate conformsToProtocol:@protocol(VEColumnViewDelegate)] == NO) {
		[NSException raise:NSInvalidArgumentException format:@"Delegate %@ must conform to the VEColumnViewDelegate protocol", delegate];
	}
	
	[super setDelegate:delegate];
	_columnViewDelegate = delegate;
}

#pragma mark - Lifecycle
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		[self initialize];
	}
    return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	
	[self initialize];
}

- (void)initialize {
	
	self.pagingEnabled = NO;
	self.showsHorizontalScrollIndicator = NO;
	self.showsVerticalScrollIndicator = YES;
	self.alwaysBounceVertical = YES;
	self.alwaysBounceHorizontal = NO;
	self.backgroundColor = [UIColor clearColor];
	self.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
	self.contentSize = self.frame.size;
	
	_reuseableViews = [[NSMutableArray alloc] initWithCapacity:0];
	_itemSizes = nil;
	_previousVisibleIndices = nil;
	_allViews = [[NSMutableDictionary alloc] initWithCapacity:0];
	
	_columnCount = 0;
	_reloadData = NO;
	
	_defaultSubviews = self.subviews.copy;
}

#pragma mark - Reusable Views
- (UIView *)dequeReusableView {
	
	UIView *view = _reuseableViews.lastObject;
	[_reuseableViews removeLastObject];
		
	return view;
}

- (void)enqueueVisibleViews {
	
	NSArray *views = [_allViews allValues];
	
	for (UIView *aView in views) {
		for (UIGestureRecognizer *recognizer in aView.gestureRecognizers) {
			[aView removeGestureRecognizer:recognizer];
			[aView removeFromSuperview];
		}
	}
	
	[_reuseableViews addObjectsFromArray:views];
	[_allViews removeAllObjects];
}

- (void)enqueueReuseableViewAtIndex:(NSInteger)index {
	
	NSNumber *key = [NSNumber numberWithInteger:index];
	UIView *view = [_allViews objectForKey:key];
	
	if (view == nil) {
		return;
	}
	
	for (UIGestureRecognizer *recognizer in view.gestureRecognizers) {
		[view removeGestureRecognizer:recognizer];
	}
	
	[view removeFromSuperview];
	[_allViews removeObjectForKey:key];
	[_reuseableViews addObject:view];
}

#pragma mark - Visible Views
- (NSIndexSet *)visibleIndices {

	CGRect visibleRect = CGRectZero;
	visibleRect.origin = self.contentOffset;
	visibleRect.size = self.frame.size;
	
	NSMutableIndexSet *indices = [NSMutableIndexSet indexSet];
	
	for (NSInteger index = 0; index < _itemCount; index++) {
		NSValue *frameValue = _itemSizes[index];
		CGRect frame = frameValue.CGRectValue;
		
		if (CGRectIntersectsRect(frame, visibleRect)) {
			[indices addIndex:index];
		}
	}
	
	return indices;
}

- (NSArray *)visibleViews {
	return [self viewsForIndices:self.visibleIndices];
}

- (UIView *)viewForIndex:(NSInteger)index {
	NSNumber *key = [NSNumber numberWithInteger:index];
	return [_allViews objectForKey:key];
}

- (NSArray *)viewsForIndices:(NSIndexSet *)indexSet {
	
	NSMutableArray *views = [NSMutableArray array];
	
	[indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		UIView *view = [self viewForIndex:idx];
		if (view) {
			[views addObject:view];
		}
	}];
	
	return views;
}

#pragma mark - Reload
- (void)reloadData {
	
	_reloadData = YES;
	[self getDatas];
	[self setNeedsLayout];
}

- (void)getDatas {

	_columnCount = [self.datasource columnViewColumCount:self];
	_itemCount = [self.datasource columnViewItemCount:self];

	CGFloat lineHeights[_columnCount];
	CGFloat margin = 4.0f;
	CGFloat columnWidth = (self.frame.size.width - margin) / _columnCount;
	CGFloat lineWidth = columnWidth - margin;
	
	for (NSInteger line = 0; line < _columnCount; line++) {
		lineHeights[line] = 0.0f;
	}

	NSMutableArray *sizes = [NSMutableArray arrayWithCapacity:_itemCount];
	
	for (NSInteger index = 0; index < _itemCount; index++) {
		
		NSInteger line = shortestLine(lineHeights, _columnCount);
		CGRect frame = CGRectZero;
		CGFloat ratio = [self.datasource columnView:self viewSizeRatioAtIndex:index];
		frame.origin.x = (columnWidth * line) + margin;
		frame.origin.y = lineHeights[line] + margin;
		frame.size = CGSizeMake(lineWidth, lineWidth * ratio);
		
		NSValue *frameValue = [NSValue valueWithCGRect:frame];
		[sizes addObject:frameValue];
		
		lineHeights[line] += frame.size.height + margin;
	}
	
	_itemSizes = sizes.copy;
	
	CGSize contentSize = self.frame.size;
	NSInteger longestLineIndex = longestLine(lineHeights, _columnCount);
	contentSize.height = lineHeights[longestLineIndex] + margin;
	self.contentSize = contentSize;
}

#pragma mark - Layout
- (void)layoutSubviews {

	if (_itemSizes.count == _itemCount) {
		[self prepareViews];
	}
}

- (void)prepareViews {
	
	NSMutableIndexSet *addViewIndices = [NSMutableIndexSet indexSet];
	NSIndexSet *visibleIndices = self.visibleIndices.copy;

	if (_reloadData) {
		[self enqueueVisibleViews];
		
		[addViewIndices addIndexes:visibleIndices];
	}
	else {		
		[_previousVisibleIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			
			if ([visibleIndices containsIndex:idx] == NO) {
				[self enqueueReuseableViewAtIndex:idx];
			}
		}];
		
		[visibleIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			
			if ([_previousVisibleIndices containsIndex:idx] == NO) {
				[addViewIndices addIndex:idx];
			}		
		}];
	}
	
	[addViewIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		
		// on main thread
		UIView *view = [self.datasource columnView:self viewAtIndex:idx];
		
		UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidSelect:)];
		gestureRecognizer.cancelsTouchesInView = NO;
		[view addGestureRecognizer:gestureRecognizer];

		NSValue *frameValue = _itemSizes[idx];
		CGRect frame = frameValue.CGRectValue;
		
		view.frame = frame;
		[self addSubview:view];		
		NSNumber *key = [NSNumber numberWithInteger:idx];
		[_allViews setObject:view forKey:key];
	}];
	
	for (UIView *view in _defaultSubviews) {
		[self bringSubviewToFront:view];
	}
		
	_previousVisibleIndices = visibleIndices.copy;

	_reloadData = NO;
}

- (void)viewDidSelect:(UITapGestureRecognizer *)gestureRecognizer {
	
	if ([self.delegate respondsToSelector:@selector(columnView:didSelectViewAtIndex:)]) {
		UIView *view = gestureRecognizer.view;
		NSNumber *key = [_allViews allKeysForObject:view][0];
		NSInteger index = key.integerValue;
		
		[self.delegate columnView:self didSelectViewAtIndex:index];
	}
}

NSInteger shortestLine(CGFloat *lineHeights, NSInteger columnCount) {
	
	NSInteger shortestLine = 0;
	CGFloat shortest = CGFLOAT_MAX;
	
	for (NSInteger line = 0; line < columnCount; line++) {
		if (lineHeights[line] < shortest) {
			shortestLine = line;
			shortest = lineHeights[line];
		}
	}
	
	return shortestLine;
}

NSInteger longestLine(CGFloat *lineHeights, NSInteger columnCount) {
	
	NSInteger longestLine = 0;
	CGFloat longest = 0.0f;
	
	for (NSInteger line = 0; line < columnCount; line++) {
		if (lineHeights[line] > longest) {
			longestLine = line;
			longest = lineHeights[line];
		}
	}
	
	return longestLine;
}

@end
