//
// Created by Evgeniy Sinev on 04/08/14.
// Copyright (c) 2014 Evgeniy Sinev. All rights reserved.
//

#import "BerHexUtil.h"
#import "BerTlvErrors.h"

static uint8_t HEX_BYTES[] = {
       // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
         99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99
/* 0 */, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99
/* 1 */, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99
/* 2 */,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 99, 99, 99, 99, 99, 99
/* 3 */, 99, 10, 11, 12, 13, 14, 15, 99, 99, 99, 99, 99, 99, 99, 99, 99
/* 4 */, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99
/* 5 */, 99, 10, 11, 12, 13, 14, 15, 99, 99, 99, 99, 99, 99, 99, 99, 99
/* 6 */, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99
};

static uint8_t HEX_BYTES_LEN = 128;
static uint8_t HEX_BYTE_SKIP = 99;


@implementation BerHexUtil

+ (NSString *)prettyFormat:(NSData *)aData {
    NSMutableString *sb = [[NSMutableString alloc] initWithCapacity:aData.length*2];
    uint8_t const *bytes = aData.bytes;
    [sb appendFormat:@"[%@]", @(aData.length)];
    for(NSUInteger i=0; i < aData.length; i++) {
        uint8_t b = bytes[i];
        [sb appendFormat:@" %02X", b];
    }
    return [sb copy];
}

+ (NSString *)format:(NSData *)aData {
    return [BerHexUtil format:aData offset:0 len:aData.length];
}

+ (NSData * _Nullable) parse:(NSString *)aHex __deprecated {
    return [self parse:aHex error:nil];
}

+ (NSData *) parse:(NSString *)aHex error:(NSError **)error {
    char const *text = [aHex cStringUsingEncoding:NSASCIIStringEncoding];
    size_t len = strnlen(text, aHex.length);

    uint8_t high = 0;
    BOOL highPassed = NO;

    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:len/2];

    for(int i=0; i< len; i++) {
        char index = text[i];

        // checks if value out of 127 (ASCII must contains from 0 to 127)
        if(index >= HEX_BYTES_LEN ) {
            continue;
        }

        uint8_t nibble = HEX_BYTES[index];

        // checks if not HEX chars
        if(nibble == HEX_BYTE_SKIP) {
            continue;
        }

        if(highPassed) {
            // fills right nibble, creates byte and adds it
            uint8_t low = (uint8_t) (nibble & 0x7f);
            highPassed = NO;
            uint8_t currentByte = ((high << 4) + low);
            [data appendBytes:&currentByte length:1];

        } else {
            // fills left nibble
            high = (uint8_t) (nibble & 0x7f);
            highPassed = YES;
        }
    }

    if(highPassed) {
        if (error) {
            *error = [BerTlvErrors invalidHexString];
        }
        return nil;
    }
    
    if ([data length] == 0) {
        if (error) {
            *error = [BerTlvErrors invalidHexString];
        }
        return nil;
    } else {
        // returns immutable
        return [data copy];
    }
}


+ (NSString *)format:(NSData *)aData offset:(uint)aOffset len:(NSUInteger)aLen {
    NSMutableString *sb = [[NSMutableString alloc] initWithCapacity:aData.length*2];
    uint8_t const *bytes = aData.bytes;
    NSUInteger max = aOffset+aLen;
    if (max <= aData.length) {
        for(NSUInteger i=aOffset; i < max; i++) {
            uint8_t b = bytes[i];
            [sb appendFormat:@"%02X", b];
        }
    }
    return [sb copy];
}

@end
