//
//  InfiniteScrollingBehaviour.swift
//  InfiniteScrolling
//
//  Created by Vishal Singh on 1/21/17.
//  Copyright © 2017 Vishal Singh. All rights reserved.
//
import UIKit

public protocol InfiniteScrollingBehaviourDelegate: class {
    func configuredCell(forItemAtIndexPath indexPath: IndexPath, originalIndex: Int, andData data: InfiniteScollingData, forInfiniteScrollingBehaviour behaviour: InfiniteScrollingBehaviour) -> UICollectionViewCell
    func didSelectItem(atIndexPath indexPath: IndexPath, originalIndex: Int, andData data: InfiniteScollingData, inInfiniteScrollingBehaviour behaviour: InfiniteScrollingBehaviour) -> Void
    func didEndScrolling(inInfiniteScrollingBehaviour behaviour: InfiniteScrollingBehaviour)
    func verticalPaddingForHorizontalInfiniteScrollingBehaviour(behaviour: InfiniteScrollingBehaviour) -> CGFloat
    func horizonalPaddingForHorizontalInfiniteScrollingBehaviour(behaviour: InfiniteScrollingBehaviour) -> CGFloat
}

public extension InfiniteScrollingBehaviourDelegate {
    func didSelectItem(atIndexPath indexPath: IndexPath, originalIndex: Int, andData data: InfiniteScollingData, inInfiniteScrollingBehaviour behaviour: InfiniteScrollingBehaviour) -> Void { }
    func didEndScrolling(inInfiniteScrollingBehaviour behaviour: InfiniteScrollingBehaviour) { }
    func verticalPaddingForHorizontalInfiniteScrollingBehaviour(behaviour: InfiniteScrollingBehaviour) -> CGFloat {
        return 0
    }
    func horizonalPaddingForHorizontalInfiniteScrollingBehaviour(behaviour: InfiniteScrollingBehaviour) -> CGFloat {
        return 0
    }
}

public protocol InfiniteScollingData { }

public enum LayoutType {
    case fixedSize(sizeValue: CGFloat, lineSpacing: CGFloat)
    case numberOfCellOnScreen(Double)
}

public struct CollectionViewConfiguration {
    public let scrollingDirection: UICollectionView.ScrollDirection
    public var layoutType: LayoutType
    public static let `default`
        = CollectionViewConfiguration(layoutType: .numberOfCellOnScreen(5),
                                      scrollingDirection: .horizontal)
    public init(layoutType: LayoutType,
                scrollingDirection: UICollectionView.ScrollDirection) {
        self.layoutType = layoutType
        self.scrollingDirection = scrollingDirection
    }
}

public class InfiniteScrollingBehaviour: NSObject {
    private var cellSize: CGFloat = 0.0
    private var padding: CGFloat = 0.0
    private var numberOfBoundaryElements = 0
    private(set) public weak var collectionView: UICollectionView!
    private(set) public weak var delegate: InfiniteScrollingBehaviourDelegate?
    private(set) public var dataSet: [InfiniteScollingData]
    private(set) public var dataSetWithBoundary: [InfiniteScollingData] = []
    private var collectionViewBoundsValue: CGFloat {
        get {
            switch self.collectionConfiguration.scrollingDirection {
            case .horizontal:
                return self.collectionView.bounds.size.width
            case .vertical:
                return self.collectionView.bounds.size.height
            }
        }
    }

    private var scrollViewContentSizeValue: CGFloat {
        get {
            switch self.collectionConfiguration.scrollingDirection {
            case .horizontal:
                return self.collectionView.contentSize.width
            case .vertical:
                return self.collectionView.contentSize.height
            }
        }
    }

    private(set) public var collectionConfiguration: CollectionViewConfiguration

