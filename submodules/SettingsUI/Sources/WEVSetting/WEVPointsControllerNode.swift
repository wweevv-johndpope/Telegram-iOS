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

final class WEVShareEarnControllerNode: ViewControllerTracingNode {
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

    private var isEditingValue: Bool = false {
        didSet {
            self.isEditing.set(self.isEditingValue)
        }
    }
    
    init(context: AccountContext, presentationData: PresentationData, navigationBar: NavigationBar, requestActivateSearch: @escaping () -> Void, requestDeactivateSearch: @escaping () -> Void, updateCanStartEditing: @escaping (Bool?) -> Void, present: @escaping (ViewController, Any?) -> Void, push: @escaping (ViewController) -> Void) {
        self.context = context
        self.presentationData = presentationData
        self.presentationDataValue.set(.single(presentationData))
        self.navigationBar = navigationBar
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
    
    private lazy var inviteCodeLabel: UILabel = {
        let view = UILabel.lj.configure(font: LJFont.medium(28 * LJScreen.scaleWidthLessOfIX), textColor: LJColor.black)
        view.textAlignment = .center
        return view
    }()
    
    /// 编辑按键
    private lazy var inviteCodeEditButton: UIButton = {
        let view = UIButton.init(type: .custom)
        view.setImage(UIImage.init(named: "share_invite_code_edit"), for: .normal)
        view.addTarget(self, action: #selector(editButtonAction), for: .touchUpInside)
        view.isHidden = true
        return view
    }()
    
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
        
        
        let shareButton = UIButton.lj.configure(title: "Share my code", fontSize: 14)
        shareButton.addTarget(self, action: #selector(shareButtonAction), for: .touchUpInside)
        //view.addSubview(shareButton)
        //Filter view to select channel
        /*let shareButtonNode =  ASDisplayNode { () -> UIView in
            return shareButton
        }*/
        self.nodeView.addSubview(shareButton)
        shareButton.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-LJScreen.safeAreaBottomHeight - 8)
            make.width.equalTo(LJScreen.width * 0.9)
            make.centerX.equalToSuperview()
            make.height.equalTo(48)
        }
        
        let scrollView = UIScrollView()
        //view.addSubview(scrollView)
        /*let scrollViewNode =  ASDisplayNode { () -> UIView in
            return scrollView
        }*/
        self.nodeView.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()//.offset(LJScreen.navigationBarHeight)
            make.bottom.equalTo(shareButton.snp.top).offset(-30)
            make.left.right.equalToSuperview()
        }

