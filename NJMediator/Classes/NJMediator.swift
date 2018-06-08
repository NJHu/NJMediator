//
//  NJMediator.swift
//  NJKit
//
//  Created by HuXuPeng on 2018/6/6.
//

import UIKit

/// 组件化中间件基类
open class NJMediator: NSObject {
    public static let sharedMediator: NJMediator = NJMediator()
    private var cachedTarget: [String : NSObject] = [String : NSObject]()
}

extension NJMediator {
    
    
    /// 动态调用方法
    ///
    /// - Parameters:
    ///   - space: 模块名称
    ///   - targetName:  Target 的后半部分名称, Target_Trends: Trends
    ///   - actionName: Action_xXXXX: xXXXXX
    ///   - params: 字典
    ///   - shouldCacheTarget:  是否缓存对象
    /// - Returns: 返回成功或者失败, 或者返回对象, 或者 nil
    public func perform(nameSpace space: String, target targetName: String, action actionName: String, params: [String: AnyObject]?, shouldCacheTarget: Bool = false) -> AnyObject? {
        
        print(space)
        print(targetName)
        print(actionName)
        
        var targetObj: NSObject?
        var targetClass: NSObject.Type?
        let classString = "\(space).Target_\(targetName)"
        
        if shouldCacheTarget {
            targetObj = cachedTarget[classString]
        }
        
        if targetObj == nil {
            targetClass = NSClassFromString(classString) as? NSObject.Type
            guard let targetType = targetClass else {
                return nil
            }
            targetObj = targetType.init()
            if shouldCacheTarget, targetObj != nil {
                cachedTarget[classString] = targetObj!
            }
        }
        
        let actionSelector = NSSelectorFromString("Action_\(actionName)")
        
        guard targetObj != nil, targetObj!.responds(to: actionSelector) else {
            return nil
        }
        
        let result = targetObj?.perform(actionSelector, with: params)
        
        return result?.takeUnretainedValue();
    }
}


extension NJMediator {
    
    /// scheme://[nameSpace].[target]/[action]?[params]
    ///
    ///    url sample:
    ///    aaa://DYtrends.targetA/actionB?id=1234&cd=234
    public func perform(url actionUrl: URL, completion: ((_ result: [String: AnyObject]?) -> ())?) -> AnyObject? {
        
        let components = NSURLComponents(string: actionUrl.absoluteString)
        
        guard let host = components?.host else {
            return nil
        }
        let nameSpaceAndTraget = host.components(separatedBy: CharacterSet(charactersIn: "."))
        guard nameSpaceAndTraget.count == 2 else {
            return nil
        }
        let nameSpace = nameSpaceAndTraget[0]
        let target = nameSpaceAndTraget[1]
        
        guard let action = components?.path?.replacingOccurrences(of: "_", with: ":").replacingOccurrences(of: "/", with: "") else {
            return nil
        }
        
        var params: [String: AnyObject]?
        if let queryItems = components?.queryItems {
            params = [String: AnyObject]()
            for (index, queryItem) in queryItems.enumerated() {
                if queryItem.value != nil {
                    params?[queryItem.name] = queryItem.value! as AnyObject
                }
            }
        }
        
        let result = self.perform(nameSpace: nameSpace, target: target, action: action, params: params, shouldCacheTarget: false)
        
        if completion != nil {
            if let result = result {
                completion?(["result": result])
            } else {
                completion?(nil)
            }
        }
        
        return result
    }
}
