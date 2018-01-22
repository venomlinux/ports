#define _GNU_SOURCE

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#ifndef DEF_SUFFIX
#  define DEF_SUFFIX "64"
#endif

int main(int argc, char **argv)
{
  char *filename;
  char *suffix;

  if(!(suffix = getenv("USE_ARCH")))
    if(!(suffix = getenv("BUILDENV")))
      suffix = DEF_SUFFIX;

  if (asprintf(&filename, "%s-%s", argv[0], suffix) < 0) {
    perror(argv[0]);
    return -1;
  }

  int status = EXIT_FAILURE;
  pid_t pid = fork();

  if (pid == 0) {
    execvp(filename, argv);
    perror(filename);
  } else if (pid < 0) {
    perror(argv[0]);
  } else {
    if (waitpid(pid, &status, 0) != pid) {
      status = EXIT_FAILURE;
      perror(argv[0]);
    } else {
      status = WEXITSTATUS(status);
    }
  }

  free(filename);

  return status;
}

