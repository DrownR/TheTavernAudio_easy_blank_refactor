using UnityEngine;
using UnityEngine.UI;

public class SoundUI : MonoBehaviour
{
    [SerializeField] private VCA vca;

    [SerializeField] private Slider globalSlider;
    [SerializeField] private Slider musicSlider;
    [SerializeField] private Slider sfxSlider;


    private void Start()
    {
        globalSlider.onValueChanged.AddListener(delegate { OnMusicVolumeChanged("vca:/Global",globalSlider.value); });
        musicSlider.onValueChanged.AddListener(delegate { OnMusicVolumeChanged("vca:/Music", musicSlider.value); });
        sfxSlider.onValueChanged.AddListener(delegate { OnMusicVolumeChanged("vca:/SFX", sfxSlider.value); });
    }

    public void OnMusicVolumeChanged(string vcaPath, float value)
    {
        vca.ChangeVolume(vcaPath, value - 100f);
    }
}
