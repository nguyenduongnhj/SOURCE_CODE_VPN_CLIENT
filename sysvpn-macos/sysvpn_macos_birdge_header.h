//
//  sysvpn_macos_birdge_header.h
//  sysvpn-macos
//
//  Created by macbook on 17/10/2022.
//

#ifndef sysvpn_macos_birdge_header_h
#define sysvpn_macos_birdge_header_h
    #include "VPNCore/IPC/AuditTokenGetter.h" 
    #include "define.h"
    #include <ifaddrs.h>
    #include <openssl/bio.h>
    #include <openssl/err.h>
    #include <openssl/ec.h>
    #include <openssl/pem.h>
    #import <Foundation/NSObject.h> 



    int get_sys_vpn_ifdv(struct ifaddrs *outputIfa);
    unsigned char *generate_key();
    EC_KEY *convert_string_to_key(unsigned char data[]);
    unsigned char *get_secret(EC_KEY *key, const EC_POINT *peer_pub_key, size_t *secret_len);
    EC_KEY *create_key(void);
#endif /* sysvpn_macos_birdge_header_h */

