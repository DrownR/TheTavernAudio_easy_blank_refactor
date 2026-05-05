using UnityEngine;

public class LightFlicker : MonoBehaviour
{
    public float maxRange = 11;
    public float minRange = 6;
    public float flickerSpeed = 0.5f;

    private Light lightSource;

    public void Start()
    {
        lightSource = GetComponent<Light>();
    }

    public void Update()
    {
        if(lightSource == null)
        {
            Debug.Log($"No light source on Object {gameObject.name}");
            return;
        }
        lightSource.intensity = Mathf.Lerp(minRange, maxRange, Mathf.PingPong(Time.time, flickerSpeed));
    }
}