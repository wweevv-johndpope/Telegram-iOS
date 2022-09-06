//
//  LJNetManager.swift
//  Wweevv
//
//  Created by panjinyong on 2021/1/15.
//

import Foundation
import CommonCrypto
import Alamofire

struct LJNetManager {
    
    typealias RequestCompletion = (_ result: LJNetManager.Result) -> ()
    
    /// Alamofire.SessionManager
    private static let sharedSessionManager: Alamofire.Session = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        let manager = Alamofire.Session(configuration: configuration)
//        manager.delegate.sessionDidReceiveChallenge = { session,challenge in
//            return    (URLSession.AuthChallengeDisposition.useCredential,URLCredential(trust:challenge.protectionSpace.serverTrust!))
//        }
        return manager
    }()
    
    
    /// 发起请求
    /// - Parameters:
    ///   - url: url
    ///   - method: method description
    ///   - bodyParameters: 请求体参数
    ///   - urlParameters: 拼接在url后面的参数
    ///   - completion: completion description
    public static func request(url: String, method: HTTPMethod, bodyParameters: Parameters? = nil, urlParameters: Parameters? = nil, completion: @escaping RequestCompletion) {
        var bodyParameters = bodyParameters
        
        var url = url
        var allParams: [String: String] = [:]
        
        if let urlParameters = urlParameters {
            url += "?"
            for (key, value) in urlParameters {
                allParams.updateValue("\(value)", forKey: key)
                url += "\(key)=\(value)&"
            }
            url = String(url.prefix(url.count - 1))
        }
        
        if let parameters = bodyParameters {
            for (key, value) in parameters {
                if let value = value as? String {
                    allParams.updateValue(value, forKey: key)
                }else if let value = value as? Int {
                    allParams.updateValue("\(value)", forKey: key)
                    bodyParameters?.updateValue("\(value)", forKey: key)
                }else if let value = value as? Bool {
                    allParams.updateValue("\(value ? "1" : "0")", forKey: key)
                    bodyParameters?.updateValue("\(value ? "1" : "0")", forKey: key)
                }else if let value = value as? Array<Any> {
                    if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: .prettyPrinted),
                       let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)?.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: " ", with: ""){
                        allParams.updateValue(jsonString, forKey: key)
                        bodyParameters?.updateValue(jsonString, forKey: key)
                    }
                }
            }
        }
        
//        let utcStr = "\(Int(Date().timeIntervalSince1970 * 1000))"
//        let signStr = sign(params: allParams, utcStr: utcStr)
//        var header = ["content-type" : "application/json",
//                      "user-agent" : "iphone",
//                      "VersionInfo": baseInfoString(),
//                      "deviceId": KeyChainStore.uuid,
//                      "nonceStr": oneceStr,
//                      "utcStr": utcStr,
//                      "sign": signStr]
//        if let token = LJUser.user.token, LJUser.user.isLogin {
//            header["token"] = token
//        }
        
        // 发起请求
        
        // 发起请求
        let request = sharedSessionManager.request( url, method: method, parameters: bodyParameters, encoding: JSONEncoding.default, headers: nil)
        
        request.responseData { response in
            switch response.result {
                case .success(let data):
                    do {
                        let asJSON = try JSONSerialization.jsonObject(with: data) as! DataResponse<Any, Error>
                        // Handle as previously success
                        self.handleNetResponseJSON(response: asJSON, completion)
                    } catch {
                        // Here, I like to keep a track of error if it occurs, and also print the response data if possible into String with UTF8 encoding
                        // I can't imagine the number of questions on SO where the error is because the API response simply not being a JSON and we end up asking for that "print", so be sure of it
//                        print("Error while decoding response: "\(error)" from: \(String(data: data, encoding: .utf8))")
                    }
                case .failure( _):
                    // Handle as previously error
                    return
                }
        }
        
    }
    
    
    /// 请求头上的基本信息
