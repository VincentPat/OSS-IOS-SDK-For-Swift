//
//  OssUpload.swift
//  paopao
//
//  Created by 永生 黄 on 15/9/18.
//  Copyright © 2015年 永生 黄. All rights reserved.
//

import Foundation

public class OssUpload {
    
    var bucket:OSSBucket!
    var ossDownloadData:OSSData!
    var ossUploadData:OSSData!
    var ossRangeData:OSSData!
    var fileDownloadData:OSSFile!
    var fileUploadData:OSSFile!
    
    var accessKey:String!
    var secretKey:String!
    
    var downloadObjectKey:String!
    var uploadObjectKey:String!
    
    var downloadFilePath:String!
    var uploadDataPath:String!
    
    var demoBucket:String!
    var demoHostId:String
    
    var taskHandler:TaskHandler!
    
    var ossService:ALBBOSSServiceProtocol!
    
    init() {
        
        accessKey = "<yourAccessKey>"
        secretKey = "<yourSecretKey>"
        
        downloadObjectKey = "<yourDownloadObjectKey>"
        uploadObjectKey = "<yourUploadObjectKey>"
        uploadDataPath = "<yourUploadDataPath>"
        
        demoBucket = "<yourBucket>"
        demoHostId = "<yourHostId>"
        
        initOSSService()
    }
    
    // 初始化OSS服务
    func initOSSService() {
        ossService = ALBBOSSServiceProvider.getService() // 初始化
        ossService.setGlobalDefaultBucketAcl(PRIVATE)
        ossService.setGlobalDefaultBucketHostId(demoHostId as String) // 设置域名
        
        // 生成签名
        ossService.setGenerateToken { (method, md5, type, date, xoss, resource) -> String! in
            var signature:String
            let content:NSString = NSString(format: "%@\n%@\n%@\n%@\n%@%@", method, md5, type, date,xoss, resource)
            signature = OSSTool.calBase64Sha1WithData(content as String, withKey: self.secretKey as String)
            signature = NSString(format: "OSS %@:%@", self.accessKey, signature) as String
            NSLog("Signature:%@", signature)
            return signature
        }
        
        // 设置bucket
        bucket = ossService.getBucket(demoBucket)
        
        // 设置下载组件
        ossDownloadData = ossService.getOSSDataWithBucket(bucket, key: downloadObjectKey)
        
        // 设置上传组件
        ossUploadData = ossService.getOSSDataWithBucket(bucket, key: uploadObjectKey)
        
        // 设置上传数据
        let uploadData:NSData = NSData(contentsOfFile: uploadDataPath)!
        ossUploadData.setData(uploadData, withType: "<dataType>")
        ossUploadData.enableUploadCheckMd5sum(true)
        
        // 设置批量下载
        ossRangeData = ossService.getOSSDataWithBucket(bucket, key: downloadObjectKey)
        ossRangeData.setRangeFrom(10, to: 20)

        // 设置文件下载
        fileDownloadData = ossService.getOSSFileWithBucket(bucket, key: downloadObjectKey)
        
        // 设置文件上传
        fileUploadData = ossService.getOSSFileWithBucket(bucket, key: uploadObjectKey)
        fileUploadData.setPath(uploadDataPath, withContentType: "<fileType>")
    }
    
