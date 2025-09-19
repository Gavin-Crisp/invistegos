/**
 * Copyright (C) 2025, Gavin Crisp under GNU Affero General Public License.
 */

#include "lcg.h"

#define MULT_32 821321413
#define INCR_32 685330167
#define LCG32(x) ((uint32_t)(MULT_32 * x + INCR_32))

#define MULT_64 954163573
#define INCR_64 418988031
#define LCG64(x) ((uint64_t)(MULT_64 * x + INCR_64))

/**
 * Maps index to another value below limit; if index is not less than limit, returns index.
 */
uint32_t lcg_map32(uint32_t index, uint32_t limit)
{
	if (index >= limit)
		return index;

	// Three times because lcg is deeply mediocre.
	index = LCG32(LCG32(LCG32(index)));

	while (index >= limit) {
		index = LCG32(index);
	}

	return index;
}

/**
 * Maps index to another value below limit; if index is not less than limit, returns index.
 */
uint64_t lcg_map64(uint64_t index, uint64_t limit)
{
	if (index >= limit)
		return index;

	// Three times because lcg is deeply mediocre.
	index = LCG64(LCG64(LCG64(index)));

	while (index >= limit) {
		index = LCG64(index);
	}

	return index;
}
