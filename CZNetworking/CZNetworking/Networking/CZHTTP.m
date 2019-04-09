//
//  CZHTTP.m
//  CZLibrary
//
//  Created by juyiwei on 2018/9/28.
//  Copyright © 2018 居祎炜. All rights reserved.
//

#import "CZHTTP.h"
#import <AFNetworking.h>

@interface CZHTTP()
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, copy) NSString *codeKey;
@property (nonatomic, copy) NSString *dataKey;
@property (nonatomic, copy) NSString *messageKey;
@end

@implementation CZHTTP

static CZHTTP *single;
+ (instancetype)manager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        single = [[CZHTTP alloc] init];
    });
    return single;
}

-(id)init {
    self = [super init];
    if (self) {
        self.codeKey = @"code";
        self.dataKey = @"data";
        self.messageKey = @"message";
        
        self.sessionManager = [[AFHTTPSessionManager alloc] init];
        self.sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        self.sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        [self.sessionManager.requestSerializer setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        self.sessionManager.responseSerializer.acceptableContentTypes = [self.sessionManager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
        self.sessionManager.responseSerializer.acceptableContentTypes = [self.sessionManager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
        
        //添加支持
        //        self.sessionManager.securityPolicy.allowInvalidCertificates = NO;
        // 证书
        //        NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"cer"];
        //        NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
        //        NSSet *cerSet = [[NSSet alloc]initWithObjects:cerData, nil];
        //        AFSecurityPolicy *securityPoliy = [AFSecurityPolicy defaultPolicy];
        //        //allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
        //        //如果是需要验证自建证书，需要设置为YES
        //        securityPoliy.allowInvalidCertificates = YES;
        //        securityPoliy.validatesDomainName = NO;
        //        //设置证书
        //        [securityPoliy setPinnedCertificates:cerSet];
        //        [self.sessionManager setSecurityPolicy:securityPoliy];
    }
    return self;
}

#pragma mark - Public

- (void)configWithResponseDataCodeKey:(NSString *)code dataKey:(NSString *)data messageKey:(NSString *)message {
    self.codeKey = code;
    self.dataKey = data;
    self.messageKey = message;
}

// 通用 post 请求处理
- (void)postWithURLString:(NSString *)URLString paramas:(NSDictionary *)paramas success:(CZHTTPBlock)success failure:(CZHTTPBlock)failure {
    NSMutableDictionary *tempParamas = [NSMutableDictionary dictionaryWithDictionary:self.commonParams];
    [tempParamas addEntriesFromDictionary:paramas];
    NSLog(@"POST 请求 %@?%@", URLString, [self urlEncodeWithParamas:paramas]);
    [self.sessionManager POST:URLString parameters:tempParamas progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self processResponse:responseObject task:task success:success failure:failure];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self processResponse:task.response task:task success:success failure:failure];
    }];
}

// 通用 get 请求处理
- (void)getWithURLString:(NSString *)URLString paramas:(NSDictionary *)paramas success:(CZHTTPBlock)success failure:(CZHTTPBlock)failure {
    NSMutableDictionary *tempParamas = [NSMutableDictionary dictionaryWithDictionary:self.commonParams];
    [tempParamas addEntriesFromDictionary:paramas];
    NSLog(@"GET 请求 %@?%@", URLString, [self urlEncodeWithParamas:paramas]);
    [self.sessionManager GET:URLString parameters:tempParamas progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self processResponse:responseObject task:task success:success failure:failure];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self processResponse:task.response task:task success:success failure:failure];
    }];
}

#pragma mark - Private

// 通用处理返回数据
-(void)processResponse:(id)response task:(NSURLSessionDataTask *)task success:(void(^)(NSURLSessionDataTask *task,id response))success failure:(void(^)(NSURLSessionDataTask *task,id response))failure {
    if (task.error.code) {
        NSString *code = [NSString stringWithFormat:@"%@", @(task.error.code)];
        NSLog(@"请求错误：code:%@, msg:%@",code, task.error.localizedDescription);
        if (failure) { failure(task,@{self.codeKey:code, self.messageKey:task.error.localizedDescription}); }
        
    } else {
        NSDictionary *responseDic = (NSDictionary *)response;
        if ([responseDic isKindOfClass:[NSDictionary class]]) {
            id errcode = responseDic[self.codeKey];
            
            if (([errcode isKindOfClass:[NSString class]] && [((NSString *)errcode) isEqualToString:@"0"]) ||
                ([errcode isKindOfClass:[NSNumber class]] && ((NSNumber *)errcode).integerValue == 0)) {
                if (success) { success(task, responseDic[self.dataKey]); }
                
            } else {
                NSString *errMsg = responseDic[self.messageKey];
                if (![errMsg isKindOfClass:[NSString class]]) {
                    errMsg = @"操作失败";
                }
                NSLog(@"操作失败：msg:%@", errMsg);
                if (failure) { failure(task, @{self.codeKey:@"401", self.messageKey:errMsg}); }
            }
            
        } else {
            NSLog(@"请求错误：msg:返回数据结构不正确");
            if (failure) { failure(task, @{self.codeKey:@"500", self.messageKey:@"网络通信错误"}); }
        }
    }
}

// 参数 Url 编码
- (NSString *)urlEncodeWithParamas:(NSDictionary *)paramas {
    NSMutableArray *arrayM = [NSMutableArray array];
    [paramas enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [arrayM addObject:[NSString stringWithFormat:@"%@=%@", key, obj]];
    }];
    NSString *paramaString = [arrayM componentsJoinedByString:@"&"];
    
    return paramaString;
}


@end
