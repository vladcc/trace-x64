#include <unistd.h>

#define MIN 60

int main(void)
{
	int i = 5*MIN;

	do {
		sleep(1);
	} while (--i);

	return 0;
}
