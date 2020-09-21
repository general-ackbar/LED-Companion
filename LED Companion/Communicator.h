//
//  Communicator.h
//
//  Created by Jonatan Yde
//  Based on code by by Roger Jungemann
//

#import <Foundation/Foundation.h>

@protocol MessageDelegate <NSObject>

-(void)didRecieveMessage:(NSString *)message;

@end


@interface Communicator : NSObject <NSStreamDelegate> {

    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;

    NSInputStream   *inputStream;
    NSOutputStream  *outputStream;

    NSMutableArray  *messages;
}

@property(nonatomic, weak) id<MessageDelegate> delegate;

- (void)connectToServer:(NSString *)server onPort:(uint32_t) port;
- (void)open;
- (void)close;
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent;
- (void) messageReceived:(NSString *)message;
-(void)sendMessage:(NSString *)msg;
-(void)sendData:(NSData *)data;
-(BOOL)isConnected;
@end
