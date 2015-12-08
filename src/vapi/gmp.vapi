[CCode(cheader_filename="gmp.h")]
namespace Gmp {

	[CCode(cname="__mpz_struct", destroy_function="mpz_clear", cprefix="mpz_", has_type_id=false)]
	public struct Mpz {
		[CCode(cname="mpz_init")]
		public Mpz();

		public void set(Mpz op);
		public void set_str(string value, int base);
		public void set_ui(ulong op);
		public void set_si(long op);

		public void add(Mpz op1, Mpz op2);
		public void add_ui(Mpz op1, ulong op2);

		public void sub(Mpz op1, Mpz op2);

		public void mul(Mpz op1, Mpz op2);
		public void mul_ui(Mpz op1, ulong op2);
		public void mul_si(Mpz op1, long op2);

		public void pow_ui(Mpz base, ulong exp);
		public void powm(Mpz b, Mpz e, Mpz m);

		public int cmp(Mpz op);

		public int sizeinbase(int base);

		[CCode(instance_pos=2.5)]
		public char* get_str(char* str, int base);
	}

	[CCode(cname="gmp_printf")]
	public void printf(string format, ...);
}
