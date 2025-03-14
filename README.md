# ChangeLanguageDuringAutopilot

Pre-Info: This script does not work with Windows 10! It is also not tested with 24H2 yet. As 24H2 brings some changes to the language handling, the script might not work. This script works good in combination with “Confirm timezone, language and keyboard layout after Autopilot”. Check this out.

Expected result: The final outcome is that the user will have the correct keyboard layout available during the Autopilot process, and ideally, the correct language will be installed by the end of the setup. As an extension to this script, I will soon provide an additional script that will present the user with a window after installation, allowing them to confirm or adjust the settings for timezone, language, and keyboard layout.

Environment: Our devices are delivered with an English (en-us) operating system by default. Typically, our onsite support teams perform preprovisioning on new devices, during which they select the country and keyboard layout for the future user. However, there are also users who initiate the userdriven-Autopilot process themselves.

We have been looking for a way to leverage these preset values to automatically configure the keyboard layout and other regional settings. This ensures that the user can start working with the correct settings – especially the right keyboard layout – during Autopilot user enrollment, rather than being forced to use the default en-US layout.

Check my blog for more information: 

https://cmdctrl4u.wordpress.com/2025/03/14/change-language-and-keyboard-layout-during-autopilot-windows-11-23h2/
