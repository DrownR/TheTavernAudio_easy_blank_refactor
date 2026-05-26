using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class SoundUI : MonoBehaviour
{
    [SerializeField] private VCA vca;

    [SerializeField] private Slider globalSlider;
    [SerializeField] private TMP_Text globalSliderText;

    [SerializeField] private Slider musicSlider;
    [SerializeField] private TMP_Text musicSliderText;
    
    [SerializeField] private Slider sfxSlider;
    [SerializeField] private TMP_Text sfxSliderText;


    private void Start()
    {
        globalSlider.onValueChanged.AddListener(delegate { OnMusicVolumeChanged("vca:/Global",globalSlider.value, globalSliderText); });
        musicSlider.onValueChanged.AddListener(delegate { OnMusicVolumeChanged("vca:/Music", musicSlider.value, musicSliderText); });
        sfxSlider.onValueChanged.AddListener(delegate { OnMusicVolumeChanged("vca:/SFX", sfxSlider.value, sfxSliderText); });
    }

    public void OnMusicVolumeChanged(string vcaPath, float value, TMP_Text text)
    {
        vca.ChangeVolume(vcaPath, value - 100f);
        text.text = (int)value + "%";
    }
}
