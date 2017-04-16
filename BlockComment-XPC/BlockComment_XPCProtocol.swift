//
//  BlockComment_XPCProtocol.h
//  BlockComment-XPC
//
//  Created by Brad Howes on 4/16/17.
//  Copyright © 2017 Brad Howes. All rights reserved.
//

import Foundation

@objc public protocol BlockComment_XPCProtocol {
    func uppercase(_ string: String, withReply: (String)->())
}
