/**
 * @file zkbrain.h
 * @brief ZKBrain Windows C/C++ SDK 统一接口头文件
 * @version 1.2.0
 * @copyright (c) 2026 ZKTeco. All rights reserved.
 * 
 * 适用于 Windows (C++, C#, Python, Electron, Unity 等) 平台的脑机接口算法与数据解析核心。
 */

#ifndef ZKBRAIN_H
#define ZKBRAIN_H

#include <stdbool.h>
#include <stdint.h>

#if defined(_WIN32)
  #if defined(ZKBRAIN_EXPORTS) || defined(ZKBRAIN_BUILD_SHARED)
    #define ZK_API __declspec(dllexport)
  #else
    #define ZK_API __declspec(dllimport)
  #endif
#else
  #define ZK_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* ========================================================================= */
/* 🌟 1. 错误码与枚举常量定义                                                 */
/* ========================================================================= */

/**
 * @brief License 安全鉴权返回状态码定义 (zkbrain_sec_init 返回值)
 */
typedef enum {
    ZKBRAIN_AUTH_SUCCESS               = 1024,  /**< 授权鉴权成功，所有算法功能解锁 */
    ZKBRAIN_AUTH_ERR_NULL_PARAM        = -1,    /**< 传入的 License 字符串指针为空 */
    ZKBRAIN_AUTH_ERR_INVALID_JSON      = -2,    /**< 外层 JSON 格式解析失败 (语法错误) */
    ZKBRAIN_AUTH_ERR_MISSING_FIELDS    = -3,    /**< 缺失 payload 或 signature 关键字段 */
    ZKBRAIN_AUTH_ERR_SIGNATURE_INVALID = -4,    /**< 授权数字签名验证未通过 (证书被篡改或签名无效) */
    ZKBRAIN_AUTH_ERR_PAYLOAD_INVALID   = -5,    /**< 内层 Payload JSON 数据解析失败 */
    ZKBRAIN_AUTH_ERR_APP_ID_MISMATCH   = -6,    /**< 宿主程序标识 AppID 与 License 绑定的 AppID 不一致 */
    ZKBRAIN_AUTH_ERR_DEVICE_MISMATCH   = -7,    /**< 硬件设备标识 DeviceID 不在授权允许列表中 */
    ZKBRAIN_AUTH_ERR_EXPIRED           = -8,    /**< 授权已过期 (当前时间超过 validUntil 截止时间戳) */
    ZKBRAIN_AUTH_ERR_TIME_TAMPERED     = -9     /**< 系统时钟异常校验触发 (系统时钟回退或异常) */
} ZKBrainAuthStatus;

/**
 * @brief 佩戴信号质量状态等级定义
 */
typedef enum {
    ZKBRAIN_SIGNAL_EXCELLENT           = 0,     /**< 导联佩戴优良 (接触阻抗正常，脑电波与专注度正常计算) */
    ZKBRAIN_SIGNAL_POOR_MIN            = 1,     /**< 接触不良下限 */
    ZKBRAIN_SIGNAL_POOR_MAX            = 199,   /**< 接触不良上限 (芯片算法暂停迭代更新) */
    ZKBRAIN_SIGNAL_OFF_SKIN            = 200    /**< 电极完全脱落未佩戴 (无物理导电回路) */
} ZKBrainSignalQuality;

/**
 * @brief 综合特征数据数组 (intData) 下标语义映射定义
 */
