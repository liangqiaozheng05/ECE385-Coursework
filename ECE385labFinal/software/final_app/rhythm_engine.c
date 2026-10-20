/*
 * rhythm_engine.c
 */
#include <unistd.h>
#include "rhythm_engine.h"
#include "beatmap.h"
#include <stdlib.h>
#include <stdio.h>

static unsigned int next_spawn_index = 0;
static unsigned int head_active_index = 0;

static unsigned long total_score = 0;
static unsigned int current_combo = 0;

static unsigned long anim_timeout = 0;
static unsigned long fb_timeout = 0;
static alt_u8 current_fb = 0;

static alt_u8 note_states[NUM_NOTES]; 


void Engine_Init(void) {
    next_spawn_index = 0;
    head_active_index = 0;
    total_score = 0;
    current_combo = 0;
    
    anim_timeout = 0;
    fb_timeout = 0;
    current_fb = 0;
    
    for (int i = 0; i < NUM_NOTES; i++) {
        note_states[i] = 0;
    }
    printf("Rhythm Engine Initialized\n");
}

// 途径Note Spawn PIO通知硬件掉落色块
void Beatmap_CheckAndSpawn(unsigned long music_time_ms, volatile alt_u8* spawn_pio) {
    *spawn_pio = 0x00; 

    // 当还有未生成的音符
    while (next_spawn_index < NUM_NOTES) {
        // 计算提前掉落时间，何时音符该开始生成并下落 TODO 把test_beatmap改了
        long spawn_time = (long)test_beatmap[next_spawn_index].hit_time_ms - DROP_DURATION_MS;
        
        // 时间到达
        if ((long)music_time_ms >= spawn_time) {
            // 向 PIO 写数据
            // 0001 表示轨道0有一个新音符，0010 表示轨道1有一个新音符...
            alt_u8 spawn_cmd = (1 << test_beatmap[next_spawn_index].track);
            *spawn_pio = spawn_cmd; 
            
            // printf("Spawn Note %d on track %d\n", next_spawn_index, test_beatmap[next_spawn_index].track);
            next_spawn_index++;
        } else {
            break;
        }
    }
}

// 检查按键是否踩中时间点
void Engine_HitDetection(alt_u8 current_key, unsigned long music_time_ms, volatile alt_u32* score_pio, volatile alt_u8* hit_pio) {
    
    

    // 超时不按导致的 Miss
    while (head_active_index < next_spawn_index) {
        if (note_states[head_active_index] == 0) { // 如果状态是掉落中
            long time_diff = (long)music_time_ms - (long)test_beatmap[head_active_index].hit_time_ms;
            if (time_diff > MISS_TOLERANCE) {
  
                note_states[head_active_index] = 2;
                current_combo = 0;
                
                // Miss停留300ms
                current_fb = 3; 
                fb_timeout = music_time_ms + 300; 
            } else {
                break; // 最前面的没超时，后面也不超时
            }
        }
        head_active_index++;
    }

    // 按键判定
    if (current_key != 0x00) {
        int hit_track = -1;
        if      (current_key == 0x07) hit_track = 0; // D
        else if (current_key == 0x09) hit_track = 1; // F
        else if (current_key == 0x0D) hit_track = 2; // J
        else if (current_key == 0x0E) hit_track = 3; // K TODO 检查按键值正确性
        
        if (hit_track != -1) {
            // 活着的音符中最早的音符
            for (int i = head_active_index; i < next_spawn_index; i++) {
                if (note_states[i] == 0 && test_beatmap[i].track == hit_track) {
                    
                    long delta_T = abs((long)music_time_ms - (long)test_beatmap[i].hit_time_ms);
                    
                    if (delta_T <= PERFECT_TOLERANCE) {
                        total_score += SCORE_PERFECT;
                        current_combo++;
                        note_states[i] = 1;
                        
                        *hit_pio = (1 << hit_track);
                        usleep(10);
                        *hit_pio = 0;

                        // 反馈出现300ms，分数按下动画100ms
                        current_fb = 1;
                        fb_timeout = music_time_ms + 300;
                        anim_timeout = music_time_ms + 100; 
                        break;
                    } 
                    else if (delta_T <= GREAT_TOLERANCE) {
                        total_score += SCORE_GREAT;
                        current_combo++;
                        note_states[i] = 1;
                        
                        *hit_pio = (1 << hit_track);
                        usleep(10);
                        *hit_pio = 0;

                        current_fb = 2;
                        fb_timeout = music_time_ms + 300;
                        anim_timeout = music_time_ms + 100;
                        break;
                    }
                    else if (delta_T <= MISS_TOLERANCE) {
                        current_combo = 0;
                        note_states[i] = 2;
                        
                        // 提前按导致的Miss
                        current_fb = 3;
                        fb_timeout = music_time_ms + 300;
                        break;
                    }
                }
            }
        }
    }

    // 判断倒计时是否结束
    // 结束则隐藏或切换动画
    alt_u8 fb_out   = (music_time_ms < fb_timeout) ? current_fb : 0;
    alt_u8 anim_out = (music_time_ms < anim_timeout) ? 7 : 0; // 111

    // 提取十进制位，不用在sv计算
    alt_u8 s_100 = (total_score / 100) % 10;
    alt_u8 s_10  = (total_score / 10) % 10;
    alt_u8 s_1   = total_score % 10;

    alt_u8 c_10  = (current_combo / 10) % 10;
    alt_u8 c_1   = current_combo % 10;

    // PIO
    *score_pio = (fb_out << 24) | (s_100 << 20) | (s_10 << 16) | (s_1 << 12) | 
                 (c_10 << 8)   | (c_1 << 4)   | anim_out;
}

// 游戏是否结束
int Beatmap_IsFinished(unsigned long music_time_ms) {
    if (next_spawn_index >= NUM_NOTES) {
        // 所有音符都生成了，且最后一个音符的时间也超过了判定期
        long last_note_time = (long)test_beatmap[NUM_NOTES - 1].hit_time_ms;
        if ((long)music_time_ms > last_note_time + MISS_TOLERANCE + 1000) { // 多等一秒
            return 1;
        }
    }
    return 0;
}