    public init(withCollectionView collectionView: UICollectionView,
                andData dataSet: [InfiniteScollingData],
                delegate: InfiniteScrollingBehaviourDelegate,
                configuration: CollectionViewConfiguration = .default) {
        self.collectionView = collectionView
        self.dataSet = dataSet
        self.collectionConfiguration = configuration
        self.delegate = delegate
        super.init()
        self.configureBoundariesForInfiniteScroll()
        self.configureCollectionView()
        self.scrollToFirstElement()
    }


    private func configureBoundariesForInfiniteScroll() {
        self.dataSetWithBoundary = dataSet
        self.calculateCellWidth()
        let absoluteNumberOfElementsOnScreen
            = ceil(self.collectionViewBoundsValue / self.cellSize)
        self.numberOfBoundaryElements = Int(absoluteNumberOfElementsOnScreen)
        self.addLeadingBoundaryElements()
        self.addTrailingBoundaryElements()
    }

    private func calculateCellWidth() {
        switch self.collectionConfiguration.layoutType {
        case .fixedSize(let sizeValue, let padding):
            self.cellSize = sizeValue
            self.padding = padding
        case .numberOfCellOnScreen(let numberOfCellsOnScreen):
            self.cellSize = (self.collectionViewBoundsValue / numberOfCellsOnScreen.cgFloat)
            self.padding = 0
        }
    }

    private func addLeadingBoundaryElements() {
        for index in stride(from: self.numberOfBoundaryElements, to: 0, by: -1) {
            let indexToAdd = (self.dataSet.count - 1) - ((self.numberOfBoundaryElements - index) % self.dataSet.count)
            let data = self.dataSet[indexToAdd]
            self.dataSetWithBoundary.insert(data, at: 0)
        }
    }

    private func addTrailingBoundaryElements() {
        for index in 0..<self.numberOfBoundaryElements {
            let data = self.dataSet[index%dataSet.count]
            self.dataSetWithBoundary.append(data)
        }
    }

    private func configureCollectionView() {
        guard let _ = self.delegate else { return }
        self.collectionView.delegate = nil
        self.collectionView.dataSource = nil
        self.collectionView.showsVerticalScrollIndicator = false
        self.collectionView.showsHorizontalScrollIndicator = false

        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = collectionConfiguration.scrollingDirection
        self.collectionView.collectionViewLayout = flowLayout
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }

    private func scrollToFirstElement() {
        self.scroll(toElementAtIndex: 0)
    }


    public func scroll(toElementAtIndex index: Int) {
        let boundaryDataSetIndex = self.indexInBoundaryDataSet(forIndexInOriginalDataSet: index)
        let indexPath = IndexPath(item: boundaryDataSetIndex, section: 0)
        let scrollPosition: UICollectionView.ScrollPosition = self.collectionConfiguration.scrollingDirection == .horizontal ? .left : .top
        self.collectionView.scrollToItem(at: indexPath, at: scrollPosition, animated: false)
    }

    public func indexInOriginalDataSet(forIndexInBoundaryDataSet index: Int) -> Int {
        let difference = index - self.numberOfBoundaryElements
        if difference < 0 {
            let originalIndex = self.dataSet.count + difference
            return abs(originalIndex % self.dataSet.count)
        } else if difference < self.dataSet.count {
            return difference
        } else {
            return abs((difference - dataSet.count) % dataSet.count)
        }
    }

    public func indexInBoundaryDataSet(forIndexInOriginalDataSet index: Int) -> Int {
        return index + self.numberOfBoundaryElements
    }
    
    
    public func reload(withData dataSet: [InfiniteScollingData]) {
        self.dataSet = dataSet
        configureBoundariesForInfiniteScroll()
        collectionView.reloadData()
        scrollToFirstElement()
    }

    public func updateConfiguration(configuration: CollectionViewConfiguration) {
        self.collectionConfiguration = configuration
        self.configureBoundariesForInfiniteScroll()
        self.configureCollectionView()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.collectionView.reloadData()
            self.scrollToFirstElement()
        }
    }
}

