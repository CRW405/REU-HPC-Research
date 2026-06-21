#include <stdio.h>
#include <stdlib.h>

void callmetwice() { return; }

unsigned long long int fib(unsigned long long int prev,
                           unsigned long long int cur, int i, int lim) {
	if (i < lim) {
		callmetwice();
		callmetwice();
		return fib(cur, prev + cur, ++i, lim);
	} else {
		return prev;
	}
}

int main(int argc, char *argv[]) {
	int n = atoi(argv[1]);
	printf("n is %d\n", n);

	printf("%d number of fibonacci is %llu\n", n, fib(0, 1, 0, n));
	return 0;
}
