/* libdl for a static RISC OS program: there's no dynamic loading, so
 * dlopen always fails. OpenTTD only uses it in LibraryLoader, to look for
 * social integration plugins, and carries on without them.
 * (GCCSDK's own libdl, which earlier builds linked, isn't in
 * riscos-crossdev's toolchain.) */
#include <dlfcn.h>
#include <stddef.h>

static const char *last_error;

void *dlopen(const char *file, int mode)
{
	(void)file; (void)mode;
	last_error = "dynamic loading isn't available on RISC OS";
	return NULL;
}

void *dlsym(void *handle, const char *name)
{
	(void)handle; (void)name;
	last_error = "dynamic loading isn't available on RISC OS";
	return NULL;
}

int dlclose(void *handle)
{
	(void)handle;
	return 0;
}

const char *dlerror(void)
{
	const char *e = last_error;
	last_error = NULL;
	return e;
}
