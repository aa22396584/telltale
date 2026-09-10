package com.cbstudio.telltale

import android.os.Build
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.By
import androidx.test.uiautomator.UiDevice
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * #47 leftover: the OS share chooser Flutter integration_test cannot drive.
 *
 * Production file hand-off on Android is ACTION_SEND through the system
 * resolver. This test starts that chooser from the isolated rig package on
 * an AOSP emulator and asserts the resolver is the focused activity. It does
 * not select a recipient and does not run on the field applicationId.
 *
 * API 16+ ships ChooserActivity in `com.android.intentresolver`, not the
 * legacy `android:id/resolver_list` sheet. Waiting on that resource id is
 * a false negative while dumpsys still shows the chooser focused.
 */
@RunWith(AndroidJUnit4::class)
class ShareChooserInstrumentedTest {
    @Test
    fun productionShareIntentOpensOsChooser() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        assertEquals(
            "native share chooser is limited to the isolated rig package",
            "com.cbstudio.telltale.rig",
            context.packageName,
        )
        val fingerprint = Build.FINGERPRINT
        assertTrue(
            "native share chooser refuses non-AOSP fingerprints: $fingerprint",
            fingerprint.contains("sdk_gphone"),
        )

        val device = UiDevice.getInstance(instrumentation)
        dismissAnr(device)
        // Background startActivity from a test context is blocked on API 31+.
        // The shell ACTION_SEND is the same OS resolver Flutter cannot drive.
        // executeShellCommand is not a shell: quoted strings with spaces
        // become extra argv and `human` is parsed as pkg=human.
        device.executeShellCommand(
            "am start -a android.intent.action.SEND " +
                "-t text/plain " +
                "-f 0x10000000 " +
                "--es android.intent.extra.TEXT pid_value",
        )

        var shown = false
        val deadline = System.currentTimeMillis() + 15_000
        while (System.currentTimeMillis() < deadline) {
            dismissAnr(device)
            // Dumpsys can report the resolver focused before the sheet
            // draws. The host screenshot is taken after this test returns,
            // so leave the chooser up and require the visible list.
            if (chooserIsOnScreen(device) && chooserIsFocused(device)) {
                shown = true
                break
            }
            Thread.sleep(300)
        }
        assertTrue("OS share chooser did not appear", shown)
        device.waitForIdle(2_000)
    }

    private fun dismissAnr(device: UiDevice) {
        val wait = device.findObject(By.res("android", "aerr_wait"))
        if (wait != null) {
            wait.click()
        }
    }

    private fun chooserIsOnScreen(device: UiDevice): Boolean {
        return device.hasObject(By.pkg("com.android.intentresolver")) ||
            device.hasObject(By.res("android", "resolver_list")) ||
            device.hasObject(By.text("Share"))
    }

    private fun chooserIsFocused(device: UiDevice): Boolean {
        val dump = device.executeShellCommand("dumpsys activity activities")
        return dump.lineSequence().any { line ->
            (line.contains("topResumedActivity") || line.contains("mFocusedApp=")) &&
                (
                    line.contains("ChooserActivity") ||
                        line.contains("ResolverActivity") ||
                        line.contains("intentresolver")
                )
        }
    }
}
