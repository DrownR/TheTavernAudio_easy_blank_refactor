using System;
using UnityEngine;

public class MenuManager : MonoBehaviour
{
    [SerializeField] private GameObject menu;
    private bool isMenuOpened = false;

    public static Action<bool> OnMenuOpened;

    private void OnEnable()
    {
        MenuManager.OnMenuOpened += OnMenuOpen;

    }

    private void OnDisable()
    {
        MenuManager.OnMenuOpened -= OnMenuOpen;
    }

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            TriggerMenu();
        }
    }

    public void TriggerMenu()
    {
        isMenuOpened = !isMenuOpened;

        OnMenuOpened?.Invoke(isMenuOpened);
    }

    private void OnMenuOpen(bool value)
    {
        menu.SetActive(isMenuOpened);

        Cursor.lockState = value ? CursorLockMode.None : CursorLockMode.Locked;
        Cursor.visible = value ? true : false;
    }
}
