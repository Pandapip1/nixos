#define _GNU_SOURCE

#include <errno.h>
#include <pwd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int
main(void)
{
	errno = 0;
	struct passwd *pw = getpwuid(getuid());
	if (pw == NULL) {
		if (errno)
		perror("getpwuid");
		else
		fprintf(stderr, "No passwd entry for current user\n");
		return EXIT_FAILURE;
	}

	const char *shell = pw->pw_shell;
	if (shell == NULL || shell[0] == '\0') {
		fprintf(stderr, "No login shell configured\n");
		return EXIT_FAILURE;
	}

	const char *base = strrchr(shell, '/');
	base = base ? base + 1 : shell;

	size_t len = strlen(base);
	char *argv0 = malloc(len + 2);
	if (argv0 == NULL) {
		perror("malloc");
		return EXIT_FAILURE;
	}

	argv0[0] = '-';
	memcpy(argv0 + 1, base, len + 1);

	char *const argv[] = {
		argv0,
		NULL,
	};

	execv(shell, argv);

	perror(shell);
	return EXIT_FAILURE;
}
