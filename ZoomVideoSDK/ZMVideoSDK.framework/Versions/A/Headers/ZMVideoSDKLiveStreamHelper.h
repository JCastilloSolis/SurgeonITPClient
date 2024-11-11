
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 @brief Live stream helper interface.
 */
@interface ZMVideoSDKLiveStreamHelper : NSObject

/**
 @brief Start live stream.
 @param streamUrl The live stream url.
 @param url The live stream broadcast url.
 @param key The live stream key.
 @return If the function succeeds, it will return ZMVideoSDKErrors_Success.
 */
-(ZMVideoSDKErrors)startLiveStream:(NSString *)streamUrl   broadcastUrl:(NSString *)url  liveStreamKey:(NSString *)key;
    
/**
 @brief Stop live stream.
 @return If the function succeeds, it will return ZMVideoSDKErrors_Success.
 */
-(ZMVideoSDKErrors)stopLiveStream;
    
/**
 @brief Determine if can start living stream.
 @return If the function succeeds, it will return ZMVideoSDKErrors_Success.
 */
-(ZMVideoSDKErrors)canStartLiveStream;

@end

NS_ASSUME_NONNULL_END