    // 开始下载
    func downloadStart() {
        self.initOSSService()
        // progressView.setProgress(0)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.taskHandler = self.ossDownloadData.getWithDataCallback({(data:NSData!, error:NSError!) in
                if error != nil {
                    print("failed")
                } else {
                    print(data.length)
                }
                }, withProgressCallback: {(progressFloat:Float) in
                    dispatch_async(dispatch_get_main_queue(), {
                        // progressView.setProgress(progressFloat)
                    })
            })
        })
    }
    
    // 取消下载
    func cancelDownload() {
        taskHandler.cancel()
    }
    
    // 开始上传
    func uploadStart() {
        self.initOSSService()
        // progressView.setProgress(0)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.taskHandler = self.ossUploadData.uploadWithUploadCallback({(isSuccess:Bool, error:NSError!) in
                if isSuccess {
                    print("success")
                } else {
                    print("failed")
                }
                }, withProgressCallback: {(progressFloat:Float) in
                    dispatch_async(dispatch_get_main_queue(), {
                        // progressView.setProgress(progressFloat)
                    })
            })
        })
    }
    
    // 取消上传
    func cancelUpload() {
        taskHandler.cancel()
    }
    
    // 显示bucket
    func listBucket() {
        self.initOSSService()
        let option:ListObjectOption = ListObjectOption()
        let result:ListObjectResult = try! bucket.listObjectsInBucket(option)
        print(result.objectList.count) // 数目
        print(result.commonPrefixList) // 列表
    }
    
    // 获取URL
    func getURL() {
        self.initOSSService()
        let url:String = ossDownloadData.getResourceURL(accessKey, andExpire: 1200)
        print(url)
    }
    
    // 批量下载
    func rangeDownload() {
        self.initOSSService()
        // progressView.setProgress(0)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.taskHandler = self.ossRangeData.getWithDataCallback({(data:NSData!, error:NSError!) in
                if error != nil {
                    print("failed")
                } else {
                    print(data.length)
                }
                }, withProgressCallback: {(progressFloat:Float) in
                    dispatch_async(dispatch_get_main_queue(), {
                        // progressView.setProgress(progressFloat)
                    })
            })
        })
    }
    
    // 同步下载
    func synDownload() {
        self.initOSSService()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let data:NSData = try! self.ossDownloadData.get()
            print(data.length)
        })
    }
    
    // 同步删除
    func synDelete() {
        self.initOSSService()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let error:NSErrorPointer = NSErrorPointer()
            self.ossUploadData.delete(error)
            if error != nil {
                print(error)
            } else {
                print("success")
            }
        })
    }
    
    // 异步删除
    func asynDelete() {
        self.initOSSService()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.ossUploadData.deleteWithDeleteCallback({(isSuccess:Bool, error:NSError!) in
                if (isSuccess) {
                   print("success")
                } else {
                    print("failed")
                }
            })
        })
    }
    
    // 同步上传
    func synUpload() {
        self.initOSSService()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let error:NSErrorPointer = NSErrorPointer()
            self.ossUploadData.upload(error)
            if error != nil {
                print(error)
            } else {
                print("success")
            }
        })
    }
    
    // 同步复制
    func synCopy() {
        self.initOSSService()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let error:NSErrorPointer = NSErrorPointer()
            self.ossUploadData.copyFromBucket(self.demoBucket, key: self.downloadObjectKey, error: error)
            if error != nil {
                print(error)
            } else {
                print("success")
            }
        })
    }
    
    // 异步复制
    func asynCopy() {
        self.initOSSService()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.ossUploadData.copyFromWithBucket(self.demoBucket, withKey: self.downloadObjectKey, withCopyCallback: {(isSuccess:Bool, error:NSError!) in
                if isSuccess {
                    print("success")
                } else {
                    print("failed")
                }
            })
        })
    }
    
    // 文件同步上传
    func fileSyncUpload() {
        self.initOSSService()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let error:NSErrorPointer = NSErrorPointer()
            self.fileUploadData.upload(error)
            if error != nil {
                print(error)
            } else {
                print("success")
            }
        })
    }
    
    // 文件异步上传
    func fileAsynUpload() {
        self.initOSSService()
        // progressView.setProgress(0)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.taskHandler = self.fileUploadData.uploadWithUploadCallback({(isSuccess:Bool, error:NSError!) in
                if isSuccess {
                    print("success")
                } else {
                    print("failed")
                }
                }, withProgressCallback: {(progressFloat:Float) in
                    dispatch_async(dispatch_get_main_queue(), {
                        // progressView.setProgress(progressFloat)
                    })
            })
        })
    }
    
    // 取消文件上传
    func cancelFileAsynUpload() {
        taskHandler.cancel()
    }
    
    // 断点续传上传
    func resumableUpload() {
        self.initOSSService()
        // progressView.setProgress(0)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.taskHandler = self.fileUploadData.resumableUploadWithCallback({(isSuccess:Bool, error:NSError!) in
                if isSuccess {
                    print("success")
                } else {
                    print("failed")
                }
                }, withProgressCallback: {(progressFloat:Float) in
                    dispatch_async(dispatch_get_main_queue(), {
                        // progressView.setProgress(progressFloat)
                    })
            })
        })
    }
    
    // 取消断点续传上传
    func cancelResumableUpload() {
        taskHandler.cancel()
    }
    
    // 断点下载
    // 暂时不支持取消
    func resumableDownload() {
        self.initOSSService()
        // progressView.setProgress(0)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.fileDownloadData.resumableDownloadTo(self.downloadFilePath, withCallback: {(isSuccess:Bool, error:NSError!) in
                if isSuccess {
                    print("success")
                } else {
                    print("failed")
                }
                }, withProgressCallback: {(progressFloat:Float) in
                    dispatch_async(dispatch_get_main_queue(), {
                        // progressView.setProgress(progressFloat)
                    })
            })
        })
    }
    
    // 文件异步下载
    func fileAsynDownload() {
        self.initOSSService()
        // progressView.setProgress(0)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.taskHandler = self.fileDownloadData.downloadTo(self.downloadFilePath, withDownloadCallback: {(isSuccess:Bool, error:NSError!) in
                if isSuccess {
                    print("success")
                } else {
                    print("failed")
                }
                }, withProgressCallback: {(progressFloat:Float) in
                    dispatch_async(dispatch_get_main_queue(), {
                        // progressView.setProgress(progressFloat)
                    })
            })
        })
    }
    
    // 文件同步下载
    func fileSynDownload() {
        self.initOSSService()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let error:NSErrorPointer = NSErrorPointer()
            self.fileDownloadData.downloadTo(self.downloadFilePath, error: error)
            if error != nil {
                print(error)
            } else {
                print("success")
            }
        })
    }
}
