//
//  ecc_openssl.h
//  sysvpn-macos
//
//  Created by macbook on 02/01/2023.
//

#ifndef ecc_openssl_h
#define ecc_openssl_h
    #include <openssl/bio.h>
    #include <openssl/err.h>
    #include <openssl/ec.h>
    #include <openssl/pem.h>
 
    EC_KEY *convert_string_to_key(unsigned char data[]);
    unsigned char *get_secret(EC_KEY *key, const EC_POINT *peer_pub_key, size_t *secret_len);
    EC_KEY *create_key(void);
    long get_pubkey_string(EC_KEY *key, unsigned char * buff);
    unsigned char * get_secret_key(EC_KEY *key,  char *peer_pub_key, int peer_pub_len, size_t *secret_len) ;
long get_privateKey_string(EC_KEY *key, unsigned char * buff);
#endif /* ecc_openssl_h */
