package com.cbstudio.telltale

/**
 * Per-app locale override on Android 13+.
 *
 * [android.app.LocaleManager.applicationLocales] is the authority. An empty
 * [LocaleList] means follow the system; it is not English. Configuration
 * locales after an override are the override, not the original system list —
 * this policy never infers the pre-override system from `Locale.getDefault`.
 *
 * Supported tags are the UI locales Dart actually maps, matching
 * `res/xml/locales_config.xml`.
 */
data class AppLocaleOverride(
    val followsSystem: Boolean,
    val tags: List<String>,
) {
    init {
        require(followsSystem == tags.isEmpty()) {
            "follow-system is the empty list, not a default language"
        }
    }
}

data class AppLocaleMigration(
    val action: AppLocalePolicy.MigrationAction,
    val tagsToApply: List<String>,
    val storedIdToKeep: String,
    val writeToOs: Boolean,
)

object AppLocalePolicy {
    const val MIN_API = 33

    val supportedTags: List<String> = listOf("en", "zh-Hant", "de")

    private val supportedTagSet: Set<String> = supportedTags.toSet()

    fun apiSupported(sdkInt: Int): Boolean = sdkInt >= MIN_API

    fun overrideFromRequestedTags(tags: List<String>): AppLocaleOverride? {
        if (tags.isEmpty()) {
            return AppLocaleOverride(followsSystem = true, tags = emptyList())
        }
        val normalised = ArrayList<String>(tags.size)
        val seen = HashSet<String>()
        for (raw in tags) {
            val tag = mapToSupported(raw) ?: return null
            if (seen.add(tag)) normalised.add(tag)
        }
        if (normalised.isEmpty()) {
            return AppLocaleOverride(followsSystem = true, tags = emptyList())
        }
        return AppLocaleOverride(followsSystem = false, tags = normalised)
    }

    fun overrideFromLocaleListTags(tags: List<String>): AppLocaleOverride {
        val kept = tags.map { it.trim() }.filter { it.isNotEmpty() }
        if (kept.isEmpty()) {
            return AppLocaleOverride(followsSystem = true, tags = emptyList())
        }
        return AppLocaleOverride(followsSystem = false, tags = kept)
    }

    fun languageTagsForLocaleList(override: AppLocaleOverride): String =
        if (override.followsSystem) "" else override.tags.joinToString(",")

    fun tagsFromStoredId(storedId: String): List<String> =
        when (storedId) {
            "en" -> listOf("en")
            "zh_Hant" -> listOf("zh-Hant")
            "de" -> listOf("de")
            else -> emptyList()
        }

    fun storedIdFromSupportedTag(tag: String): String =
        when (tag) {
            "en" -> "en"
            "zh-Hant" -> "zh_Hant"
            "de" -> "de"
            else -> "system"
        }

    enum class MigrationAction {
        USE_OS_OVERRIDE,
        HANDOFF_STORED_ONCE,
        FOLLOW_SYSTEM,
    }

    fun migrate(osOverrideTags: List<String>, storedId: String): AppLocaleMigration {
        val os = overrideFromLocaleListTags(osOverrideTags)
        if (!os.followsSystem) {
            val mapped = os.tags.mapNotNull(::mapToSupported).distinct()
            val stored = if (mapped.size == 1) storedIdFromSupportedTag(mapped.single()) else "system"
            return AppLocaleMigration(
                action = MigrationAction.USE_OS_OVERRIDE,
                tagsToApply = os.tags,
                storedIdToKeep = stored,
                writeToOs = false,
            )
        }
        val handoff = tagsFromStoredId(storedId)
        if (handoff.isNotEmpty()) {
            return AppLocaleMigration(
                action = MigrationAction.HANDOFF_STORED_ONCE,
                tagsToApply = handoff,
                storedIdToKeep = storedId,
                writeToOs = true,
            )
        }
        return AppLocaleMigration(
            action = MigrationAction.FOLLOW_SYSTEM,
            tagsToApply = emptyList(),
            storedIdToKeep = "system",
            writeToOs = false,
        )
    }

    /**
     * Map a BCP-47 tag onto a shipped UI locale, or null.
     *
     * Script beats a conflicting region: `zh-Hans-TW` is still Hans and is
     * not 繁體中文. `de-AT` / `de-CH` are German. Unknown languages stay
     * unknown so a Japanese OS override is not silently rewritten to English.
     */
    fun mapToSupported(raw: String): String? {
        val tag = raw.trim().replace('_', '-')
        if (tag.isEmpty()) return null
        val parts = tag.split('-').filter { it.isNotEmpty() }
        if (parts.isEmpty()) return null
        val language = parts[0].lowercase()
        if (language == "en") return "en"
        if (language == "de") return "de"
        if (language != "zh") return null
        val subtags = parts.drop(1)
        val script = subtags.firstOrNull { it.length == 4 }?.lowercase()
        if (script == "hans") return null
        if (script == "hant") return "zh-Hant"
        val region = subtags.firstOrNull { it.length == 2 }?.uppercase()
        if (region == "TW" || region == "HK" || region == "MO") return "zh-Hant"
        if (subtags.isEmpty()) return "zh-Hant"
        return null
    }
}
