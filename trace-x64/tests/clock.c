#include <stdio.h>
#include <time.h>
#include <unistd.h>

int main(void)
{
	struct timespec start;
    clock_gettime(CLOCK_REALTIME, &start);
    return 0;
}
