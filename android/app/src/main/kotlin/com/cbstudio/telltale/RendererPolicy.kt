package com.cbstudio.telltale

import java.util.Locale

/**
 * Which rendering backend this process asks Flutter for, decided before the
 * engine exists. `docs/platform-support.md`, "Rendering backend on Android",
 * says why the decision is the app's and not the engine's.
 */
enum class RendererMode(val label: String) {
    /**
     * Nothing overridden; the engine chooses. At API 29+ that is Impeller —
     * Vulkan, or its own OpenGL ES backend — except on a Vivante GPU
     * (`ro.hardware.egl`), where the engine itself picks Skia.
     */
    IMPELLER_DEFAULT("impeller-default"),

    /** `--enable-impeller=false` is passed, so the engine builds its Skia OpenGL ES surface. */
    SKIA_FORCED("skia-forced"),

    /** Below API 29 the engine selects Skia by itself; there is nothing to pass. */
    SKIA_ENGINE_DEFAULT("skia-engine-default"),
}

data class RendererDecision(val mode: RendererMode, val reason: String) {
    /** Shell arguments to append when initialising the Flutter loader. */
    val shellArgs: Array<String>
        get() = when (mode) {
            RendererMode.SKIA_FORCED -> arrayOf(DISABLE_IMPELLER_ARG)
            RendererMode.IMPELLER_DEFAULT, RendererMode.SKIA_ENGINE_DEFAULT -> emptyArray()
        }

    companion object {
        /**
         * `switches.cc` at the pinned engine enables Impeller only when the
         * value is literally `true`; anything else disables it. The Java layer
         * appends caller arguments after manifest metadata and the parser keeps
         * the last occurrence, so this beats a manifest `EnableImpeller`.
         */
        const val DISABLE_IMPELLER_ARG = "--enable-impeller=false"
    }
}

object RendererPolicy {
    /** `kMinimumAndroidApiLevelForImpeller` in the engine's `flutter_main.cc` at Flutter 3.47.0. */
    const val MIN_API_FOR_IMPELLER = 29

    /**
     * One of the two properties the Android Vulkan loader builds the driver
     * filename from, so `vulkan.msm8974.so` in the crash log means one of
     * them read `msm8974`. (The engine's own SoC check reads a third,
     * `ro.product.board`; it is not consulted here.)
     */
    const val BOARD_PLATFORM = "ro.board.platform"

    /** The other property the Vulkan loader derives the driver filename from. */
    const val VULKAN_HARDWARE = "ro.hardware.vulkan"

    /**
     * SoC platform strings whose GPU driver crashes inside Impeller's OpenGL ES
     * backend. Matched exactly after [normalise]; never by prefix, substring
     * or GPU vendor, because "no Vulkan" and "Adreno" both describe healthy
     * phones too.
     *
     * Every entry needs evidence — a tombstone from the device, or an engine
     * issue naming the silicon — because a false entry costs a healthy phone
     * Impeller and a missing one costs a launch:
     *
     *  - `msm8974` — Adreno 330, `libsc-a3xx.so`. SIGSEGV in `__link_shaders`
     *    under `libflutter.so` on a Samsung Note 3 (`hlte`) running DivestOS
     *    18.1, ImL1s/telltale#121; the same silicon as the Nexus 5 crash
     *    flutter/flutter#163675, whose fix was the API < 29 gate above — which an
     *    Android 11 build of the same phone walks straight past.
     */
    val impellerGlesCrashes: Set<String> = setOf("msm8974")

    fun decide(sdkInt: Int, boardPlatform: String?, vulkanHardware: String?): RendererDecision {
        if (sdkInt < MIN_API_FOR_IMPELLER) {
            return RendererDecision(
                RendererMode.SKIA_ENGINE_DEFAULT,
                "api $sdkInt is below $MIN_API_FOR_IMPELLER",
            )
        }
        val board = normalise(boardPlatform)
        val vulkan = normalise(vulkanHardware)
        // Both values are always in the reason, so an evidence file shows a
        // disagreement between the two properties instead of only the one
        // that matched.
        val values =
            "$BOARD_PLATFORM=${board.ifEmpty { "(empty)" }} " +
                "$VULKAN_HARDWARE=${vulkan.ifEmpty { "(empty)" }}"
        val matched = buildList {
            if (board in impellerGlesCrashes) add(BOARD_PLATFORM)
            if (vulkan in impellerGlesCrashes) add(VULKAN_HARDWARE)
        }
        if (matched.isNotEmpty()) {
            return RendererDecision(
                RendererMode.SKIA_FORCED,
                "$values matched=${matched.joinToString(",")}",
            )
        }
        return RendererDecision(RendererMode.IMPELLER_DEFAULT, values)
    }

    /** Trimmed and lower-cased in the root locale; null and blank both become "". */
    fun normalise(value: String?): String = value?.trim()?.lowercase(Locale.ROOT) ?: ""

    /**
     * Whether the decision is the one this process is running on, after an
     * activity has asked to apply it.
     *
     * The loader is a process singleton and initialises once. The first
     * activity in a process finds it uninitialised, applies the decision, and
     * the answer is `true`. A later activity in the same process — back out,
     * leave the process cached, tap the icon again — finds it initialised
     * *because this app initialised it*, and the answer must stay `true`:
     * relabelling that launch `unknown` would drop the one fact this exists
     * to record, on the second launch of every session. Only an activity
     * that finds the loader initialised with no decision recorded in this
     * process (`previous == null`) reports `false`: something else started
     * the engine first.
     */
    fun recordApplied(previous: Boolean?, loaderInitialized: Boolean): Boolean =
        if (!loaderInitialized) true else previous ?: false
}
