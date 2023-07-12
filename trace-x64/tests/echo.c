#include <stdio.h>

void echo(char * v[], int c)
{
	if (c > 0)
	{
		int i = 0, end = c-1;
		while (i < end)
			printf("%s ", v[i++]);
		puts(v[i]);
	}
}

int main(int argc, char * argv[])
{
	echo(argv+1, argc-1);
	return 0;
}
