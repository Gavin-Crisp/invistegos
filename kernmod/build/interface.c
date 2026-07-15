#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/bio.h>
#include <linux/device-mapper.h>

// Zig functions assume a 16 byte aligned stack, but the linux
// kernel uses 8 byte alignment. Wrap zig callbacks in this macro to ensure our
// stack is in a sane state
#define CALL_16_ALIGNED(__f)                                 \
({                                                           \
	int __x __attribute__((aligned(16))) = 0;                \
	/* Use __asm__ block to avoid optimizing away __x */     \
	__asm__(""                                               \
			:                                                \
			/* Tell GCC that __x needs to have an address */ \
			/* so it is forced onto the stack */             \
			: "g"(&__x)                                      \
			/* Tell GCC that memory could be changed */      \
			/* by this asm block to avoid reordering */      \
			: "memory"                                       \
			);                                               \
	/* Actually do the work passed in */                     \
	__f;                                                     \
})

int invistegos_impl_ctr(struct dm_target *, unsigned int , char **);
void invistegos_impl_dtr(struct dm_target *);
int invistegos_impl_map(struct dm_target *, struct bio *);

static int invistegos_ctr(struct dm_target *ti, unsigned int argc, char **argv) {
	return CALL_16_ALIGNED(invistegos_impl_ctr(ti, argc, argv));
}

static void invistegos_dtr(struct dm_target *ti) {
	CALL_16_ALIGNED(invistegos_impl_dtr(ti));
}

/*  Return values from target map function:
 *  DM_MAPIO_SUBMITTED :  Your target has submitted the bio request to underlying request
 *  DM_MAPIO_REMAPPED  :  Bio request is remapped, Device mapper should submit bio.
 *  DM_MAPIO_REQUEUE   :  Some problem has happened with the mapping of bio, So
 *                                                re queue the bio request. So the bio will be submitted
 *                                                to the map function
 */
static int invistegos_map(struct dm_target *ti, struct bio *bio) {
	return CALL_16_ALIGNED(invistegos_impl_map(ti, bio));
}

static struct target_type invistegos_target = {
	.name = "invistegos",
	.version = {0,0,0},
	.module = THIS_MODULE,
	.ctr = invistegos_ctr,
	.dtr = invistegos_dtr,
	.map = invistegos_map,
};

module_dm(invistegos);

MODULE_AUTHOR("Gain Crisp <gavin@gavincrisp.com.au>");
MODULE_DESCRIPTION(DM_NAME " self-concealing target");
MODULE_LICENSE("GPL");
