using UnityEngine;

public class CameraShake : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private Transform cameraTransform;
    [SerializeField] private CharacterController controller;

    [Header("Walk Bob")]
    [SerializeField] private float walkFrequency = 6f;
    [SerializeField] private float walkAmplitude = 0.04f;

    [Header("Run Bob")]
    [SerializeField] private float runFrequency = 10f;
    [SerializeField] private float runAmplitude = 0.08f;

    [Header("Smoothing")]
    [SerializeField] private float bobSmooth = 10f;
    [SerializeField] private float returnSmooth = 8f;

    [Header("Idle Sway")]
    [SerializeField] private float idleFrequency = 1f;
    [SerializeField] private float idleAmplitude = 0.01f;

    private Vector3 startLocalPosition;
    private float bobTimer;

    private void Start()
    {
        if (cameraTransform == null)
            cameraTransform = transform;

        startLocalPosition = cameraTransform.localPosition;
    }

    private void Update()
    {
        bool isMoving = controller.velocity.magnitude > 0.1f && controller.isGrounded;
        bool isRunning = Input.GetKey(KeyCode.LeftShift);

        bobTimer += Time.deltaTime;

        if (isMoving)
        {
            float frequency = isRunning ? runFrequency : walkFrequency;
            float amplitude = isRunning ? runAmplitude : walkAmplitude;

            float x = Mathf.Cos(bobTimer * frequency * 0.5f) * amplitude * 0.5f;
            float y = Mathf.Sin(bobTimer * frequency) * amplitude;

            Vector3 targetPosition = startLocalPosition + new Vector3(x, y, 0f);

            cameraTransform.localPosition = Vector3.Lerp(
                cameraTransform.localPosition,
                targetPosition,
                Time.deltaTime * bobSmooth
            );
        }
        else
        {
            float x = Mathf.Sin(bobTimer * idleFrequency * 0.7f) * idleAmplitude;
            float y = Mathf.Cos(bobTimer * idleFrequency) * idleAmplitude;

            Vector3 targetPosition = startLocalPosition + new Vector3(x, y, 0f);

            cameraTransform.localPosition = Vector3.Lerp(
                cameraTransform.localPosition,
                targetPosition,
                Time.deltaTime * returnSmooth
            );
        }
    }
}