typedef enum {
    ZKBRAIN_DATA_INDEX_SIGNAL          = 0,     /**< 信号质量 (0: 优良, 1-199: 接触不良, 200: 脱落) */
    ZKBRAIN_DATA_INDEX_ATTENTION       = 1,     /**< 专注度 (Attention: 0 - 100) */
    ZKBRAIN_DATA_INDEX_MEDITATION      = 2,     /**< 放松度 / 冥想深度 (Meditation: 0 - 100) */
    ZKBRAIN_DATA_INDEX_PREFERENCE      = 3,     /**< 情绪偏好 / 喜爱度 (Preference: 0 - 100) */
    ZKBRAIN_DATA_INDEX_BATTERY         = 4,     /**< 设备剩余电量百分比 (0 - 100 %) */
    ZKBRAIN_DATA_INDEX_GRIND           = 5,     /**< 咬牙 / 磨牙强度 (0 - 255) */
    ZKBRAIN_DATA_INDEX_HEART_RATE      = 6,     /**< 实时心率 (HeartRate BPM, -1: 异常, 0: 未测出) */
    ZKBRAIN_DATA_INDEX_DELTA           = 7,     /**< Delta 频段能量 (0.5 - 2.75 Hz) */
    ZKBRAIN_DATA_INDEX_THETA           = 8,     /**< Theta 频段能量 (3.5 - 6.75 Hz) */
    ZKBRAIN_DATA_INDEX_LOW_ALPHA       = 9,     /**< Low Alpha 频段能量 (7.5 - 9.25 Hz) */
    ZKBRAIN_DATA_INDEX_HIGH_ALPHA      = 10,    /**< High Alpha 频段能量 (10.0 - 11.75 Hz) */
    ZKBRAIN_DATA_INDEX_LOW_BETA        = 11,    /**< Low Beta 频段能量 (13.0 - 16.75 Hz) */
    ZKBRAIN_DATA_INDEX_HIGH_BETA       = 12,    /**< High Beta 频段能量 (17.5 - 29.75 Hz) */
    ZKBRAIN_DATA_INDEX_LOW_GAMMA       = 13,    /**< Low Gamma 频段能量 (31.0 - 39.75 Hz) */
    ZKBRAIN_DATA_INDEX_MID_GAMMA       = 14,    /**< Middle Gamma 频段能量 (41.0 - 49.75 Hz) */
    ZKBRAIN_DATA_ARRAY_SIZE            = 15     /**< 综合特征数据数组标准长度 */
} ZKBrainDataIndex;

/* ========================================================================= */
/* 🌟 2. 回调函数签名与数据结构定义                                           */
/* ========================================================================= */

/**
 * @brief 综合脑电特征数据回调函数 (1Hz 输出)
 * 
 * @param intData 整型数据数组指针，长度至少为 15，各下标定义如下：
 *   - intData[0]: 信号质量 (Signal: 0 为佩戴良好, 1-199 为接触不良, 200 为脱落未佩戴)
 *   - intData[1]: 专注度 (Attention: 0 - 100)
 *   - intData[2]: 放松度 / 冥想深度 (Meditation: 0 - 100)
 *   - intData[3]: 用户喜好度 / 情绪偏好 (Preference)
 *   - intData[4]: 设备电量百分比 (Battery: 0 - 100)
 *   - intData[5]: 咬牙 / 磨牙强度 (Grind Intensity)
 *   - intData[6]: 实时心率 (Heart Rate BPM, -1 为异常, 0 为未佩戴或测不出)
 *   - intData[7]: Delta 频段脑电波能量谱 (0.5 - 2.75 Hz)
 *   - intData[8]: Theta 频段脑电波能量谱 (3.5 - 6.75 Hz)
 *   - intData[9]: Low Alpha 频段脑电波能量谱 (7.5 - 9.25 Hz)
 *   - intData[10]: High Alpha 频段脑电波能量谱 (10.0 - 11.75 Hz)
 *   - intData[11]: Low Beta 频段脑电波能量谱 (13.0 - 16.75 Hz)
 *   - intData[12]: High Beta 频段脑电波能量谱 (17.5 - 29.75 Hz)
 *   - intData[13]: Low Gamma 频段脑电波能量谱 (31.0 - 39.75 Hz)
 *   - intData[14]: Middle Gamma 频段脑电波能量谱 (41.0 - 49.75 Hz)
 * @param hw 固件硬件版本号 (如 1.2)
 * @param temp 额温 / 体温 (°C)
 * @param userData 用户自定义上下文指针 (即 set_callbacks 时传入的 userData)
 */
typedef void (*BrainDataCallback)(int* intData, double hw, float temp, void* userData);

/**
 * @brief 高频原始脑电波回调 (Raw Wave, 256Hz / 512Hz)
 * 
 * @param raw 原始微伏采样点 (-32768 ~ 32767)
 * @param userData 用户自定义上下文指针
 */
typedef void (*RawWaveCallback)(int raw, void* userData);

/**
 * @brief 三轴重力加速度与空间姿态回调
 * 
 * @param x X轴加速度 / 角度
 * @param y Y轴加速度 / 角度
 * @param z Z轴加速度 / 角度
 * @param userData 用户自定义上下文指针
 */
typedef void (*GravityCallback)(int x, int y, int z, void* userData);

/**
 * @brief 心率 RR 间期原始数据流回调
 * 
 * @param rrData RR 间期毫秒数组
 * @param len 数组长度
 * @param userData 用户自定义上下文指针
 */
