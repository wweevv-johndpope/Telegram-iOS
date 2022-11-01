import Foundation
import UIKit
import Display
import AsyncDisplayKit
import Postbox
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import AccountContext
import SearchUI

public class WEVWatchLaterController: ViewController {
    private let context: AccountContext
    
    private var controllerNode: WEVWatchLaterControllerNode {
        return self.displayNode as! WEVWatchLaterControllerNode
    }
    
    private var _ready = Promise<Bool>()
    override public var ready: Promise<Bool> {
        return self._ready
    }
    
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    
    private var editItem: UIBarButtonItem!
    private var doneItem: UIBarButtonItem!
    
    private var previousContentOffset: ListViewVisibleContentOffset?

    
    public init(context: AccountContext) {
        self.context = context
        
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        self.editItem = UIBarButtonItem(title: self.presentationData.strings.Common_Done, style: .done, target: self, action: #selector(self.editPressed))
        self.doneItem = UIBarButtonItem(title: self.presentationData.strings.Common_Edit, style: .plain, target: self, action: #selector(self.editPressed))
        
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        
        self.title = self.presentationData.strings.WEV_WatchLater
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
        
        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).start(next: { [weak self] presentationData in
            if let strongSelf = self {
                let previousTheme = strongSelf.presentationData.theme
                let previousStrings = strongSelf.presentationData.strings
                
                strongSelf.presentationData = presentationData
                
                if previousTheme !== presentationData.theme || previousStrings !== presentationData.strings {
                    strongSelf.updateThemeAndStrings()
                }
            }
        })
        
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
    }
    
    private func updateThemeAndStrings() {
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationData: self.presentationData))
        //self.searchContentNode?.updateThemeAndPlaceholder(theme: self.presentationData.theme, placeholder: self.presentationData.strings.Common_Search)
        self.title = self.presentationData.strings.Settings_AppLanguage
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
        self.controllerNode.updatePresentationData(self.presentationData)
        
        let editItem = UIBarButtonItem(title: self.presentationData.strings.Common_Done, style: .done, target: self, action: #selector(self.editPressed))
        let doneItem = UIBarButtonItem(title: self.presentationData.strings.Common_Edit, style: .plain, target: self, action: #selector(self.editPressed))
        if self.navigationItem.rightBarButtonItem === self.editItem {
            self.navigationItem.rightBarButtonItem = editItem
        } else if self.navigationItem.rightBarButtonItem === self.doneItem {
            self.navigationItem.rightBarButtonItem = doneItem
        }
        self.editItem = editItem
        self.doneItem = doneItem
    }
    
    override public func loadDisplayNode() {
        self.displayNode = WEVWatchLaterControllerNode(context: self.context, presentationData: self.presentationData, navigationBar: self.navigationBar!, requestActivateSearch: { [weak self] in
            self?.activateSearch()
        }, requestDeactivateSearch: { [weak self] in
            self?.deactivateSearch()
        }, updateCanStartEditing: { [weak self] value in
            guard let strongSelf = self else {
                return
            }
            let item: UIBarButtonItem?
            if let value = value {
                item = value ? strongSelf.editItem : strongSelf.doneItem
            } else {
                item = nil
            }
            if strongSelf.navigationItem.rightBarButtonItem !== item {
                strongSelf.navigationItem.setRightBarButton(item, animated: true)
            }
        }, present: { [weak self] c, a in
            self?.present(c, in: .window(.root), with: a)
        }, push: { [weak self] c in
            self?.push(c)
        })
    
        /*self.controllerNode.listNode.visibleContentOffsetChanged = { [weak self] offset in
            if let strongSelf = self {
                
                var previousContentOffsetValue: CGFloat?
                if let previousContentOffset = strongSelf.previousContentOffset, case let .known(value) = previousContentOffset {
                    previousContentOffsetValue = value
                }
                switch offset {
                    case let .known(value):
                        let transition: ContainedViewLayoutTransition
                        if let previousContentOffsetValue = previousContentOffsetValue, value <= 0.0, previousContentOffsetValue > 30.0 {
                            transition = .animated(duration: 0.2, curve: .easeInOut)
                        } else {
                            transition = .immediate
                        }
                        strongSelf.navigationBar?.updateBackgroundAlpha(min(30.0, max(0.0, value - 54.0)) / 30.0, transition: transition)
                    case .unknown, .none:
                        strongSelf.navigationBar?.updateBackgroundAlpha(1.0, transition: .immediate)
                }
                
                strongSelf.previousContentOffset = offset
            }
        }*/
        
                
        self._ready.set(self.controllerNode._ready.get())
        
        self.navigationBar?.updateBackgroundAlpha(1.0, transition: .immediate)
        
        self.displayNodeDidLoad()
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.controllerNode.containerLayoutUpdated(layout, navigationBarHeight: self.cleanNavigationHeight, transition: transition)
    }
    
    @objc private func editPressed() {
        self.controllerNode.toggleEditing()
    }
    
    private func activateSearch() {
    }
    
    private func deactivateSearch() {
    }
}
