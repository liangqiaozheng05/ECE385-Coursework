/*
 * beatmap.h
 * to store hardcoded beatmap data
 */

#ifndef BEATMAP_H_
#define BEATMAP_H_

// single note structure
typedef struct {
    unsigned long hit_time_ms; // expected hit time (timestamp when note reaches judgment line)
    int track;                 // track number: 0, 1, 2, 3 (corresponding to keys D, F, J, K, or sth else)
} Note;

// read-only array for the song
static const Note test_beatmap[] = {
          // time   track
		    {1321,  2},   // 3
		    {1643,  1},   // 2
		    {1964,  0},   // low6
		    {2286,  1},   // 2

		    {4214,  1},   // 2
		    {4536,  2},   // 3
		    {4857,  1},   // 2
		    {5179,  2},   // 3
		    {5500,  2},   // 5
		    {5821,  2},   // 3

		    {6143,  1},   // 2
		    {6464,  2},   // 3
		    {6786,  1},   // 2
		    {7107,  0},   // low6
		    {7429,  1},   // 1

		    {9357,  3},   // high1
		    {10000, 3},   // 7
		    {10214, 2},   // 5
		    {10429, 2},   // 3

		    {11393, 1},   // 2
		    {11714, 2},   // 3
		    {12036, 1},   // 2
		    {12357, 0},   // low6
		    {12679, 1},   // 2

		    {14607, 1},   // 2
		    {14929, 2},   // 3
		    {15250, 1},   // 2
		    {15571, 2},   // 3
		    {15893, 2},   // 5
		    {16214, 2},   // 3

		    {16429, 1},   // 2
		    {16750, 2},   // 3
		    {17071, 1},   // 2
		    {17393, 1},   // 1
		    {17714, 0}    // low6
};

// how many notes in the beatmap
#define NUM_NOTES (sizeof(test_beatmap) / sizeof(test_beatmap[0]))

#define DROP_DURATION_MS 1333 

#endif /* BEATMAP_H_ */
