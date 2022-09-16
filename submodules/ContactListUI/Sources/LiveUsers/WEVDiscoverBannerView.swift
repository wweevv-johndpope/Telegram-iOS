//
//  WEVDiscoverBannerView.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import UIKit

class WEVDiscoverBannerView: UICollectionReusableView {
    
    /// 选中某个
    public var didSelected: ((WEVVideoModel)->())? = nil
    
    /// 数据源
    public var dataArray: [WEVVideoModel] = [] {
        didSet {
            collectionView.reloadData()
            //pageView.pageNumber = dataArray.count
            //pageView.refreshCurrentPage()
        }
    }
    
    /// 当前页数
    /*private var currentIndex = 0 {
        didSet {
            pageView.currentPage = currentIndex
        }
    }*/
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
        
    //MARK: UI

    /// collectionView
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .horizontal
       
        let collectionView = UICollectionView.init(frame: bounds, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        //collectionView.isPagingEnabled = true
        collectionView.register(CollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        return collectionView
    }()
    
    /// 页码
   /* private let pageView: PageView = {
        let view = PageView()
        return view
    }()*/
    
    /// 初始视图
    private func initView() {
        backgroundColor = .clear
        clipsToBounds = true

        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        /*addSubview(pageView)
        pageView.snp.makeConstraints { (make) in
            make.right.left.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10)
            make.height.equalTo(2)
        }*/
    }
                
}

//MARK: UICollectionViewDataSource
extension WEVDiscoverBannerView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10 //dataArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        //let model = dataArray[indexPath.row]
        //cell.model = model
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.init(top: 8, left: 5, bottom: 0, right: 5)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 60, height: 80)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        //currentIndex = Int(targetContentOffset.pointee.x / frame.width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        /*let model = dataArray[indexPath.row]
        didSelected?(model)*/
    }
}

//MARK: CollectionViewCell
class CollectionViewCell: UICollectionViewCell {
    
    //MARK: UI
    /// 图片
    public let profileImageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = LJColor.main
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 30
        view.layer.masksToBounds = true
        return view
    }()
    
    /// 频道名字
    public let liveUserName: UILabel = {
        let label = UILabel.lj.configure(font: LJFont.medium(10), textColor: .black)
        label.text = "WWEEVV"
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    /// 初始视图
    func initView() {
        
        addSubview(liveUserName)
             
        liveUserName.snp.updateConstraints { (make) in
            make.left.equalToSuperview().offset(5)
            make.right.bottom.equalToSuperview().offset(-5)
            make.height.equalTo(15)
        }
        
        addSubview(profileImageView)
        profileImageView.snp.updateConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(liveUserName.snp.top)
        }
        
    }
    
}

//MARK: 页码视图
extension WEVDiscoverBannerView {
    class PageView: UIView {
        
        /// 总页数
        public var pageNumber: Int = 0 {
            didSet {
                if oldValue != pageNumber {
                    resetView()
                }
            }
        }
        
        /// 当前页码
        public var currentPage: Int = 0 {
            didSet {
                refreshCurrentPage()
            }
        }
        
        /// 线条数组
        private var lineArray: [UIView] = []
        
        /// 总页数发生改变，重置界面
        private func resetView() {
            subviews.forEach{$0.removeFromSuperview()}
            lineArray.removeAll()
            
            let lineWidth: CGFloat = 25
            let lineInterval: CGFloat = 8
            let totalWidth = lineWidth * CGFloat(pageNumber) + CGFloat(pageNumber - 1) * lineInterval
            for i in 0..<pageNumber {
                let line = UIView()
                line.backgroundColor = UIColor.init(white: 1, alpha: 0.5)
                lineArray.append(line)
                addSubview(line)
                line.snp.makeConstraints { (make) in
                    make.centerX.equalToSuperview().offset(-totalWidth / 2 + CGFloat(i) * (lineWidth + lineInterval) + lineWidth / 2.0)
                    make.centerY.equalToSuperview()
                    make.size.equalTo(CGSize(width: lineWidth, height: 2))
                }
            }
        }
        
        /// 当前页码发生改变，刷新界面
        public func refreshCurrentPage() {
            for (i, line) in lineArray.enumerated() {
                line.backgroundColor = UIColor.init(white: 1, alpha: i == currentPage ? 1 : 0.3)
            }
        }
    }
}
