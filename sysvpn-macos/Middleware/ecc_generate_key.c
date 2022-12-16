//
//  ecc_generate_key.c
//  sysvpn-macos
//
//  Created by doragon on 15/12/2022.
//

#include <stdio.h>
#include <stdlib.h>
#include <openssl/bio.h>
#include <openssl/err.h>
#include <openssl/ec.h>
#include <openssl/pem.h>
#include <string.h>
#define ECCTYPE  "secp521r1"

EC_KEY *create_key(void)
{
    EC_KEY *key;
    if (NULL == (key = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1))) {
        printf("Failed to create key curve\n");
        return NULL;
    }
     
    
    if (1 != EC_KEY_generate_key(key)) {
        printf("Failed to generate key\n");
        return NULL;
    }
    return key;
}

EC_KEY *convert_string_to_key(unsigned char data[] ) { 
    EC_KEY *key = EC_KEY_new();
    BIO *keybio = BIO_new(BIO_s_mem());
    BIO_write(keybio, data, strlen(data));
    PEM_read_bio_EC_PUBKEY(keybio, &key, NULL, NULL);
    EC_POINT * pkey = EC_KEY_get0_public_key(key);
    BIO_free(keybio);
    return key;
}

char *generate_key(void) {
    EC_KEY *key = create_key();
//    unsigned char  str[] = "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEa16msDvs57M2/gisellEBAR6/nlqulM2Z1RZfi1EC561jYffbNN1KK30K7frscucc8gEDaP8ntY/ytPkKxwCow==\n-----END PUBLIC KEY-----";
//    EC_KEY *key = convert_string_to_key(str);
    char *buf = malloc(256);
    char *p;
 
    BIO *keybio = BIO_new(BIO_s_mem());
    PEM_write_bio_EC_PUBKEY(keybio, key);
    
   
    size_t readSize = BIO_get_mem_data(keybio, &p);
    
    memcpy(buf, p, readSize);
    
    BIO_set_close(keybio, BIO_NOCLOSE);
    
    BIO_free(keybio);
    
    return buf;
}
  

unsigned char *get_secret(EC_KEY *key, const EC_POINT *peer_pub_key,
            size_t *secret_len)
{
    int field_size;
    unsigned char *secret;

    field_size = EC_GROUP_get_degree(EC_KEY_get0_group(key));
    *secret_len = (field_size + 7) / 8;

    if (NULL == (secret = OPENSSL_malloc(*secret_len))) {
        printf("Failed to allocate memory for secret");
        return NULL;
    }

    *secret_len = ECDH_compute_key(secret, *secret_len,
                    peer_pub_key, key, NULL);

    if (*secret_len <= 0) {
        OPENSSL_free(secret);
        return NULL;
    }
    return secret;
}
