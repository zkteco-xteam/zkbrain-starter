#ifndef ZKBRAIN_PARSER_CORE_H
#define ZKBRAIN_PARSER_CORE_H

#include <stdint.h>
#include <functional>

#if defined(_WIN32)
#define ZKBRAIN_EXPORT __declspec(dllexport)
#else
#define ZKBRAIN_EXPORT
#endif

class ZKBRAIN_EXPORT ZKBrainParserCore {
public:
    ZKBrainParserCore();
    inline ~ZKBrainParserCore() {}

    void parseBytes(const uint8_t* buffer, int length);
    void parseCustomFff8Packet(const uint8_t* buffer, int length);
    void parseMindRawPacket(const uint8_t* buffer, int length);
    void reset();
    void setDeviceMode(int mode); // 0 = 自动探测自愈, 1 = 强制ThinkGear协议流(如zk_teco), 2 = 强制MindWave纯20字节裸流

    using OnBrainDataCallback = std::function<void(const int* int_data, double hw_version, float temp)>;
    using OnRawWaveCallback = std::function<void(int raw_wave)>;
    using OnGravityCallback = std::function<void(int x, int y, int z)>;
    using OnRRIntervalCallback = std::function<void(const int* rr_data, int len)>;
    using OnQuaternionCallback = std::function<void(float q0, float q1, float q2, float q3)>;

    void setCallbacks(OnBrainDataCallback onBrainData,
                      OnRawWaveCallback onRawWave,
                      OnGravityCallback onGravity = nullptr,
                      OnRRIntervalCallback onRRInterval = nullptr,
                      OnQuaternionCallback onQuaternion = nullptr);

private:
    int parserStatus;
    int payloadLength;
    int payloadBytesReceived;
    int payloadSum;
    int checksum;
    uint8_t payload[1024];
    int higCRC;
    float preTemperature;

    // 🌟 协议流模式探测与锁定：0 = AUTO (自适应), 1 = THINKGEAR (自研/ThinkGear协议), 2 = MINDWAVE_RAW (MindWave纯20字节裸流)
    int m_streamMode;
    int m_thinkgear_packet_count;
    int m_mindwave_raw_count;

    // 🌟 FFF8 自定义包状态缓存
    int customSignal;
    int m_lastSignal;
    int customAttention;
    int customMeditation;
    int customDelta;
    int customTheta;
    int customLowAlpha;
    int customHighAlpha;
    int customLowBeta;
    int customHighBeta;
    int customLowGamma;
    int customMidGamma;

    // 🌟 优化：极速权限缓存器
    uint32_t m_auth_check_tick;
    bool m_can_raw_eeg;
    bool m_can_attention;
    bool m_can_meditation;
    bool m_can_eeg_power;

    OnBrainDataCallback m_onBrainData;
    OnRawWaveCallback m_onRawWave;
    OnGravityCallback m_onGravity;
    OnRRIntervalCallback m_onRRInterval;
    OnQuaternionCallback m_onQuaternion;

    void parseByte(uint8_t byteValue);
    void parsePacketPayload();
    void parseHRVPacketPayload();
    int getEEGPower(uint8_t highByte, uint8_t midByte, uint8_t lowByte);
    void crc16Calc1021(const uint8_t* bytes, int len, uint8_t& outHigh, uint8_t& outLow);
};

#endif // ZKBRAIN_PARSER_CORE_H