//
//  LJDebugTool.swift
//  Peach
//
//  Created by panjinyong on 2021/6/17.
//  Copyright © 2021 techne. All rights reserved.
//

import UIKit

class LJDebugTool: NSObject {
    /// 日志变化回调
    typealias CurrentLogDidChanged = (LJDebugLogModel) -> ()
    
    public static let share = LJDebugTool()
    
    /// 当前日志
    private(set) lazy var currentLog: LJDebugLogModel = {
        let date = Date()
        return LJDebugLogModel.init(logId: "\(Int(date.timeIntervalSince1970 * 1000))", createDate: date, fileName: "\(Int(date.timeIntervalSince1970 * 1000)).txt")
    }()
    
    /// 所有历史日志
    private(set) lazy var historyLogArray: [LJDebugLogModel] = {
        loadLogList()?.sorted(by: {$0.createDate.timeIntervalSince1970 > $1.createDate.timeIntervalSince1970}) ?? []
    }()
            
    /// 日志变化回调集合 key: hash
    private var currentLogDidChangedDic: [Int: CurrentLogDidChanged] = [:]

    override init() {
        super.init()
        addObserver()
        addCrashObserver()
    }

    //MARK: - UI

    /// 显示日志按键
    fileprivate lazy var logButton: UIWindow = {
        let window = UIWindow()
        window.rootViewController = UIViewController()
        window.windowLevel = UIWindow.Level.init(UIWindow.Level.alert.rawValue + 10)
        window.backgroundColor = .red
        window.alpha = 0.5
        window.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(logButtonAction)))
        window.addGestureRecognizer(UIPanGestureRecognizer.init(target: self, action: #selector(panAction(pan:))))
        return window
    }()
    
    /// 日志显示背景
    private lazy var logWindow: UIWindow = {
        let window = UIWindow()
        window.backgroundColor = .white
        window.rootViewController = UINavigationController.init(rootViewController: LJLogViewController())
        window.frame = UIScreen.main.bounds
        window.windowLevel = UIWindow.Level.init(UIWindow.Level.alert.rawValue + 9)
        return window
    }()
    
    @objc private func logButtonAction() {
        logWindow.isHidden = !logWindow.isHidden
    }
    
    @objc private func panAction(pan: UIPanGestureRecognizer) {
//        guard let superview = logButton.superviewx else { return }
        let translation = pan.translation(in: logButton)
        var frame = logButton.frame
        var newX = frame.origin.x + translation.x
        if newX < 0 {
            newX = 0
        }else if newX + frame.width > LJScreen.width {
            newX = LJScreen.width - frame.width
        }
        var newY = frame.origin.y + translation.y
        if newY < 0 {
            newY = 0
        }else if newY + frame.height > LJScreen.height {
            newY = LJScreen.height - frame.height
        }
        frame.origin.x = newX
        frame.origin.y = newY
        logButton.frame = frame
        pan.setTranslation(.zero, in: logButton)
    }
    
    //MARK: - Public
    
    /// 启动
    public func launch() {
        logButton.frame = CGRect(x: LJScreen.width - 100, y: LJScreen.height - 100, width: 40, height: 40)
        logButton.isHidden = false
    }
            
    /// 拼接日志
    /// - Parameters:
    ///   - log: 日志
    ///   - isCrash: 是否崩溃日志
    public func appendLog(_ log: String, isCrash: Bool = false) {
        self.currentLog.text.append("\n-------------------------\n\(log)")
        self.currentLog.isCrash = isCrash
        DispatchQueue.main.async {
            self.currentLogDidChangedDic.values.forEach{$0(self.currentLog)}
        }
    }
    
    /// 添加当前日志监听
    /// - Parameters:
    ///   - listener: 监听者
    ///   - currentLogDidChanged: 监听回调
    /// - Returns: description
    public func addCurrentLogListener(_ listener: NSObjectProtocol, currentLogDidChanged: @escaping CurrentLogDidChanged) {
        self.currentLogDidChangedDic[listener.hash] = currentLogDidChanged
    }
    
    /// 移除当前日志监听
    /// - Parameter listener: 监听者
    public func removeCurrentLogListener(_ listener: NSObjectProtocol) {
        self.currentLogDidChangedDic.removeValue(forKey: listener.hash)
    }

}

