import Foundation
import UIKit
import Display
import AsyncDisplayKit
import Postbox
import TelegramCore
import SwiftSignalKit
import TelegramPresentationData
import MergeLists
import ItemListUI
import PresentationDataUtils
import AccountContext
import ShareController
import SearchBarNode
import SearchUI
import UndoUI
import TelegramUIPreferences
import TranslateUI
import ContactListUI
import PostgREST

final class WEVPointsControllerNode: ViewControllerTracingNode {
    private let context: AccountContext
    private var presentationData: PresentationData
    private weak var navigationBar: NavigationBar?
    private let requestActivateSearch: () -> Void
    private let requestDeactivateSearch: () -> Void
    private let present: (ViewController, Any?) -> Void
    private let push: (ViewController) -> Void
    
    private var didSetReady = false
    let _ready = ValuePromise<Bool>()
    
    private var containerLayout: (ContainerViewLayout, CGFloat)?
    private let presentationDataValue = Promise<PresentationData>()
    private let isEditing = ValuePromise<Bool>(false)
    private var nodeView = UIView(frame: .zero)
    private var currentLayout: CGSize = .zero
    private var client: PostgrestClient?
    private var descLabel = UILabel(frame: .zero)
    private let controller: WEVPointsController?
    private var isEditingValue: Bool = false {
        didSet {
            self.isEditing.set(self.isEditingValue)
        }
    }
    
    init(context: AccountContext, presentationData: PresentationData, navigationBar: NavigationBar, controller: WEVPointsController, requestActivateSearch: @escaping () -> Void, requestDeactivateSearch: @escaping () -> Void, updateCanStartEditing: @escaping (Bool?) -> Void, present: @escaping (ViewController, Any?) -> Void, push: @escaping (ViewController) -> Void) {
        self.context = context
        self.presentationData = presentationData
        self.presentationDataValue.set(.single(presentationData))
        self.navigationBar = navigationBar
        self.controller = controller
        self.requestActivateSearch = requestActivateSearch
        self.requestDeactivateSearch = requestDeactivateSearch
        self.present = present
        self.push = push
        super.init()
        
        self.backgroundColor = presentationData.theme.list.blocksBackgroundColor
    }
    
    deinit {
    }
    
    func updatePresentationData(_ presentationData: PresentationData) {
        self.presentationData = presentationData
        self.presentationDataValue.set(.single(presentationData))
        self.backgroundColor = presentationData.theme.list.blocksBackgroundColor
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        let hadValidLayout = self.containerLayout != nil
        self.containerLayout = (layout, navigationBarHeight)
        
        if !hadValidLayout {
            self.dequeueTransitions(navigationBarHeight: navigationBarHeight)
        } else {
            if self.currentLayout != layout.size {
                self.updateConstriant(navigationBarHeight: navigationBarHeight)
            }
        }
        self.currentLayout = layout.size
    }
    
    private func dequeueTransitions(navigationBarHeight: CGFloat) {
        guard let _ = self.containerLayout else {
            return
        }
        
        if !self.didSetReady {
            self.didSetReady = true
            self._ready.set(true)
            //set postgress client
            client = PostgrestClient(
                url: "\(LJConfig.SupabaseKeys.supabaseUrlDev)/rest/v1",
                headers: ["apikey": LJConfig.SupabaseKeys.supabaseKeyDev],
                schema: "public")
            //get user Data and set referral code
            self.doGetUserData()
            self.initView(navigationBarHeight: navigationBarHeight)
        }
    }
    
    private func updateConstriant(navigationBarHeight: CGFloat) {
            nodeView.snp.remakeConstraints { (make) in
                make.top.equalToSuperview().offset(navigationBarHeight)
                make.left.bottom.right.equalToSuperview()
            }
        }

    func toggleEditing() {
        self.isEditingValue = !self.isEditingValue
    }
    
