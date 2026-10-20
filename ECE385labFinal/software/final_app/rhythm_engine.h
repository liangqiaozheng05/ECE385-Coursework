/*
 * rhythm_engine.h
 * 负责生成控制与碰撞判定逻辑
 * 它会修改Spawn PIO通知硬件生成新的音符
 * 它会修改Score PIO的值来更新分数和连击数
 */

#ifndef RHYTHM_ENGINE_H_
#define RHYTHM_ENGINE_H_

#include "alt_types.h"

// 判定窗口
#define PERFECT_TOLERANCE 50   // ±50ms 内算 Perfect
#define GREAT_TOLERANCE   120 
#define MISS_TOLERANCE    200

// 得分权重
#define SCORE_PERFECT 5
#define SCORE_GREAT   2

void Engine_Init(void);
void Beatmap_CheckAndSpawn(unsigned long music_time_ms, volatile alt_u8* spawn_pio);
void Engine_HitDetection(alt_u8 current_key, unsigned long music_time_ms, volatile alt_u32* score_pio, volatile alt_u8* hit_pio);
int Beatmap_IsFinished(unsigned long music_time_ms);

#endif /* RHYTHM_ENGINE_H_ */