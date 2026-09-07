package com.cbstudio.telltale

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class RendererPolicyTest {
    private fun decide(sdk: Int = 30, board: String? = null, vulkan: String? = null) =
        RendererPolicy.decide(sdk, board, vulkan)

    @Test
    fun `the reporter's phone is forced to Skia through the board platform`() {
        val d = decide(sdk = 30, board = "msm8974", vulkan = "")
        assertEquals(RendererMode.SKIA_FORCED, d.mode)
        assertEquals("ro.board.platform=msm8974 ro.hardware.vulkan=(empty) matched=ro.board.platform", d.reason)
        assertArrayEquals(arrayOf("--enable-impeller=false"), d.shellArgs)
    }

    @Test
    fun `the vulkan property matches on its own`() {
        val d = decide(sdk = 30, board = "", vulkan = "msm8974")
        assertEquals(RendererMode.SKIA_FORCED, d.mode)
        assertEquals("ro.board.platform=(empty) ro.hardware.vulkan=msm8974 matched=ro.hardware.vulkan", d.reason)
    }

    @Test
    fun `when both properties match the reason names both`() {
        val d = decide(sdk = 30, board = "msm8974", vulkan = "msm8974")
        assertEquals(RendererMode.SKIA_FORCED, d.mode)
        assertEquals("ro.board.platform=msm8974 ro.hardware.vulkan=msm8974 matched=ro.board.platform,ro.hardware.vulkan", d.reason)
    }

    @Test
    fun `a conflicting other property does not undo a match, and stays visible in the reason`() {
        val d = decide(sdk = 30, board = "msm8974", vulkan = "adreno")
        assertEquals(RendererMode.SKIA_FORCED, d.mode)
        assertEquals("ro.board.platform=msm8974 ro.hardware.vulkan=adreno matched=ro.board.platform", d.reason)
        val e = decide(sdk = 30, board = "pineapple", vulkan = "msm8974")
        assertEquals(RendererMode.SKIA_FORCED, e.mode)
        assertEquals("ro.board.platform=pineapple ro.hardware.vulkan=msm8974 matched=ro.hardware.vulkan", e.reason)
    }

    @Test
    fun `a modern Qualcomm phone keeps Impeller`() {
        // Galaxy S24 Ultra, read on the device.
        val d = decide(sdk = 36, board = "pineapple", vulkan = "adreno")
        assertEquals(RendererMode.IMPELLER_DEFAULT, d.mode)
        assertArrayEquals(emptyArray<String>(), d.shellArgs)
        assertEquals("ro.board.platform=pineapple ro.hardware.vulkan=adreno", d.reason)
    }

    @Test
    fun `the emulator keeps the engine's own choice`() {
        // sdk_gphone64_arm64, read on the emulator: the platform is unset there.
        val d = decide(sdk = 36, board = "", vulkan = "ranchu")
        assertEquals(RendererMode.IMPELLER_DEFAULT, d.mode)
        assertEquals("ro.board.platform=(empty) ro.hardware.vulkan=ranchu", d.reason)
    }

    @Test
    fun `unknown is not a match`() {
        assertEquals(RendererMode.IMPELLER_DEFAULT, decide(sdk = 30, board = null, vulkan = null).mode)
        assertEquals(RendererMode.IMPELLER_DEFAULT, decide(sdk = 30, board = "", vulkan = "").mode)
        assertEquals(RendererMode.IMPELLER_DEFAULT, decide(sdk = 30, board = "   ", vulkan = "\n").mode)
    }

    @Test
    fun `a lookalike is not a match`() {
        for (value in listOf("msm8974pro", "xmsm8974", "msm 8974", "8974", "msm8974,other", "adreno330")) {
            assertEquals(value, RendererMode.IMPELLER_DEFAULT, decide(sdk = 30, board = value, vulkan = value).mode)
        }
    }

    @Test
    fun `case and surrounding whitespace do not defeat the match`() {
        val d = decide(sdk = 30, board = " MSM8974\n", vulkan = "")
        assertEquals(RendererMode.SKIA_FORCED, d.mode)
        assertEquals("ro.board.platform=msm8974 ro.hardware.vulkan=(empty) matched=ro.board.platform", d.reason)
    }

    @Test
    fun `below API 29 nothing is passed because the engine already picks Skia`() {
        val d = decide(sdk = 28, board = "msm8974", vulkan = "msm8974")
        assertEquals(RendererMode.SKIA_ENGINE_DEFAULT, d.mode)
        assertArrayEquals(emptyArray<String>(), d.shellArgs)
        assertEquals("api 28 is below 29", d.reason)
    }

    @Test
    fun `API 29 itself is on the Impeller side of the gate`() {
        assertEquals(RendererMode.IMPELLER_DEFAULT, decide(sdk = 29, board = "pineapple", vulkan = "adreno").mode)
        assertEquals(RendererMode.SKIA_FORCED, decide(sdk = 29, board = "msm8974", vulkan = "").mode)
    }

    @Test
    fun `the first activity in a process applies the decision`() {
        assertEquals(true, RendererPolicy.recordApplied(previous = null, loaderInitialized = false))
    }

    @Test
    fun `a warm relaunch keeps the decision this app already applied`() {
        // Back out, leave the process cached, tap the icon again: the loader
        // is initialised because this app initialised it, and the answer
        // must not become unknown on the second launch of every session.
        assertEquals(true, RendererPolicy.recordApplied(previous = true, loaderInitialized = true))
    }

    @Test
    fun `an engine started by something else is reported as not applied`() {
        assertEquals(false, RendererPolicy.recordApplied(previous = null, loaderInitialized = true))
        assertEquals(false, RendererPolicy.recordApplied(previous = false, loaderInitialized = true))
    }

    @Test
    fun `every denylist entry is already in normalised form, so a match is reachable`() {
        assertTrue(RendererPolicy.impellerGlesCrashes.isNotEmpty())
        for (entry in RendererPolicy.impellerGlesCrashes) {
            assertEquals(entry, RendererPolicy.normalise(entry))
            assertTrue(entry, entry.isNotBlank())
            assertEquals(RendererMode.SKIA_FORCED, decide(sdk = 30, board = entry, vulkan = "").mode)
        }
    }
}

