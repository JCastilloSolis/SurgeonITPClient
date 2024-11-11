//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZMVideoSDKCRCHelper : NSObject

/**
 @brief Queries if the CRC feature is enabled.
 @return YES means that the CRC is enabled, otherwise it's disabled.
 @warning  only get the correct value after joining the session.
 */
- (BOOL)isCRCEnabled;

/**
 @brief Calls the CRC device. Only available for the host/co-host.
 @param address The CRC device's IP address.
 @param callProtocol The protocol of the CRC device.
 @return If the function succeeds, it will return ZMVideoSDKErrors_Success.
 */
- (ZMVideoSDKErrors)callCRCDevice:(NSString *)address protocol:(ZMVideoSDKCRCProtocol)callProtocol;

/**
 @brief Cancels the call to the CRC device. Only available for the host/co-host.
 @return If the function succeeds, it will return ZMVideoSDKErrors_Success.
 */
- (ZMVideoSDKErrors)cancelCallCRCDevice;
@end

NS_ASSUME_NONNULL_END
