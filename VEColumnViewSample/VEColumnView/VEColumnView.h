//
//  VEColumnView.m
//  VEColumnViewSample
//
//  Created by Yamazaki Mitsuyoshi on 6/18/13.
//  Copyright (c) 2013 Mitsuyoshi Yamazaki. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VEColumnView;

@protocol VEColumnViewDatasource <NSObject>
@required
- (NSInteger)columnViewColumCount:(VEColumnView *)columnView;
- (NSInteger)columnViewItemCount:(VEColumnView *)columnView;
- (CGFloat)columnView:(VEColumnView *)columnView viewSizeRatioAtIndex:(NSInteger)index;
- (UIView *)columnView:(VEColumnView *)columnView viewAtIndex:(NSInteger)index;
@end

@protocol VEColumnViewDelegate <NSObject, UIScrollViewDelegate>
@optional
- (void)columnView:(VEColumnView *)columnView didSelectViewAtIndex:(NSInteger)index;
@end

/** 現在は仕様として、 dequeReusableView から返るviewはgestureRecognizerがremoveされている
 */
@interface VEColumnView : UIScrollView

@property (nonatomic, weak) id <VEColumnViewDatasource> datasource;
@property (nonatomic, weak) id <VEColumnViewDelegate> delegate;

- (UIView *)dequeReusableView;
- (NSIndexSet *)visibleIndices;
- (NSArray *)visibleViews;
- (UIView *)viewForIndex:(NSInteger)index;
- (NSArray *)viewsForIndices:(NSIndexSet *)indexSet;
- (void)reloadData;

@end