//    private static func baseInfoString() -> String {
//        let uuid = KeyChainStore.uuid
//        let appType = "0"
//        let platformType = "0"
//        let versionCode = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
//        let baseInfoDic = ["appType": appType,
//                           "uuid": uuid,
//                           "platformType": platformType,
//                           "versionCode": versionCode]
//
//        guard let baseInfoData = try? JSONSerialization.data(withJSONObject: baseInfoDic, options: []) else { return "" }
//        let baseInfoStr = String(data: baseInfoData, encoding: String.Encoding.utf8)
//        let base64String = baseInfoStr?.data(using: String.Encoding.utf8)?.base64EncodedString()
//        return base64String ?? ""
//    }
    
    
    /// 处理请求结果
    static private func handleNetResponseJSON(response: DataResponse<Any, Error>, _ completion: RequestCompletion) -> () {
        
        switch response.result {
           case .success(let value):
            if let reponseError = response.error {
                let error = Result.RequestError.netError(reponseError)
                completion(Result.failure(error))
            }else {
                let error = Result.RequestError.netError(NSError.init(domain: "Internal Server Error.", code: 500, userInfo: nil) as Error)
                completion(Result.failure(error))
            }
            
            // 如果请求头有返回token，提出来
//            if let token = response.response?.allHeaderFields["token"] as? String {
//                if var data = value["data"] as? [String: Any] {
//                    data["token"] = token
//                    value["data"] = data
//                }
//            }
            
            if let JSON = value as? [String: Any] {
                                    let status = JSON["status"] as! String
                                    print(status)
                
                if let code = JSON["code"] as? Int {
                    let data = Result.ApiData.init(JSON)
                    if code == 0 {
                        // 接口调用成功
                        completion(Result.success(data))
                    }else {
                        // 接口调用失败
                        var error = Result.RequestError.apiError(data)
                        let isHandled = self.checkError(error.apiError!)
                        if isHandled {
    //                        // 如果是经过处理会弹出提示弹窗的情况，则不显示后台返回的提示
    //                        value["message"] = ""
                            let noMessageData = Result.ApiData.init(JSON)
                            error = Result.RequestError.apiError(noMessageData)
                        }
                        completion(Result.failure(error))
                        return
                    }
                }else {
                    //服务器异常
                    let err = NSError.init(domain: "Internal Server Error", code: 500, userInfo: nil) as Error
                    let error = Result.RequestError.netError(err)
                    completion(Result.failure(error))
                }
            }
            
           
        
            
            return
        //success, do anything
           case .failure( _):
            return
        //failure
        }
        
     

       
    }
    
    /// code异常处理
    private static func checkError(_ errorData: Result.ApiData) -> Bool {
        
//        let code = errorData.code
//        guard code != 0 else { return true }
//        if code == 90000 { // token失效
//            LJUser.user.logout(isForce: true)
//            return true
//        }else if code == 90001 { // 用户在别处登录
//            LJUser.user.logout(isForce: true)
//            return true
//        }else if code == 8901 { // 账户被禁用
//            LJUser.user.logout(isForce: true)
//            return true
//        }else if code == 8902 { // 账户被注销
//            LJUser.user.logout(isForce: true)
//            return true
//        }else if code == 91000 { // 版本强制更新
//            // 版本检测
////            ALFVersionCheckManager.manager.check()
//            return true
//        }
        return false
    }
}


    

//MARK: Tool

extension LJNetManager {
    
    /// url拼接
//    private static func appendUrl(api: String) -> URL {
//        var str = "\(LJConfig.baseURL)\(api)"
//        str = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
//        return URL(string: str)!
//    }
    
    /// 随机字符串
    private static var oneceStr: String {
        get {
            let str = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
            var ret = ""
            for _ in 0..<16 {
                let start = str.index(str.startIndex, offsetBy: Int(arc4random()) % (str.count - 1))
                let end = str.index(start, offsetBy: 1)
                ret.append(contentsOf: str[start..<end])
            }
            return ret
        }
    }
    
//    /// MD5
//    private static func MD5String(str: String) -> String {
//        let cStrl = str.cString(using: String.Encoding.utf8)
//        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
//        CC_MD5(cStrl, CC_LONG(strlen(cStrl!)), buffer)
//        var md5String = ""
//        for idx in 0...15 {
//            let obcStrl = String.init(format: "%02x", buffer[idx]);
//            md5String.append(obcStrl);
//        }
//        free(buffer)
//        return md5String
//    }
//
    /// 签名
    /// - Parameters:
    ///   - params: 参数
    ///   - utcStr: 当前时间戳
    /// - Returns: 签名结果
//    private static func sign(params: [String: String], utcStr: String) -> String {
//        let oneceStr = Self.oneceStr
//        var params = params
//        params["nonceStr"] = oneceStr
//        params["utcStr"] = utcStr
//        let paramStrArray = Array(params).sorted { (a, b) -> Bool in
//            return a.key.localizedStandardCompare(b.key) == .orderedAscending
//        }.map{"\($0.key)=\($0.value)"}
//        let paramStr = paramStrArray.joined(separator: "&")
//        let key = "wweevv@technehqz@20210101@wweevv"
//        let signStr = "\(paramStr)&key=\(key)"
//        let signValue = Self.MD5String(str: signStr).uppercased()
//        return signValue
//    }

}

