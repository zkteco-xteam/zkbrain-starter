/**
 * @file zkbrain.h
 * @brief ZKBrain Windows C/C++ SDK Unified Interface Header
 * @version 1.2.0
 * @copyright (c) 2026 ZKTeco. All rights reserved.
 * 
 * BCI algorithm and data parsing core for Windows (C++, C#, Python, Electron, Unity).
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
/* 1. Error Codes & Enumerations                                             */
/* ========================================================================= */

/**
 * @brief License authorization return status codes (zkbrain_sec_init return values)
 */
typedef enum {
    ZKBRAIN_AUTH_SUCCESS               = 1024,  /**< Authorized successfully, all algorithm features unlocked */
    ZKBRAIN_AUTH_ERR_NULL_PARAM        = -1,    /**< Null pointer for License string */
    ZKBRAIN_AUTH_ERR_INVALID_JSON      = -2,    /**< Outer JSON syntax error */
    ZKBRAIN_AUTH_ERR_MISSING_FIELDS    = -3,    /**< Missing payload or signature fields */
    ZKBRAIN_AUTH_ERR_SIGNATURE_INVALID = -4,    /**< Digital signature verification failed */
    ZKBRAIN_AUTH_ERR_PAYLOAD_INVALID   = -5,    /**< Inner payload JSON parsing error */
    ZKBRAIN_AUTH_ERR_APP_ID_MISMATCH   = -6,    /**< Host application AppID mismatch */
    ZKBRAIN_AUTH_ERR_DEVICE_MISMATCH   = -7,    /**< Hardware DeviceID not in authorized whitelist */
    ZKBRAIN_AUTH_ERR_EXPIRED           = -8,    /**< License expired (current time exceeds validUntil) */
    ZKBRAIN_AUTH_ERR_TIME_TAMPERED     = -9     /**< System clock rollback or anomaly detected */
} ZKBrainAuthStatus;

/**
 * @brief Signal quality status levels
 */
typedef enum {
    ZKBRAIN_SIGNAL_EXCELLENT           = 0,     /**< Excellent contact impedance (normal EEG & attention calculation) */
    ZKBRAIN_SIGNAL_POOR_MIN            = 1,     /**< Poor contact lower bound */
    ZKBRAIN_SIGNAL_POOR_MAX            = 199,   /**< Poor contact upper bound (algorithm holds previous state) */
    ZKBRAIN_SIGNAL_OFF_SKIN            = 200    /**< Electrodes completely detached (no physical circuit) */
} ZKBrainSignalQuality;

/**
 * @brief Composite metrics array (intData) index mapping
 */
typedef enum {
    ZKBRAIN_DATA_INDEX_SIGNAL          = 0,     /**< Signal quality (0: Good, 1-199: Poor, 200: Off-head) */
    ZKBRAIN_DATA_INDEX_ATTENTION       = 1,     /**< Attention level (0 - 100) */
    ZKBRAIN_DATA_INDEX_MEDITATION      = 2,     /**< Meditation depth (0 - 100) */
    ZKBRAIN_DATA_INDEX_PREFERENCE      = 3,     /**< Emotional preference (0 - 100) */
    ZKBRAIN_DATA_INDEX_BATTERY         = 4,     /**< Battery remaining percentage (0 - 100 %) */
    ZKBRAIN_DATA_INDEX_GRIND           = 5,     /**< Grind / teeth clench intensity (0 - 255) */
    ZKBRAIN_DATA_INDEX_HEART_RATE      = 6,     /**< Real-time Heart Rate (BPM, -1: error, 0: not measured) */
    ZKBRAIN_DATA_INDEX_DELTA           = 7,     /**< Delta band power (0.5 - 2.75 Hz) */
    ZKBRAIN_DATA_INDEX_THETA           = 8,     /**< Theta band power (3.5 - 6.75 Hz) */
    ZKBRAIN_DATA_INDEX_LOW_ALPHA       = 9,     /**< Low Alpha band power (7.5 - 9.25 Hz) */
    ZKBRAIN_DATA_INDEX_HIGH_ALPHA      = 10,    /**< High Alpha band power (10.0 - 11.75 Hz) */
    ZKBRAIN_DATA_INDEX_LOW_BETA        = 11,    /**< Low Beta band power (13.0 - 16.75 Hz) */
    ZKBRAIN_DATA_INDEX_HIGH_BETA       = 12,    /**< High Beta band power (17.5 - 29.75 Hz) */
    ZKBRAIN_DATA_INDEX_LOW_GAMMA       = 13,    /**< Low Gamma band power (31.0 - 39.75 Hz) */
    ZKBRAIN_DATA_INDEX_MID_GAMMA       = 14,    /**< Middle Gamma band power (41.0 - 49.75 Hz) */
    ZKBRAIN_DATA_ARRAY_SIZE            = 15     /**< Standard composite metrics array size */
} ZKBrainDataIndex;

/* ========================================================================= */
/* 2. Callback Signatures & Data Structures                                  */
/* ========================================================================= */

