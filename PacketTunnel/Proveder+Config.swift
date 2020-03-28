//
//  Proveder+Config.swift
//  PacketTunnel
//
//  Created by 朱熙 on 2019/8/17.
//  Copyright © 2019 xizi. All rights reserved.
//

import Foundation

enum ConfigType: UInt32 {
    case IP = 0x00010000
}

extension PacketTunnelProvider {
    
    func configIP(callBack: @escaping (String, String) -> Void) {
        self.tcpConn.readLength(4, completionHandler: { (headerData, headerErr) in
            guard let count = headerData?.uint32, headerErr == nil else {
                return
            }
            guard count & ConfigType.IP.rawValue == ConfigType.IP.rawValue else {
                return
            }
            
            self.tcpConn?.readLength(8, completionHandler: { (pdata: Data?, error: Error?) in
                guard let pdata = pdata else { return }
                NSLog("ips -- \(pdata as NSData)")
                let hostData = pdata[0...3]
                let clientData = pdata[4...7]
                
                let hostIP = hostData.uint32.ipv4()
                let clientIP = clientData.uint32.ipv4()
                NSLog("host IP:\(hostIP), client IP:\(clientIP)")
                
                callBack(hostIP, clientIP)
            })
        })
    }
    
    func udpConfigIP(callBack: @escaping (String, String) -> Void) {
        self.udpConn?.setReadHandler({ (data, err) in
            guard let pdata = data?[0] else { return }
            let flag = pdata[0...3]
            guard flag.uint32 == ConfigType.IP.rawValue else { return }
            
            NSLog("ips -- \(pdata as NSData)")
            let hostData = pdata[4...7]
            let clientData = pdata[8...11]
            
            let hostIP = hostData.uint32.ipv4()
            let clientIP = clientData.uint32.ipv4()
            NSLog("host IP:\(hostIP), client IP:\(clientIP)")
            
            callBack(hostIP, clientIP)
         }, maxDatagrams: 1)
        
        self.udpConn.writeDatagram(ConfigType.IP.rawValue.data) { (error) in
            print(error)
        }
 
    }
}
