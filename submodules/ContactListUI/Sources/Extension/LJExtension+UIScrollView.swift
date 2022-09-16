//
//  LJExtension+UIScrollView.swift
//  Wweevv
//
//  Created by panjinyong on 2020/12/24.
//

import UIKit
import MJRefresh

extension LJExtension where Base: UIScrollView {
  
    //MARK: 添加MJRefresh
    
    /// 添加头部刷新
    func addMJReshreHeader(delegate: LJScrollViewRefreshDelegate) {
        let scrollView = base
        let header = MJRefreshNormalHeader.init(refreshingBlock: { [weak scrollView, weak delegate] in
            scrollView?.mj_header?.beginRefreshing()
            delegate?.scrollViewLoadData(isHeadRefesh: true)
        })
        scrollView.mj_header = header
    }
    
    /// 添加底部刷新
    func addMJReshreFooter(delegate: LJScrollViewRefreshDelegate) {
        let scrollView = base

        let footer = MJRefreshBackNormalFooter.init(refreshingBlock: { [weak scrollView, weak delegate] in
            scrollView?.mj_footer?.beginRefreshing()
            delegate?.scrollViewLoadData(isHeadRefesh: false)
        })
        scrollView.mj_footer = footer
    }
    
    /// 停止刷新动画
    func endRefreshing(isHeader: Bool) {
        if isHeader {
            base.mj_header?.endRefreshing()
        }else {
            base.mj_footer?.endRefreshing()
        }
    }


    

}

/// 配合MJRefresh使用
protocol LJScrollViewRefreshDelegate: NSObject {
    
    func scrollViewLoadData(isHeadRefesh: Bool)
        
}

