Pre-Info: This script does not work with Windows 10! It is also not tested with 24H2 yet. As 24H2 brings some changes to the language handling, the script might not work. This script works good in combination with “Confirm timezone, language and keyboard layout after Autopilot”. Check this out.

Expected result: The final outcome is that the user will have the correct keyboard layout available during the Autopilot process, and ideally, the correct language will be installed by the end of the setup. As an extension to this script, I will soon provide an additional script that will present the user with a window after installation, allowing them to confirm or adjust the settings for timezone, language, and keyboard layout.

Environment: Our devices are delivered with an English (en-us) operating system by default. Typically, our onsite support teams perform preprovisioning on new devices, during which they select the country and keyboard layout for the future user. However, there are also users who initiate the userdriven-Autopilot process themselves.

We have been looking for a way to leverage these preset values to automatically configure the keyboard layout and other regional settings. This ensures that the user can start working with the correct settings – especially the right keyboard layout – during Autopilot user enrollment, rather than being forced to use the default en-US layout.

Check my blog for more information: 
I borrowed some ideas from Alex Semibratov’s excellent “Full localization of Windows 10/11 from Autopilot” script, which, in turn, is based on Oliver Kieselbach’s “How to completely change Windows 10 language with Intune” script. You can find links to both solutions here. Thanks, Oliver and Alex, for your outstanding work!

https://www.linkedin.com/pulse/full-localization-windows-1011-from-autopilot-alex-semibratov/

https://oliverkieselbach.com/2020/04/22/how-to-completely-change-windows-10-language-with-intune/


Check my blog for more information about my solution: 

https://cmdctrl4u.wordpress.com/2025/03/14/change-language-and-keyboard-layout-during-autopilot-windows-11-23h2/