class DevicePropertiesTest {
    @Test
    fun `a JVM with neither the Android class nor getprop reads as unknown without throwing`() {
        // On the build machine and in CI there is no android.os.SystemProperties
        // and no getprop binary, so both paths fail — the value must be "",
        // which the policy treats as unknown rather than as a match.
        val read = DeviceProperties.read("ro.board.platform")
        assertEquals("", read.value)
        assertEquals(PropertyRead.VIA_GETPROP, read.via)
    }

    @Test
    fun `the subprocess path returns the command's first line`() {
        val deadline = System.nanoTime() + 2_000_000_000L
        val read = DeviceProperties.getprop("msm8974", deadline, command = "echo")
        assertEquals("msm8974", read.value)
        assertEquals(PropertyRead.VIA_GETPROP, read.via)
    }

    @Test
    fun `the subprocess path gives up within a few polls of the deadline, not when the child exits`() {
        // The child sleeps five seconds; the deadline is 150 ms. What the poll
        // loop can promise is "deadline plus one poll plus the spawn"; 750 ms
        // leaves room for a slow CI runner and is still an order of magnitude
        // short of the child, so an implementation that waited for the child
        // fails and one that ignored the deadline for a fixed second fails too.
        val started = System.nanoTime()
        val read = DeviceProperties.getprop("5", started + 150_000_000L, command = "sleep")
        val elapsedMs = (System.nanoTime() - started) / 1_000_000
        assertEquals("", read.value)
        assertEquals(PropertyRead.VIA_GETPROP, read.via)
        assertTrue("took ${elapsedMs}ms", elapsedMs < 750)
    }

    @Test
    fun `an already expired deadline spawns nothing, and says so`() {
        // Not a clock: a spawn of `sleep` returns in well under 50 ms, so an
        // elapsed-time bound could not tell "spawned nothing" from "spawned
        // and gave up". The path reports itself instead.
        val read = DeviceProperties.getprop("5", System.nanoTime() - 1L, command = "sleep")
        assertEquals("", read.value)
        assertEquals(PropertyRead.VIA_DEADLINE_EXPIRED, read.via)
    }

    @Test
    fun `a command that does not exist reads as unknown`() {
        val read = DeviceProperties.getprop("x", System.nanoTime() + 1_000_000_000L, command = "no-such-binary-telltale")
        assertEquals("", read.value)
        assertEquals(PropertyRead.VIA_GETPROP, read.via)
    }
}