//MARK: - 请求结果

extension LJNetManager {
        
    /// 网络请求结果
    ///
    /// - success: 请求成功，附带返回的数据
    /// - failure: 请求失败，附带失败的数据
    public enum Result {
        
        case success(ApiData)
        
        case failure(RequestError)
        
        public var isSuccess: Bool {
            switch self {
            case .success:
                return true
            case .failure:
                return false
            }
        }
        
        public var isFailure: Bool {
            return !isSuccess
        }
        
        public var successData: ApiData? {
            switch self {
            case .success(let value):
                return value
            case .failure:
                return nil
            }
        }
        
        public var error: RequestError? {
            switch self {
            case .success:
                return nil
            case .failure(let error):
                return error
            }
        }
        
        /// 请求成功返回的字典数据
        public var successDicData: Dictionary<String, Any>? {
            if let successData = successData, let dicData = successData.data as? Dictionary<String, Any> {
                return dicData
            }
            return nil
        }
        
        /// 请求成功返回的数组数据
        public var successArrayData: Array<Any>? {
            if let successData = successData, let arrayData = successData.data as? Array<Any> {
                return arrayData
            }
            return nil
        }
        
        /// 请求完成的提示语
        public var message: String {
            var msg = "success"
            if isSuccess {
                if let successMsg = successData?.message {
                    msg = successMsg
                }
            }else if let error = error {
                if error.isApiError {
                    if let errorMsg = error.apiError?.message {
                        msg = errorMsg
                    }
                }else {
                    msg = "Unable to connect to the server."
                }
            }
            return msg
        }

        /// 网络请求错误
        ///
        /// - netError: 网络错误
        /// - apiError: 接口错误
        public enum RequestError {
            
            case netError(Error)
            
            case apiError(ApiData)
            
            public var isNetError: Bool {
                switch self {
                case .netError:
                    return true
                case .apiError:
                    return false
                }
            }
            
            public var isApiError: Bool {
                return !isNetError
            }
            
            public var netError: Error? {
                switch self {
                case .netError(let err):
                    return err
                default:
                    return nil
                }
            }
            
            public var apiError: ApiData? {
                switch self {
                case .apiError(let err):
                    return err
                default:
                    return nil
                }
            }
        }

        /// 接口返回的数据
        public struct ApiData {
            var code: Int = 0
            var message: String? = nil
            var data: Any? = nil
            var time: Double? = nil
            
            init(_ dataDic: Dictionary<String, Any> = [:]) {
                if dataDic["code"] == nil {
                    return
                }
                code = dataDic["code"] as? Int ?? 500
                message = dataDic["message"] as? String
                data = dataDic["data"]
                time = dataDic["time"] as? Double
            }
            
            /// 错误类型
            var errorType: ErrorType? {
                get {
                    if let type = ErrorType.UserRight.init(rawValue: code) {
                        return .userRight(type)
                    }else if let type = ErrorType.Other.init(rawValue: code) {
                        return .other(type)
                    }else {
                        return nil
                    }
                }
            }
            
            /// 错误类型
            enum ErrorType {
                
                /// 用户权限
                case userRight(UserRight)
                
                /// 其它
                case other(Other)
                
                /// 用户权限错误
                enum UserRight: Int {
                    /// token失效
                    case tokenInvalid = 9000
                    /// 用户在别处登录
                    case duplicateLogin = 9001
                    /// 该账号已被禁用
                    case accountDisable = 8901
                    /// 账户被注销
                    case accountRemove = 8902
                    /// 版本强制更新
                    case versionLow = 91000
                }
                
                enum Other: Int {
                    /// 兑换商品没有足够的积分或虚拟币
                    case convertProductNoSufficient = 10000
                }
                
            }

            
        }
    }
    
}
