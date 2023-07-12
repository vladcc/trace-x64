#include <stdio.h>

#define MAX_FIB 93

static size_t fib_rec(size_t n)
{
	return (n < 2) ? n : fib_rec(n-1) + fib_rec(n-2);
}
static size_t fib_tbl(size_t n)
{
	static size_t cache[MAX_FIB];
	
	if (n < 2)
		return n;
	
	if (cache[n])
		return cache[n];
	
	return (cache[n] = fib_tbl(n-1) + fib_tbl(n-2));
}
static size_t fib_loop(size_t n)
{
	if (n < 2)
		return n;
	
	size_t a = 0;
	size_t b = 1;
	size_t c = a+b;
	
	for (size_t i = 2; i < n; ++i)
	{
		a = b;
		b = c;
		c = a+b;
	}
	
	return c;
}

int main(int argc, char * argv[])
{
	if (argc != 2)
	{
		fprintf(stderr, "Use: fib <num>\n");
		return 1;
	}
	
	size_t num = 0;
	if (sscanf(argv[1], "%zu", &num) != 1)
	{
		fprintf(stderr, "error: '%s' not a valid number", argv[1]);
		return 2;
	}
	
	if (num > MAX_FIB)
	{
		fprintf(stderr, "error: %zu is too large\n", num);
		return 3;
	}
		
	printf("%zu\n", fib_rec(num));
	printf("%zu\n", fib_tbl(num));
	printf("%zu\n", fib_loop(num));
	return 0;
}