        let containView = UIView()
        scrollView.addSubview(containView)
        containView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.width.equalTo(view)
        }
        
        let imageView = UIImageView(image: UIImage.init(named: "share_invite_contact_bg"))
        containView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(16)
            make.size.equalTo(CGSize(width: 243, height: 194))
            make.centerX.equalToSuperview()
        }
        
        let codeBgView: UIView = {
            let codeBgView = UIView()
            codeBgView.backgroundColor = .clear //LJColor.hex(0xEFF0F2, 0.79)
            codeBgView.layer.cornerRadius = 16
           
            let descLabel = UILabel.lj.configure(font: LJFont.regular(14), textColor: presentationData.theme.list.itemPrimaryTextColor, text: "Share your code with a friend. When they use it to register to Wweevv you will earn points!\nThe more you refer, the better the points.")
            descLabel.lj.setLineSpacing()
            descLabel.textAlignment = .center
            descLabel.numberOfLines = 0
            codeBgView.addSubview(descLabel)
            descLabel.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(24)
                make.left.equalToSuperview().offset(15)
                make.right.equalToSuperview().offset(-15)
            }
            let youCode = UILabel.lj.configure(font: LJFont.medium(16), textColor: presentationData.theme.list.itemPrimaryTextColor, text: "Your code")
            codeBgView.addSubview(youCode)
            youCode.snp.makeConstraints { (make) in
                make.top.equalTo(descLabel.snp.bottom).offset(24)
                make.centerX.equalToSuperview()
            }
            
            let codeImageBgView: UIImageView = {
                let imageView = UIImageView(image: UIImage.init(named: "share_invite_code_bg"))
                imageView.addSubview(inviteCodeLabel)
                imageView.isUserInteractionEnabled = true
                inviteCodeLabel.snp.makeConstraints { (make) in
                    make.center.equalToSuperview()
                }
                
                imageView.addSubview(inviteCodeEditButton)
                inviteCodeEditButton.snp.makeConstraints { (make) in
                    make.left.equalTo(inviteCodeLabel.snp.right).offset(0)
                    make.size.equalTo(CGSize(width: 40, height: 40))
                    make.centerY.equalToSuperview()
                }
                return imageView
            }()
            
            codeBgView.addSubview(codeImageBgView)
            codeImageBgView.snp.makeConstraints { (make) in
                make.top.equalTo(youCode.snp.bottom).offset(12)
                //make.left.equalToSuperview().offset(24)
                //make.right.bottom.equalToSuperview().offset(-24)
                make.bottom.equalToSuperview().offset(-24)
                make.width.equalTo(LJScreen.width * 0.8)
                make.centerX.equalToSuperview()
                make.height.equalTo(64)
            }
            return codeBgView
        }()
        
        containView.addSubview(codeBgView)
        codeBgView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.top.equalTo(imageView.snp.bottom).offset(32)
        }
        
        let descPointLabel = UILabel.lj.configure(font: LJFont.regular(12), textColor: presentationData.theme.list.itemPrimaryTextColor, text: "1 invite = 2 points, 10 invites = 25 points, 50 invites = 200 points, 100 invites = 500 points and 250 invites = 3,000 points!")
        descPointLabel.lj.setLineSpacing()
        descPointLabel.textAlignment = .center
        descPointLabel.numberOfLines = 0
        containView.addSubview(descPointLabel)
        descPointLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.top.equalTo(codeBgView.snp.bottom).offset(24)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    private func updateView(code: String) {
        inviteCodeLabel.text = code //LJUser.user.inviteCode
        inviteCodeEditButton.isHidden = true //LJUser.user.editInviteCode
    }
    
    //MARK: - Action

    @objc private func shareButtonAction() {
        /*MBProgressHUD.showAdded(to: self.view, animated: true)
        WEVShareManager.manger.shareApp(from: self) {[weak self] (isSuccess) in
            guard let self = self else {return}
            MBProgressHUD.hide(for: self.view, animated: true)
        }*/
    }
    
    weak var editAlertAction: UIAlertAction?
    
    /// 点击编辑按键
    @objc private func editButtonAction() {
        /*let alert = UIAlertController.init(title: "Please note that each account is only allowed to edit the Referral code once.", message: nil, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: { (_) in
            self.showEditInviteCodeAlert(code: LJUser.user.inviteCode)
        }))
        present(alert, animated: true, completion: nil)*/
    }
    
    /// 显示编辑弹窗
    /// - Parameter code: 已经填写的邀请码
    private func showEditInviteCodeAlert(code: String?) {
        /*let editAlert = UIAlertController.init(title: "Referral Code", message: nil, preferredStyle: .alert)
        editAlert.addTextField { (textField) in
            textField.textColor = LJColor.hex(0x141419)
            textField.font = LJFont.regular(13)
            textField.addTarget(self, action: #selector(self.textFieldDidChanged(_:)), for: .editingChanged)
            textField.text = code
        }
        let editAction = UIAlertAction.init(title: "Save", style: .default, handler: {[weak editAlert] (_) in
            guard let code = editAlert?.textFields?.first?.text else {return}
            self.editInvieteCodeRequest(code) { (isSuccess) in
                if !isSuccess {
                    // 修改接口失败，重新显示旧的弹窗
                    self.showEditInviteCodeAlert(code: code)
                }
            }
        })
        editAlert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        editAlert.addAction(editAction)
        editAlertAction = editAction
        present(editAlert, animated: true, completion: nil)
        checkEditingInviteCode(code ?? "")*/
    }
    
    @objc private func textFieldDidChanged(_ textField: UITextField) {
        guard let text = textField.text else { return }
        let max = 10
        if text.count > max {
            textField.text = String(text.prefix(max))
        }
        checkEditingInviteCode(text)
    }
    
    @discardableResult
    private func checkEditingInviteCode(_ code: String) -> Bool {
        let min = 4
        let isEnabled = code.count >= min
        editAlertAction?.isEnabled = isEnabled
        return isEnabled
    }
    
    //MARK: - Request
    
    /// 更改邀请码请求
    private func editInvieteCodeRequest(_ code: String, completion: @escaping (Bool) -> ()) {
        /*MBProgressHUD.showAdded(to: self.view, animated: true)
        LJNetManager.Profile.editInviteCode(inviteCode: code) {[weak self] (result) in
            guard let self = self else {return}
            MBProgressHUD.hide(for: self.view, animated: true)
            if result.isSuccess {
                LJUser.user.inviteCode = code
                LJUser.user.editInviteCode = true
                LJUser.user.saveLocalData()
                self.updateView()
            }else {
                MBProgressHUD.lj.showHint(result.message)
            }
            completion(result.isSuccess)
        }*/
    }

}

extension WEVShareEarnControllerNode {
    
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
               .from("user")
           .select()
           .eq(column: "user_id", value: "\(self.context.account.peerId.id._internalGetInt64Value())")
           .execute()
           .decoded(to: [WevUser].self).first

            guard let code = currentUser?.referralcode else {
                return
            }
            //Set referral code
            DispatchQueue.main.async {
                self.updateView(code: code)
            }
            
        } catch {
            print(error.localizedDescription)
        }
    }
}