//MARK: - 日志的保存、删除

extension LJDebugTool {
    /// 保存日志的文件夹
    public static let logCachesDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first?.appending("/ljDebugLog") ?? ""
    
    /// 保存日志
    private func saveCurrentLog() {
        if !FileManager.default.fileExists(atPath: LJDebugTool.logCachesDirectory) {
            do {
                try FileManager.default.createDirectory(atPath: LJDebugTool.logCachesDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
                return
            }
        }
        do {
            let data = try JSONEncoder.init().encode(currentLog)
            try data.write(to: URL.init(fileURLWithPath: "\(LJDebugTool.logCachesDirectory)/\(currentLog.fileName)"))
        } catch {
            print(error)
        }
    }
    
    /// 获取所有日志
    /// - Returns: 日志
    private func loadLogList() -> [LJDebugLogModel]? {
        do {
            var logArray: [LJDebugLogModel] = []
            let fileList = try FileManager.default.contentsOfDirectory(atPath: LJDebugTool.logCachesDirectory)
            fileList.forEach { (file) in
                let url = URL.init(fileURLWithPath: "\(LJDebugTool.logCachesDirectory)/\(file)")
                do {
                    let data = try Data.init(contentsOf: url)
                    let logModel = try JSONDecoder.init().decode(LJDebugLogModel.self, from: data)
                    logArray.append(logModel)
                }catch {
                    print(error)
                }
            }
            return logArray
        } catch {
            print(error)
            return nil
        }
    }
    
    //MARK: Public 清除所有日志

    /// 清除所有日志
    /// - Returns: 结果
    @discardableResult
    public func clearAllLog() -> Bool {
        do {
            try FileManager.default.removeItem(atPath: LJDebugTool.logCachesDirectory)
            self.historyLogArray.removeAll()
            return true
        } catch {
            print(error)
            return false
        }
    }
    
}

//MARK: - 通知监听

extension LJDebugTool {
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeKeyNotification), name: UIWindow.didBecomeKeyNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    @objc private func didBecomeKeyNotification() {
        if UIWindow.key == logButton {
            // 不让浮窗成为keyWindow
            logButton.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {[weak self] in
                guard let self = self else {return}
                self.logButton.isHidden = false
            }
        }
    }
    
    @objc private func appWillTerminate() {
        saveCurrentLog()
    }
}

//MARK: - 奔溃监听

extension LJDebugTool {
    
    /// 设置奔溃监听
    private func addCrashObserver() {
        NSSetUncaughtExceptionHandler { (exception) in
            let arr = exception.callStackSymbols
            let reason = exception.reason ?? ""
            let name = exception.name.rawValue
            let crash = "\r\n\r\n name:\(name) \r\n reason:\(String(describing: reason)) \r\n \(arr.joined(separator: "\r\n")) \r\n\r\n"
            LJDebugTool.share.appendLog(crash, isCrash: true)
            LJDebugTool.share.saveCurrentLog()
        }
        
        func signalExceptionHandler(signal:Int32) {
            LJDebugTool.share.appendLog(Thread.callStackSymbols.joined(separator: "\n"), isCrash: true)
            LJDebugTool.share.saveCurrentLog()
            exit(signal)
        }
        
        signal(SIGABRT, signalExceptionHandler)
        signal(SIGSEGV, signalExceptionHandler)
        signal(SIGBUS, signalExceptionHandler)
        signal(SIGTRAP, signalExceptionHandler)
        signal(SIGILL, signalExceptionHandler)
        signal(SIGHUP, signalExceptionHandler)
        signal(SIGINT, signalExceptionHandler)
        signal(SIGQUIT, signalExceptionHandler)
        signal(SIGFPE, signalExceptionHandler)
        signal(SIGPIPE, signalExceptionHandler)
    }
    
}
