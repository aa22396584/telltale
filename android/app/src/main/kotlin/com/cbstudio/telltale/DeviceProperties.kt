package com.cbstudio.telltale

import java.io.IOException
import java.lang.reflect.InvocationTargetException

/**
 * A property's value, or "", and which path produced it: reflection, a
 * `getprop` child, or no child at all because the deadline had already
 * passed when the subprocess path was reached.
 */
data class PropertyRead(val value: String, val via: String) {
    companion object {
        const val VIA_REFLECTION = "reflection"
        const val VIA_GETPROP = "getprop"
        const val VIA_DEADLINE_EXPIRED = "deadline-expired"
    }
}

/**
 * Reads `ro.*` system properties before the Flutter engine starts.
 *
 * `android.os.SystemProperties` is not SDK API, so it is asked through
 * reflection and any refusal — a hidden-API policy, a missing method, a
 * SecurityException — falls through to the `getprop` binary, which is the same
 * store the engine's own board check reads natively. Every failure returns "",
 * which [RendererPolicy] treats as unknown and never as a match: the worst
 * outcome of a broken read is a phone that keeps the engine's default.
 *
 * What the deadline bounds: the poll loop that waits for the child, which
 * stops at the deadline whether or not the child has exited. What it does not
 * bound, because nothing here can interrupt them: the spawn itself, and
 * `destroy()` afterwards — both are short in practice and neither is under
 * this code's control. `Process.waitFor` with a timeout needs API 26 and this
 * app supports 24, so the wait is a poll. The caller passes one deadline for
 * every read it makes, so the budget is per process.
 */
object DeviceProperties {
    private const val MAX_BYTES = 256
    private const val POLL_MS = 5L

    /** The whole budget for every property read in one process. */
    const val DEFAULT_BUDGET_NANOS = 250_000_000L

    /**
     * The value, or "", with the path that answered — the caller logs it,
     * because whether the reflection path survives the hidden-API policy on
     * a given Android release is something only a run inside the app shows.
     */
    fun read(name: String, deadlineNanos: Long = System.nanoTime() + DEFAULT_BUDGET_NANOS): PropertyRead {
        reflect(name)?.let { return PropertyRead(it.trim(), PropertyRead.VIA_REFLECTION) }
        return getprop(name, deadlineNanos)
    }

    /**
     * Every failure reflection can have is answered with null — the class or
     * method missing or refused (which is how the hidden-API policy says
     * no), a linkage or class-initialisation error, an access or argument
     * problem, a `SecurityException` — except a VM error: out of memory or
     * a stack overflow is not a property that could not be read, and it
     * propagates, including when the reflected call is what raised it.
     */
    private fun reflect(name: String): String? =
        try {
            val get = Class.forName("android.os.SystemProperties")
                .getMethod("get", String::class.java)
            get.invoke(null, name) as? String
        } catch (e: InvocationTargetException) {
            val cause = e.cause
            if (cause is VirtualMachineError) throw cause
            null
        } catch (_: ReflectiveOperationException) {
            null
        } catch (_: LinkageError) {
            null
        } catch (_: SecurityException) {
            null
        } catch (_: IllegalArgumentException) {
            null
        }

    /**
     * First line of `command name`, or "" when the child cannot be started,
     * or "" once the poll reaches [deadlineNanos] with the child still
     * running — each reported as `via getprop`. A deadline that has already
     * passed spawns nothing and says so, so the log never claims a child
     * that never ran.
     */
    internal fun getprop(name: String, deadlineNanos: Long, command: String = "getprop"): PropertyRead {
        if (System.nanoTime() >= deadlineNanos) {
            return PropertyRead("", PropertyRead.VIA_DEADLINE_EXPIRED)
        }
        return PropertyRead(spawn(name, deadlineNanos, command), PropertyRead.VIA_GETPROP)
    }

    private fun spawn(name: String, deadlineNanos: Long, command: String): String {
        val process =
            try {
                ProcessBuilder(command, name).redirectErrorStream(true).start()
            } catch (_: IOException) {
                return ""
            } catch (_: SecurityException) {
                return ""
            }
        try {
            val input = process.inputStream
            val out = StringBuilder()
            val buffer = ByteArray(64)
            fun drain() {
                while (input.available() > 0 && out.length < MAX_BYTES) {
                    val n = input.read(buffer, 0, minOf(buffer.size, MAX_BYTES - out.length))
                    if (n <= 0) return
                    out.append(String(buffer, 0, n, Charsets.UTF_8))
                }
            }
            while (System.nanoTime() < deadlineNanos) {
                drain()
                if (hasExited(process)) {
                    drain()
                    return out.lineSequence().firstOrNull()?.trim() ?: ""
                }
                Thread.sleep(POLL_MS)
            }
            return ""
        } catch (_: InterruptedException) {
            // Answer unknown, but do not eat the interrupt: whoever asked for
            // it still has to see it.
            Thread.currentThread().interrupt()
            return ""
        } catch (_: IOException) {
            return ""
        } finally {
            try {
                process.inputStream.close()
            } catch (_: IOException) {
                // The child may already be gone; there is nothing to do.
            }
            process.destroy()
        }
    }

    private fun hasExited(process: Process): Boolean =
        try {
            process.exitValue()
            true
        } catch (_: IllegalThreadStateException) {
            false
        }
}
