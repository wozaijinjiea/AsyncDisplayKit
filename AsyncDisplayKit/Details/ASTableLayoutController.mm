//
//  ASTableLayoutController.mm
//  AsyncDisplayKit
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the root directory of this source tree. An additional grant
//  of patent rights can be found in the PATENTS file in the same directory.
//

#import <AsyncDisplayKit/ASTableLayoutController.h>

#import <UIKit/UIKit.h>

#import <AsyncDisplayKit/ASAssert.h>

@interface ASTableLayoutController()
// This will be sorted ascending.
@property (nonatomic, strong) NSArray<NSIndexPath *> *visibleIndexPaths;
@end

@implementation ASTableLayoutController

- (instancetype)initWithTableView:(UITableView *)tableView
{
  if (!(self = [super init])) {
    return nil;
  }
  _tableView = tableView;
  return self;
}

#pragma mark - Visible Indices

- (void)setVisibleNodeIndexPaths:(NSArray *)indexPaths
{
  _visibleIndexPaths = [indexPaths sortedArrayUsingSelector:@selector(compare:)];
}

/**
 * IndexPath array for the element in the working range.
 */

- (NSSet *)indexPathsForScrolling:(ASScrollDirection)scrollDirection rangeMode:(ASLayoutRangeMode)rangeMode rangeType:(ASLayoutRangeType)rangeType
{
  if (_visibleIndexPaths.count == 0) {
    return [NSSet set];
  }

  CGSize viewportSize = [self viewportSize];

  ASRangeTuningParameters tuningParameters = [self tuningParametersForRangeMode:rangeMode rangeType:rangeType];

  ASDirectionalScreenfulBuffer directionalBuffer = ASDirectionalScreenfulBufferVertical(scrollDirection, tuningParameters);
  
  NSIndexPath *startPath = [self findIndexPathAtDistance:(-directionalBuffer.negativeDirection * viewportSize.height)
                                          fromIndexPath:_visibleIndexPaths.firstObject];
  
  NSIndexPath *endPath   = [self findIndexPathAtDistance:(directionalBuffer.positiveDirection * viewportSize.height)
                                          fromIndexPath:_visibleIndexPaths.lastObject];

  NSSet *indexPaths = [self indexPathsFromIndexPath:startPath toIndexPath:endPath];
  return indexPaths;
}

#pragma mark - Utility

- (NSIndexPath *)findIndexPathAtDistance:(CGFloat)distance fromIndexPath:(NSIndexPath *)start
{
  CGFloat startY = CGRectGetMidY([_tableView rectForRowAtIndexPath:start]);
  static CGFloat kInitialRowSearchHeight = 100;
  /**
   * There may not be a row at any given EXACT point, for these possible reasons:
   * - There is a section header/footer at that point.
   * - That point is beyond the start/end of the table content.
   *
   * Solution: Make a target rect, starting at height 100, and if we don't
   * find any rows, keep doubling its height and searching again. In practice,
   * this will virtually always find 
   */
  NSIndexPath *result = nil;
  for (CGRect targetRect = CGRectMake(0, startY, 1, kInitialRowSearchHeight);
       result == nil;
       targetRect = CGRectInset(targetRect, 0, -CGRectGetHeight(targetRect) / 2.0)) {
    result = [_tableView indexPathsForRowsInRect:targetRect].firstObject;
  }
  return result;
}

- (NSSet<NSIndexPath *> *)indexPathsFromIndexPath:(NSIndexPath *)startIndexPath toIndexPath:(NSIndexPath *)endIndexPath
{
  ASDisplayNodeAssert([startIndexPath compare:endIndexPath] != NSOrderedDescending, @"Index paths must be in nondescending order. Start: %@, end %@", startIndexPath, endIndexPath);

  NSMutableSet *result = [NSMutableSet set];
  NSInteger const endSection = endIndexPath.section;
  NSInteger i = startIndexPath.row;
  for (NSInteger s = startIndexPath.section; s <= endSection; s++) {
    // If end section, row <= end.item. Otherwise (row <= sectionRowCount - 1).
    NSInteger const rowLimit = (s == endSection ? endIndexPath.row : ([_tableView numberOfRowsInSection:s] - 1));
    for (; i <= rowLimit; i++) {
      [result addObject:[NSIndexPath indexPathForRow:i inSection:s]];
    }
    i = 0;
  }
  return result;
}

@end
