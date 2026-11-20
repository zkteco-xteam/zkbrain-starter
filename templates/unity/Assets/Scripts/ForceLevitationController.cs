using UnityEngine;

namespace ZKBrain.Unity
{
    /// <summary>
    /// Mind-Controlled Telekinesis Levitation Sphere Controller (Force Levitation Demo)
    /// Higher Attention floats the object higher with aura emission and color transitions.
    /// </summary>
    public class ForceLevitationController : MonoBehaviour
    {
        [Header("Levitation Configuration")]
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
            // Normalize attention (0-100) -> Target levitation height
            float t = Mathf.Clamp01(attention / 100f);
            targetHeight = Mathf.Lerp(baseHeight, maxHeight, t);

            // Light and emissive material feedback
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
            // Smooth interpolation simulating levitation and floating breath
            Vector3 pos = transform.position;
            float floating = Mathf.Sin(Time.time * 2f) * 0.08f;
            pos.y = Mathf.Lerp(pos.y, targetHeight + floating, Time.deltaTime * smoothSpeed);
            transform.position = pos;

            // Slow rotation for 3D telekinesis aesthetic
            transform.Rotate(Vector3.up * (20f + targetHeight * 15f) * Time.deltaTime);
        }
    }
}
