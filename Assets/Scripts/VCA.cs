using UnityEngine;

/// <summary>
/// Zarządza głośnością ścieżek audio poprzez FMOD VCAs.
/// </summary>
public class VCA : MonoBehaviour
{
    // FMOD - Referencje do VCAs.
    private FMOD.Studio.VCA globalVCA;
    private FMOD.Studio.VCA sfxVCA;
    private FMOD.Studio.VCA musicVCA;

    // Flagi stanu wyciszenia.
    [SerializeField]
    private bool globalMuteActive = true;
    [SerializeField]
    private bool musicMuteActive = false;
    [SerializeField]
    private bool tavernMuteActive = false;

    void Start()
    {
        // Pobiera VCAs z FMOD.
        globalVCA = FMODUnity.RuntimeManager.GetVCA("vca:/Global");
        sfxVCA = FMODUnity.RuntimeManager.GetVCA("vca:/Music");
        musicVCA = FMODUnity.RuntimeManager.GetVCA("vca:/SFX");
    }

    void Update()
    {
        // Sprawdza, czy klawisze zostały naciśnięte i wywołuje odpowiednią funkcję.
        if (Input.GetKeyDown(KeyCode.U))
        {
            ToggleMute(globalVCA, ref globalMuteActive);
        }
        if (Input.GetKeyDown(KeyCode.I))
        {
            ToggleMute(sfxVCA, ref musicMuteActive);
        }
        if (Input.GetKeyDown(KeyCode.O))
        {
            ToggleMute(musicVCA, ref tavernMuteActive);
        }
    }

    /// <summary>
    /// Przełącza głośność VCA na 0 dB (włączony) lub -100 dB (wyciszony).
    /// </summary>
    /// <param name="vca">VCA do przełączenia.</param>
    /// <param name="muteFlag">Zmienna stanu, która jest przełączana.</param>
    private void ToggleMute(FMOD.Studio.VCA vca, ref bool muteFlag)
    {
        muteFlag = !muteFlag; // Odwraca stan wyciszenia.
        float volume = muteFlag ? DecibelToLinear(-100) : DecibelToLinear(0);
        vca.setVolume(volume);
    }

    /// <summary>
    /// Konwertuje decybele na wartość liniową.
    /// </summary>
    private float DecibelToLinear(float dB)
    {
        return Mathf.Pow(10.0f, dB / 20f);
    }

    public void ChangeVolume(string vcaPath, float value)
    {
        FMODUnity.RuntimeManager.GetVCA(vcaPath).setVolume(DecibelToLinear(value));

    }
}