using UnityEngine;

namespace ZKBrain.Unity
{
    /// <summary>
    /// 🎮 脑控念力悬浮小球控制器 (Force Levitation Demo)
    /// 专注度 (Attention) 越高，物体悬浮越高，伴随粒子发光与色彩变化
    /// </summary>
    public class ForceLevitationController : MonoBehaviour
    {
        [Header("悬浮参数配置")]
        public float baseHeight = 0.5f;
        public float maxHeight = 4.0f;
        public float smoothSpeed = 3.0f;
        public Light auraLight;

        private float targetHeight;
        private Renderer objRenderer;

        private void Start()
        {
            objRenderer = GetComponent<Renderer>();
            targetHeight = baseHeight;

            if (ZKBrainBleBridge.Instance != null)
            {
                ZKBrainBleBridge.Instance.OnBrainMetricsUpdated += OnBrainMetrics;
            }
        }

        private void OnDestroy()
        {
            if (ZKBrainBleBridge.Instance != null)
            {
                ZKBrainBleBridge.Instance.OnBrainMetricsUpdated -= OnBrainMetrics;
            }
        }

        private void OnBrainMetrics(int attention, int meditation)
        {
            // 归一化注意力 (0~100) -> 目标悬浮高度
            float t = Mathf.Clamp01(attention / 100f);
            targetHeight = Mathf.Lerp(baseHeight, maxHeight, t);

            // 光源与发光材质反馈
            if (auraLight != null)
            {
                auraLight.intensity = t * 3.5f;
                auraLight.color = Color.Lerp(Color.blue, Color.yellow, t);
            }

            if (objRenderer != null && objRenderer.material.HasProperty("_EmissionColor"))
            {
                Color emission = Color.Lerp(Color.black, Color.cyan * 2f, t);
                objRenderer.material.SetColor("_EmissionColor", emission);
            }
        }

        private void Update()
        {
            // 平滑插值模拟物体悬浮与呼吸浮动
            Vector3 pos = transform.position;
            float floating = Mathf.Sin(Time.time * 2f) * 0.08f;
            pos.y = Mathf.Lerp(pos.y, targetHeight + floating, Time.deltaTime * smoothSpeed);
            transform.position = pos;

            // 缓慢旋转展示 3D 念力质感
            transform.Rotate(Vector3.up * (20f + targetHeight * 15f) * Time.deltaTime);
        }
    }
}
