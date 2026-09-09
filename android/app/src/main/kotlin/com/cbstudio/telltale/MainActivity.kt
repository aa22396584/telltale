package com.cbstudio.telltale

import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.Bundle
import android.os.StatFs
import android.os.SystemClock
import android.util.Log
import io.flutter.BuildConfig as FlutterBuildConfig
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterShellArgs
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        applyRendererDecision()
        super.onCreate(savedInstanceState)
    }

    /**
     * Decides the rendering backend and initialises the Flutter loader with it,
     * before the engine exists.
     *
     * The engine picks Impeller on every API 29+ device but a Vivante GPU,
     * and has no route back to Skia at runtime: when Vulkan is missing it
     * falls to its own OpenGL ES backend, and on an Adreno 330 that backend
     * dies in the driver's shader linker before the first frame
     * (ImL1s/telltale#121). The only lever an app holds that reaches Skia is
     * `--enable-impeller=false`, and a manifest entry would pull every phone
     * onto it. So the decision is per device, made here, and passed as a
     * shell argument that the engine's parser lets win over the manifest.
     * [RendererPolicy] is the whole of the rule and is unit-tested on the
     * JVM; this method only carries its answer across.
     *
     * Why before `super.onCreate()`: `FlutterActivity.onCreate` attaches its
     * delegate, which builds a `FlutterEngineGroup`, which initialises the
     * loader only if nothing has yet — and `ensureInitializationComplete` is a
     * no-op once it has run. The first caller in the process decides, so this
     * has to be it. `FlutterEngine`'s own documentation names exactly this
     * sequence as the way to pass VM arguments.
     *
     * In release the arguments are ours alone. The default path also parses
     * launch-Intent extras into shell arguments, so an exported activity could
     * be started into Skia on a modern phone while this code logged
     * `impeller-default`; flutter/flutter#190461 is the engine's own plan to
     * stop honouring those extras in release, and until it lands this does. In
     * debug and profile the extras are kept because `flutter run` delivers its
     * flags through them, and ours go last so the denylist still wins.
     */
    private fun applyRendererDecision() {
        val decision = rendererDecision
        val loader = FlutterInjector.instance().flutterLoader()
        val initialised = loader.initialized()
        val applied = RendererPolicy.recordApplied(rendererApplied, initialised)
        if (initialised) {
            // Either this app applied the decision in an earlier activity of
            // this process (a warm relaunch), and it still stands; or
            // something else started the engine first, in which case the
            // decision was never applied and the metadata says so rather
            // than claiming a backend nobody asked for.
            rendererApplied = applied
            Log.i(
                TAG,
                if (applied) "renderer: ${decision.mode.label} (${decision.reason}), applied earlier in this process"
                else "renderer: ${decision.mode.label} not applied, engine initialised before MainActivity (${decision.reason})",
            )
            return
        }
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, toolingShellArgs() + decision.shellArgs)
        rendererApplied = applied
        Log.i(TAG, "renderer: ${decision.mode.label} (${decision.reason})")
    }

    /**
     * The Intent-carried flags `flutter run` uses in debug and profile, and
     * nothing in release. `FlutterShellArgs` is deprecated in favour of
     * manifest metadata and is used here only on the side the tool needs.
     */
    @Suppress("DEPRECATION")
    private fun toolingShellArgs(): Array<String> =
        if (FlutterBuildConfig.RELEASE) emptyArray() else FlutterShellArgs.fromIntent(intent).toArray()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PLATFORM_METADATA_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPlatformMetadata" -> result.success(platformMetadata())
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            APP_STORAGE_CAPACITY_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAvailableBytes" ->
                    appCacheAvailableBytes(call.argument<String>("path"), result)
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WIFI_ROUTE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "bind" -> bindWifiRoute(call.argument<String>("host"), result)
                "release" -> releaseWifiRoute(result)
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FORM_FACTOR_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                // The platform's own answer, not an inference from window
                // geometry: a narrow split-screen phone is still a phone.
                "isWatch" -> result.success(
                    packageManager.hasSystemFeature(
                        android.content.pm.PackageManager.FEATURE_WATCH,
                    ),
                )
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ELAPSED_REALTIME_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                // Includes deep sleep. Dart Stopwatch / uptimeMillis do not.
                "elapsedRealtimeMs" -> result.success(SystemClock.elapsedRealtime())
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SCREEN_WAKE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "keepOn" -> {
                    // A driving dashboard that dozes off mid-corner is worse
                    // than the battery it saves. Scoped to this window only:
                    // the flag clears with the activity, so a crash cannot
                    // leave the screen pinned on.
                    val on = call.argument<Boolean>("on") == true
                    if (on) {
                        window.addFlags(
                            android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                        )
                    } else {
                        window.clearFlags(
                            android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                        )
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Binds this process to a connected Wi-Fi network, validated or not.
     *
     * An ELM327 soft AP never validates — it has no internet — so requiring
     * NET_CAPABILITY_VALIDATED here would refuse the exact network this
     * exists for. When Android 12+ dual-STA (Samsung Intelligent Wi-Fi) has
     * two Wi-Fi networks up at once, the candidate whose link subnet actually
     * contains the adapter's address is tried first — binding succeeding says
     * nothing about the destination being reachable — then the unvalidated
     * ones, since the validated one is the home network. Error messages are
     * transcript detail, not screen text; the Dart side owns the user-facing
     * sentence.
     *
     * This handler MUST stay synchronous on the platform thread: the Dart
     * side compensates an abandoned (timed-out) bind by enqueuing a release
     * on this same channel, and that compensation is sound only because
     * channel messages execute here in arrival order. Offloading either call
     * to another thread silently breaks the orphaned-binding guarantee. Both
     * calls are short binder IPC, so staying synchronous is also correct for
     * responsiveness.
     */
    private fun bindWifiRoute(host: String?, result: MethodChannel.Result) {
        val manager = connectivityManagerOr(result) ?: return
        // allNetworks is deprecated in favor of an async callback API; a
        // synchronous snapshot is exactly what one bind-then-connect needs.
        @Suppress("DEPRECATION")
        val wifi = manager.allNetworks.mapNotNull { network ->
            val capabilities = manager.getNetworkCapabilities(network)
            if (capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) != true) {
                return@mapNotNull null
            }
            // A network still connecting has no link addresses yet and cannot
            // carry a socket; admitting it only manufactures spurious ties.
            val link = manager.getLinkProperties(network)
            if (link == null || link.linkAddresses.isEmpty()) {
                return@mapNotNull null
            }
            network to capabilities
        }
        if (wifi.isEmpty()) {
            result.error(
                "no_wifi_network",
                "ConnectivityManager reports no TRANSPORT_WIFI network",
                null,
            )
            return
        }
        // The Dart side only forwards numeric literals, but this handler must
        // stay synchronous, so it does not trust that contract with a blocking
        // DNS lookup on the line: anything that is not shaped like a literal
        // is dropped here too, and simply loses the reachability preference.
        val target = host?.takeIf(::isNumericHost)?.let {
            try {
                java.net.InetAddress.getByName(it)
            } catch (_: Exception) {
                null
            }
        }
        // ELM327 hosts are always on-link, so link subnets are the whole
        // route story here; gateway routes are deliberately not consulted.
        val keyed = wifi.map { (network, capabilities) ->
            val key = Pair(
                target != null && linkContains(manager, network, target),
                // Negated so the adapter-like (never validated) sorts higher.
                !capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED),
            )
            network to key
        }.sortedWith(
            compareByDescending<Pair<android.net.Network, Pair<Boolean, Boolean>>> { it.second.first }
                .thenByDescending { it.second.second },
        )
        // Binding succeeding proves nothing about the destination being
        // reachable, and allNetworks' order carries no routing meaning — so a
        // genuine tie at the top is a coin flip that, bound deterministically,
        // would time out the same way on every retry with the adapter taking
        // the blame. Refusing with a nameable reason is the honest outcome.
        val topKey = keyed.first().second
        val top = keyed.filter { it.second == topKey }
        if (top.size > 1) {
            result.error(
                "ambiguous_wifi_network",
                "${top.size} Wi-Fi networks are equally plausible routes " +
                    "toward the adapter",
                null,
            )
            return
        }
        // Only the unique top candidate is bound. Falling through to a
        // lower-ranked network would bind one already known not to reach the
        // adapter, hand back success, and spend the whole connect budget
        // timing out with the adapter taking the blame — the same failure
        // mode the tie refusal above exists to prevent.
        val (topNetwork, _) = keyed.first()
        if (!manager.bindProcessToNetwork(topNetwork)) {
            result.error(
                "bind_refused",
                "bindProcessToNetwork returned false for the selected " +
                    "Wi-Fi candidate",
                null,
            )
            return
        }
        result.success(null)
    }

    /**
     * IPv6 literals are colon-and-hex only (a v4-mapped tail adds dots);
     * anything else must be dotted-quad. `foo:bar` would fall through
     * InetAddress.getByName to a real DNS lookup, which this synchronous
     * handler must never perform.
     */
    private fun isNumericHost(host: String): Boolean = when {
        host.contains(':') -> host.all {
            it.isDigit() || it in 'a'..'f' || it in 'A'..'F' || it == ':' || it == '.'
        }
        else -> host.matches(Regex("""\d{1,3}(\.\d{1,3}){3}"""))
    }

    /** Whether one of [network]'s link subnets contains [target]. */
    private fun linkContains(
        manager: ConnectivityManager,
        network: android.net.Network,
        target: java.net.InetAddress,
    ): Boolean {
        val link = manager.getLinkProperties(network) ?: return false
        return link.linkAddresses.any { linkAddress ->
            sameSubnet(linkAddress.address, target, linkAddress.prefixLength)
        }
    }

    private fun sameSubnet(
        a: java.net.InetAddress,
        b: java.net.InetAddress,
        prefixLength: Int,
    ): Boolean {
        val left = a.address
        val right = b.address
        if (left.size != right.size) return false
        var bits = prefixLength
        for (i in left.indices) {
            if (bits <= 0) break
            val mask = if (bits >= 8) 0xFF else (0xFF shl (8 - bits)) and 0xFF
            if ((left[i].toInt() and mask) != (right[i].toInt() and mask)) return false
            bits -= 8
        }
        return true
    }

    private fun releaseWifiRoute(result: MethodChannel.Result) {
        val manager = connectivityManagerOr(result) ?: return
        if (!manager.bindProcessToNetwork(null)) {
            result.error(
                "release_refused",
                "bindProcessToNetwork(null) returned false",
                null,
            )
            return
        }
        result.success(null)
    }

    private fun appCacheAvailableBytes(
        path: String?,
        result: MethodChannel.Result,
    ) {
        try {
            val probePath = if (path.isNullOrEmpty()) cacheDir.path else path
            val bytes = StatFs(probePath).availableBytes
            if (bytes > 0L) {
                result.success(bytes)
            } else {
                result.error("capacity_invalid", "Available bytes were not positive", null)
            }
        } catch (error: Exception) {
            result.error("capacity_failed", error.message, null)
        }
    }

    private fun connectivityManagerOr(
        result: MethodChannel.Result,
    ): ConnectivityManager? {
        val manager = getSystemService(ConnectivityManager::class.java)
        if (manager == null) {
            result.error(
                "no_connectivity_service",
                "ConnectivityManager is unavailable",
                null,
            )
        }
        return manager
    }

    @Suppress("DEPRECATION")
    private fun platformMetadata(): Map<String, Any> {
        val packageInfo = packageManager.getPackageInfo(packageName, 0)
        val longVersionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageInfo.longVersionCode
        } else {
            packageInfo.versionCode.toLong()
        }

        return mapOf(
            "applicationId" to packageName,
            "appVersion" to (packageInfo.versionName ?: UNKNOWN),
            "appBuild" to longVersionCode.toString(),
            "platform" to "android",
            "osVersion" to (Build.VERSION.RELEASE ?: UNKNOWN),
            "manufacturer" to (Build.MANUFACTURER ?: UNKNOWN),
            "model" to (Build.MODEL ?: UNKNOWN),
            "sdkInt" to Build.VERSION.SDK_INT,
            // The backend this process asked for and why. `unknown` when the
            // decision was not the one applied, so an evidence file never says
            // `skia-forced` about a process that was started some other way.
            "renderer" to (if (rendererApplied == true) rendererDecision.mode.label else UNKNOWN),
            "rendererReason" to rendererDecision.reason +
                (if (rendererApplied == true) "" else " (not applied: engine initialised before this app decided)"),
        )
    }

    private companion object {
        const val TAG = "Telltale"

        /**
         * Decided once per process. A recreated activity must not re-read the
         * properties and relabel a process that is already rendering on one
         * backend; and below the engine's own API gate nothing is read at all,
         * because the engine picks Skia there without being asked.
         */
        val rendererDecision: RendererDecision by lazy {
            val sdk = Build.VERSION.SDK_INT
            if (sdk < RendererPolicy.MIN_API_FOR_IMPELLER) {
                RendererPolicy.decide(sdk, null, null)
            } else {
                // One deadline for both reads, so the budget is per process
                // and not per property. What it bounds, and what it does not,
                // is on [DeviceProperties.read].
                val deadline = System.nanoTime() + DeviceProperties.DEFAULT_BUDGET_NANOS
                val board = DeviceProperties.read(RendererPolicy.BOARD_PLATFORM, deadline)
                val vulkan = DeviceProperties.read(RendererPolicy.VULKAN_HARDWARE, deadline)
                // Which path answered is worth one line each: whether
                // reflection survives the hidden-API policy on a given
                // Android release is only ever known from a run in the app.
                Log.i(TAG, "property ${RendererPolicy.BOARD_PLATFORM} via ${board.via}")
                Log.i(TAG, "property ${RendererPolicy.VULKAN_HARDWARE} via ${vulkan.via}")
                RendererPolicy.decide(sdk, board.value, vulkan.value)
            }
        }

        /** Null until [applyRendererDecision] has run in this process. */
        @Volatile
        var rendererApplied: Boolean? = null

        const val PLATFORM_METADATA_CHANNEL = "com.cbstudio.telltale/platform_metadata"
        const val APP_STORAGE_CAPACITY_CHANNEL =
            "com.cbstudio.telltale/app_storage_capacity"
        const val WIFI_ROUTE_CHANNEL = "com.cbstudio.telltale/wifi_route"
        const val SCREEN_WAKE_CHANNEL = "com.cbstudio.telltale/screen_wake"
        const val ELAPSED_REALTIME_CHANNEL = "com.cbstudio.telltale/elapsed_realtime"
        const val FORM_FACTOR_CHANNEL = "com.cbstudio.telltale/form_factor"
        const val UNKNOWN = "unknown"
    }
}