typedef void (*RRIntervalCallback)(int* rrData, int len, void* userData);

/**
 * @brief MEMS 空间 3D 旋转姿态四元数回调
 * 
 * @param q0 归一化四元数 W 分量
 * @param q1 归一化四元数 X 分量
 * @param q2 归一化四元数 Y 分量
 * @param q3 归一化四元数 Z 分量
 * @param userData 用户自定义上下文指针
 */
typedef void (*QuaternionCallback)(float q0, float q1, float q2, float q3, void* userData);


/* ========================================================================= */
/* 🌟 2. 授权鉴权与环境接口                                                   */
/* ========================================================================= */

/**
 * @brief 初始化 SDK 安全许可与 License 验证 (必须最优先调用)
 * 
 * @param license_json_str 授权 License JSON 字符串 (包含 payload 与 signature)
 * @return int 状态码：
 *   - 1024: 授权成功，全部算法功能解锁
 *   - -1: 传入的 License 字符串为空
 *   - -2: JSON 格式解析失败
 *   - -3: 缺失 payload 或 signature 字段
 *   - -4: 数字签名校验未通过
 *   - -5: 内层 Payload 解析异常
 *   - -6: AppID 不匹配
 *   - -7: DeviceID (设备标识) 不匹配
 *   - -8: 授权已过期 (validUntil 超时)
 *   - -9: 系统时钟异常 (时间校验不通过)
 */
ZK_API int zkbrain_sec_init(const char* license_json_str);

/**
 * @brief 获取当前 Windows 宿主程序的识别标识 (AppID)
 * 用于向 ZKTeco 申请正版授权文件。
 * @return const char* 当前宿主可执行文件名 (例如 "MyApp")
 */
ZK_API const char* zkbrain_get_app_id();

/**
 * @brief 查询指定功能特性是否已被授权解锁
 * 
 * @param feature_name 功能名称，如 "raw_eeg"、"attention"、"meditation"、"eeg_power" 等
 * @return true 已授权可用
 * @return false 未授权被阻断
 */
ZK_API bool zkbrain_sec_has_feature(const char* feature_name);

/**
 * @brief 获取已绑定的设备机器码白名单字符串
 * @return const char* 机器码字符串或 "*" (全放行)
 */
ZK_API const char* zkbrain_sec_get_authorized_devices();


/* ========================================================================= */
/* 🌟 3. 解析器核心控制接口                                                   */
/* ========================================================================= */

/**
 * @brief 创建脑电解析器实例
 * 注意：必须在 zkbrain_sec_init 成功授权后调用，否则返回 NULL。
 * 
 * @return void* 解析器实例句柄
 */
ZK_API void* zkbrain_parser_create();

/**
 * @brief 销毁解析器实例并释放内存
 * 
 * @param handle 解析器句柄
 */
ZK_API void zkbrain_parser_destroy(void* handle);

/**
 * @brief 重置解析器状态机 (用于设备重连或断开时清空缓冲)
 * 
 * @param handle 解析器句柄
 */
ZK_API void zkbrain_parser_reset(void* handle);

/**
 * @brief 喂入硬件传输的原始字节流 (来自 BLE 特征值 Notify 或 串口 Serial 接收)
 * 
 * @param handle 解析器句柄
 * @param data 字节缓冲区指针
 * @param len 字节长度
 */
ZK_API void zkbrain_parser_parse(void* handle, const uint8_t* data, int len);

/**
 * @brief 注册数据回调监听器
 * 
 * @param handle 解析器句柄
 * @param onData 综合脑电特征包回调 (1Hz)
 * @param onRaw 高频原始脑电波回调 (256Hz/512Hz)
 * @param onGravity 重力加速度姿态回调 (可为 NULL)
 * @param onRRInterval RR 间期心率回调 (可为 NULL)
 * @param onQuaternion 3D 姿态四元数回调 (可为 NULL)
 * @param userData 用户自定义上下文指针，会在各个回调中原样传回
 */
ZK_API void zkbrain_parser_set_callbacks(
    void* handle,
    BrainDataCallback onData,
    RawWaveCallback onRaw,
    GravityCallback onGravity,
    RRIntervalCallback onRRInterval,
    QuaternionCallback onQuaternion,
    void* userData
);

#ifdef __cplusplus
}
#endif

#endif /* ZKBRAIN_H */