extension InfiniteScrollingBehaviour: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.padding
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return self.padding
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch (collectionConfiguration.scrollingDirection, delegate) {
        case (.horizontal, .some(let delegate)):
            let inset = delegate.verticalPaddingForHorizontalInfiniteScrollingBehaviour(behaviour: self)
            return UIEdgeInsets(top: inset, left: 0, bottom: inset, right: 0)
        case (.vertical, .some(let delegate)):
            let inset = delegate.horizonalPaddingForHorizontalInfiniteScrollingBehaviour(behaviour: self)
            return UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        case (_, _):
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch (collectionConfiguration.scrollingDirection, delegate) {
        case (.horizontal, .some(let delegate)):
            let height = collectionView.bounds.size.height - 2*delegate.verticalPaddingForHorizontalInfiniteScrollingBehaviour(behaviour: self)
            return CGSize(width: cellSize, height: height)
        case (.vertical, .some(let delegate)):
            let width = collectionView.bounds.size.width - 2*delegate.horizonalPaddingForHorizontalInfiniteScrollingBehaviour(behaviour: self)
            return CGSize(width: width, height: cellSize)
        case (.horizontal, _):
            return CGSize(width: cellSize, height: collectionView.bounds.size.height)
        case (.vertical, _):
            return CGSize(width: collectionView.bounds.size.width, height: cellSize)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let originalIndex = self.indexInOriginalDataSet(forIndexInBoundaryDataSet: indexPath.item)
        self.delegate?.didSelectItem(atIndexPath: indexPath,
                                     originalIndex: originalIndex,
                                     andData: self.dataSetWithBoundary[indexPath.item],
                                     inInfiniteScrollingBehaviour: self)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let boundarySize = self.numberOfBoundaryElements.cgFloat * self.cellSize + (self.numberOfBoundaryElements.cgFloat * self.padding)
        let contentOffsetValue = self.collectionConfiguration.scrollingDirection == .horizontal ? scrollView.contentOffset.x : scrollView.contentOffset.y
        if contentOffsetValue >= (self.scrollViewContentSizeValue - boundarySize) {
            let offset = boundarySize - self.padding
            let updatedOffsetPoint = self.collectionConfiguration.scrollingDirection == .horizontal ?
                CGPoint(x: offset, y: 0) : CGPoint(x: 0, y: offset)
            scrollView.contentOffset = updatedOffsetPoint
        } else if contentOffsetValue <= 0 {
            let boundaryLessSize = self.dataSet.count.cgFloat * self.cellSize + (self.dataSet.count.cgFloat * self.padding)
            let updatedOffsetPoint = self.collectionConfiguration.scrollingDirection == .horizontal ?
                CGPoint(x: boundaryLessSize, y: 0) : CGPoint(x: 0, y: boundaryLessSize)
            scrollView.contentOffset = updatedOffsetPoint
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.delegate?.didEndScrolling(inInfiniteScrollingBehaviour: self)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                         willDecelerate decelerate: Bool) {
        if decelerate == false {
            self.delegate?.didEndScrolling(inInfiniteScrollingBehaviour: self)
        }
    }

}

extension InfiniteScrollingBehaviour: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSetWithBoundary.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let delegate = self.delegate else {
            return UICollectionViewCell()
        }
        let originalIndex = indexInOriginalDataSet(forIndexInBoundaryDataSet: indexPath.item)
        return delegate.configuredCell(forItemAtIndexPath: indexPath,
                                       originalIndex: originalIndex,
                                       andData: self.dataSetWithBoundary[indexPath.item],
                                       forInfiniteScrollingBehaviour: self)
    }
}

extension Double {
    var cgFloat: CGFloat {
        get {
            return CGFloat(self)
        }
    }
}

extension Int {
    var cgFloat: CGFloat {
        get {
            return CGFloat(self)
        }
    }
}
