/**
 * Copyright (C) 2025, Gavin Crisp under GNU Affero General Public License.
 */

#ifndef _LCG_H

#include <linux/types.h>

#ifndef uint32_t
# define __u32 uint32_t
#endif

#ifndef uint64_t
# define __u64 uint64_t
#endif

uint32_t lcg_map32(uint32_t index, uint32_t limit);
uint64_t lcg_map64(uint64_t index, uint64_t limit);

#endif