/**
 * @brief Composite EEG metrics callback (1Hz output)
 * 
 * @param intData Pointer to integer array of length >= 15:
 *   - intData[0]: Signal quality (0: Good, 1-199: Poor contact, 200: Off-head)
 *   - intData[1]: Attention (0 - 100)
 *   - intData[2]: Meditation (0 - 100)
 *   - intData[3]: User preference / emotion (0 - 100)
 *   - intData[4]: Battery percentage (0 - 100)
 *   - intData[5]: Grind intensity (0 - 255)
 *   - intData[6]: Real-time Heart Rate BPM (-1: error, 0: unmeasured)
 *   - intData[7]: Delta band power (0.5 - 2.75 Hz)
 *   - intData[8]: Theta band power (3.5 - 6.75 Hz)
 *   - intData[9]: Low Alpha band power (7.5 - 9.25 Hz)
 *   - intData[10]: High Alpha band power (10.0 - 11.75 Hz)
 *   - intData[11]: Low Beta band power (13.0 - 16.75 Hz)
 *   - intData[12]: High Beta band power (17.5 - 29.75 Hz)
 *   - intData[13]: Low Gamma band power (31.0 - 39.75 Hz)
 *   - intData[14]: Middle Gamma band power (41.0 - 49.75 Hz)
 * @param hw Firmware hardware version (e.g. 1.2)
 * @param temp Forehead / body temperature (deg C)
 * @param userData Custom context pointer passed to set_callbacks
 */
typedef void (*BrainDataCallback)(int* intData, double hw, float temp, void* userData);

/**
 * @brief High-frequency raw EEG waveform callback (256Hz / 512Hz)
 * 
 * @param raw Raw microvolt sampling point (-32768 ~ 32767)
 * @param userData Custom context pointer
 */
typedef void (*RawWaveCallback)(int raw, void* userData);

/**
 * @brief 3-axis gravity acceleration and spatial attitude callback
 * 
 * @param x X-axis acceleration / angle
 * @param y Y-axis acceleration / angle
 * @param z Z-axis acceleration / angle
 * @param userData Custom context pointer
 */
typedef void (*GravityCallback)(int x, int y, int z, void* userData);

/**
 * @brief Heart rate RR interval raw data callback
 * 
 * @param rrData Array of RR interval in milliseconds
 * @param len Length of array
 * @param userData Custom context pointer
 */
typedef void (*RRIntervalCallback)(int* rrData, int len, void* userData);

/**
 * @brief MEMS 3D spatial rotation quaternion callback
 * 
 * @param q0 Normalized quaternion W component
 * @param q1 Normalized quaternion X component
 * @param q2 Normalized quaternion Y component
 * @param q3 Normalized quaternion Z component
 * @param userData Custom context pointer
 */
typedef void (*QuaternionCallback)(float q0, float q1, float q2, float q3, void* userData);

/* ========================================================================= */
/* 3. Authorization & Environment API                                        */
/* ========================================================================= */

/**
 * @brief Initialize SDK security license verification (must be called first)
 * 
 * @param license_json_str License JSON string (containing payload & signature)
 * @return int Status code: 1024 for success, negative values for errors
 */
ZK_API int zkbrain_sec_init(const char* license_json_str);

/**
 * @brief Get Windows host application identifier (AppID)
 * @return const char* Current host executable name (e.g. "MyApp")
 */
ZK_API const char* zkbrain_get_app_id();

/**
 * @brief Check if a specific feature is authorized
 * 
 * @param feature_name Feature name: "raw_eeg", "attention", "meditation", "eeg_power", etc.
 * @return true if authorized, false otherwise
 */
ZK_API bool zkbrain_sec_has_feature(const char* feature_name);

/**
 * @brief Get authorized device ID whitelist string
 * @return const char* Device string or "*" (all allowed)
 */
ZK_API const char* zkbrain_sec_get_authorized_devices();

/* ========================================================================= */
/* 4. Parser Core Control API                                                */
/* ========================================================================= */

/**
 * @brief Create BCI parser instance (requires successful zkbrain_sec_init)
 * @return void* Parser handle or NULL on failure
 */
ZK_API void* zkbrain_parser_create();

/**
 * @brief Destroy parser instance and release memory
 * @param handle Parser handle
 */
ZK_API void zkbrain_parser_destroy(void* handle);

/**
 * @brief Reset parser state machine (e.g. on disconnect or reconnect)
 * @param handle Parser handle
 */
ZK_API void zkbrain_parser_reset(void* handle);

/**
 * @brief Feed raw byte stream from BLE Notify or Serial COM
 * @param handle Parser handle
 * @param data Byte buffer pointer
 * @param len Buffer length
 */
ZK_API void zkbrain_parser_parse(void* handle, const uint8_t* data, int len);

/**
 * @brief Register data callback listeners
 * 
 * @param handle Parser handle
 * @param onData Composite 1Hz EEG metrics callback
 * @param onRaw High-frequency raw wave callback (256Hz/512Hz)
 * @param onGravity 3-axis gravity callback (optional, can be NULL)
 * @param onRRInterval RR interval callback (optional, can be NULL)
 * @param onQuaternion 3D rotation quaternion callback (optional, can be NULL)
 * @param userData Custom context pointer passed back to callbacks
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
