//
//  Communicator.m
//
//  Created by Jonatan Yde
//  Based on code by by Roger Jungemann
//
//

#import "Communicator.h"



@implementation Communicator

@synthesize delegate;

-(void)sendMessage:(NSString *)msg {

    //NSString *response  = [NSString stringWithFormat:@"msg:%@", msg];
    
    NSData *data = [[NSData alloc] initWithData:[msg dataUsingEncoding:NSASCIIStringEncoding]];
    [outputStream write:[data bytes] maxLength:[data length]];

}

-(void)sendData:(NSData *)data {
    
    NSUInteger dataSize = data.length;
    NSLog(@"Data size: %lu", dataSize);
    long value = htonl(dataSize);
    NSData *sizePacket = [NSData dataWithBytes: &value length: sizeof(value)];
    [outputStream write: [sizePacket bytes]  maxLength: sizePacket.length];
    
    if (dataSize > 0)
    {
        //uint8_t buffer[1024];
        int buffer = 1024;
        int index = 0;
        do
        {
            size_t num = MIN(dataSize, buffer);
            NSData *partToWrite = [data subdataWithRange:NSMakeRange(index, num)];
            if (num < 1)
                return;
            if (![outputStream write: [partToWrite bytes] maxLength:num])
                return;
            dataSize -= num;
            index +=buffer;
            //NSLog(@"index: %i", index);
        }
        while (dataSize > 0);
    }
    
    //[outputStream write:[data bytes] maxLength:[data length]];
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {

    NSLog(@"stream event %lu", (unsigned long)streamEvent);

    switch (streamEvent) {

        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened");
            NSLog(@"Connected");
            break;
        case NSStreamEventHasBytesAvailable:

            if (theStream == inputStream)
            {
                uint8_t buffer[1024];
                NSInteger len;

                while ([inputStream hasBytesAvailable])
                {
                    len = [inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0)
                    {
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];

                        if (nil != output)
                        {
                            if([delegate respondsToSelector:@selector(didRecieveMessage:)])
                            {
                                [delegate didRecieveMessage:output];
                            }
                            [self messageReceived:output];
                        }
                    }
                }
            }
            break;

        case NSStreamEventHasSpaceAvailable:
            NSLog(@"Stream has space available now");
            break;

        case NSStreamEventErrorOccurred:
             NSLog(@"%@",[theStream streamError].localizedDescription);
            break;

        case NSStreamEventEndEncountered:

            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            NSLog(@"Disconnected");
            NSLog(@"close stream");
            break;
        default:
            NSLog(@"Unknown event");
    }

}

- (void)connectToServer:(NSString *)server onPort:(uint32_t) port{

    NSLog(@"Setting up connection to %@ : %i", server, port);
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef) server, port, &readStream, &writeStream);

    messages = [[NSMutableArray alloc] init];

    [self open];
}

-(BOOL)isConnected
{
    if(!inputStream && !outputStream)
        return false;
    
    return true;
}

- (void)close {
    NSLog(@"Closing streams.");
    [inputStream close];
    [outputStream close];
    [inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream setDelegate:nil];
    [outputStream setDelegate:nil];
    inputStream = nil;
    outputStream = nil;

    NSLog(@"Disconnected");
}


- (void)open {

    NSLog(@"Opening streams.");

    outputStream = (__bridge NSOutputStream *)writeStream;
    inputStream = (__bridge NSInputStream *)readStream;

    [outputStream setDelegate:self];
    [inputStream setDelegate:self];

    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    [outputStream open];
    [inputStream open];

    NSLog(@"Connected");
}


- (void) messageReceived:(NSString *)message {
    [messages addObject:message];
    //NSLog(@"%@", message);
}

-(NSMutableArray *)messages
{
    return messages;
}


@end