    private func initView(navigationBarHeight: CGFloat) {
        
        let shareView =  ASDisplayNode { () -> UIView in
            return self.nodeView
        }
        self.addSubnode(shareView)
        self.nodeView.backgroundColor = .clear
        nodeView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(navigationBarHeight)
            make.bottom.left.right.equalToSuperview()
        }
        
        
        let scrollView = UIScrollView()
        self.nodeView.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()//.offset(LJScreen.navigationBarHeight)
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
        }

        let containView = UIView()
        scrollView.addSubview(containView)
        containView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.width.equalTo(view)
        }
            
        let imageView = UIImageView(image: UIImage.init(named: "rewards_wallet_point"))
        containView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(20)
            make.size.equalTo(CGSize(width: 80, height: 67))
            make.centerX.equalToSuperview()
        }
        
        descLabel = UILabel.lj.configure(font: LJFont.medium(32 * LJScreen.scaleWidthOfIX), textColor: presentationData.theme.list.itemPrimaryTextColor, text: "0")
        descLabel.lj.setLineSpacing()
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        containView.addSubview(descLabel)
        descLabel.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        
        let youCode = UILabel.lj.configure(font: LJFont.medium(16), textColor: presentationData.theme.list.itemSecondaryTextColor, text: "My Wweevv points")
        containView.addSubview(youCode)
        youCode.snp.makeConstraints { (make) in
            make.top.equalTo(descLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        
        let button = UIButton.init(type: .custom)
        button.titleLabel?.font = LJFont.medium(16)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        let att = NSAttributedString.init(string: "How to gain?", attributes: [NSAttributedString.Key.foregroundColor : UIColor(red: 191/255, green: 48/255, blue: 113/255, alpha: 1), .font: LJFont.medium(16), .underlineStyle: NSNumber.init(value: 1)])
        button.setAttributedTitle(att, for: .normal)
        containView.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.top.equalTo(youCode.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
            make.height.equalTo(30)
        }
        
        
        let imgBubble = UIImageView(image: UIImage.init(named: "wallet_bubble"))
        containView.insertSubview(imgBubble, belowSubview: button)
        imgBubble.snp.makeConstraints { (make) in
            make.top.equalTo(button.snp.bottom).offset(-10)
            make.size.equalTo(CGSize(width: 161, height: 166))
            make.centerX.equalToSuperview()
        }
        
        let imgPeople = UIImageView(image: UIImage.init(named: "wallet_clap_icon"))
        containView.addSubview(imgPeople)
        imgPeople.snp.makeConstraints { (make) in
            make.top.equalTo(imgBubble.snp.bottom).offset(-10)
            make.size.equalTo(CGSize(width: 220, height: 161))
            make.centerX.equalToSuperview()
        }
        
        
        let codeBgView: UIView = {
            let codeBgView = UIView()
            codeBgView.backgroundColor =  presentationData.theme.rootController.tabBar.backgroundColor
            codeBgView.layer.cornerRadius = 16
           
            let descLabel = UILabel.lj.configure(font: LJFont.medium(16), textColor: UIColor(red: 0, green: 122/255, blue: 1, alpha: 1), text: "Invite your froends and earn up to 3000 points.")
            descLabel.lj.setLineSpacing()
            descLabel.textAlignment = .center
            descLabel.numberOfLines = 0
            codeBgView.addSubview(descLabel)
            descLabel.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(30)
                make.left.equalToSuperview().offset(15)
                make.right.equalToSuperview().offset(-15)
                make.bottom.equalToSuperview().offset(-50)
            }
            return codeBgView
        }()
        
        containView.addSubview(codeBgView)
        codeBgView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-30)
            make.top.equalTo(imgPeople.snp.bottom).offset(-10)
        }
        
        let shareButton = UIButton.lj.configure(font: LJFont.medium(14), titleColor: .white, backgroundColor: UIColor(red: 191/255, green: 48/255, blue: 113/255, alpha: 1), title: "Find out more")
        shareButton.addTarget(self, action: #selector(shareButtonAction), for: .touchUpInside)
        containView.addSubview(shareButton)
        shareButton.snp.makeConstraints { (make) in
            make.top.equalTo(codeBgView.snp.bottom).offset(-20)
            make.width.equalTo((LJScreen.width * 220) / 375)
            make.height.equalTo(40)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-LJScreen.safeAreaBottomHeight)
        }
    }
    
    @objc private func buttonAction() {
        let alert = UIAlertController.init(title: "How to gain?", message: "Wweevv points are earned every time you watch a live video and when inviting friends.", preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))
        self.controller?.present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Action

    @objc private func shareButtonAction() {
        guard let navController = self.controller?.navigationController else {
            return
        }
        navController.pushViewController(WEVShareEarnController(context: self.context), animated: true)
    }
}

extension WEVPointsControllerNode {
    
    func doGetUserData() {
        Task {
            await getUserData()
        }
    }
    
    func getUserData() async {
        //check client is not a nil
        guard let client = client else {
            return
        }
        
        do {
            let currentUser = try await client
               .from("fetch_pointscount_view")
           .select()
           .eq(column: "user_id", value: "\(self.context.account.peerId.id._internalGetInt64Value())")
           .execute()
           .decoded(to: [UserPoints].self).first
            
            DispatchQueue.main.async {
                self.descLabel.text = "\(currentUser?.points ?? 0)"
            }
            
        } catch {
            print(error.localizedDescription)
        }
    }
}
