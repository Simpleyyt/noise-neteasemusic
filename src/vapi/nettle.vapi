namespace Nettle {
	[CCode (has_target = false)]
	public delegate void CryptFunc(void* ctx, uint length, uint8* dst, uint8* src);
	
	[CCode (cname = "struct aes_ctx", cprefix = "aes_", cheader_filename = "nettle/aes.h")]
	public struct AES
	{
		public void set_encrypt_key(uint length, uint8* key);
		public void set_decrypt_key(uint length, uint8* key);
		public void invert_key(AES *src);
		public void encrypt(uint length, uint8* dst, uint8* src);
		public void decrypt(uint length, uint8* dst, uint8* src);
	}
	
	[CCode (cname = "cbc_encrypt", cheader_filename = "nettle/cbc.h")]
	public void cbc_encrypt(void* ctx, CryptFunc f, uint block_size, uint8* iv, uint length, uint8* dst, uint8* src);

	[CCode (cname = "cbc_decrypt", cheader_filename = "nettle/cbc.h")]
	public void cbc_decrypt(void* ctx, CryptFunc f, uint block_size, uint8* iv, uint length, uint8* dst, uint8* src);
	
	[CCode (cname = "AES_BLOCK_SIZE", cheader_filename = "nettle/aes.h")]
	public const int AES_BLOCK_SIZE;

	[CCode (cname = "struct base64_encode_ctx", cprefix = "base64_", cheader_filename = "nettle/base64.h")]
	public struct Base64
	{
		[CCode (cname = "base64_encode_init")]
		public Base64 ();
		public size_t encode_single (uint8* dst, uint8 src);
		public size_t encode_update (uint8* dst, size_t length, uint8* src);
		public size_t encode_final (uint8* dst);
	}

	[CCode (cname = "BASE64_ENCODE_LENGTH", cheader_filename = "nettle/base64.h")]
	public size_t BASE64_ENCODE_LENGTH(size_t length);

	[CCode (cname = "BASE64_ENCODE_FINAL_LENGTH", cheader_filename = "nettle/base64.h")]
	public const size_t BASE64_ENCODE_FINAL_LENGTH;
}
