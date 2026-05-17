package io.github.tissyboxc.widget

import android.appwidget.AppWidgetManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import io.github.tissyboxc.MainActivity
import io.github.tissyboxc.R
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

open class CourseWidgetProvider : HomeWidgetProvider() {
    protected open val fixedWidgetSize: WidgetSize? = null

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == WidgetContract.ACTION_PAGE) {
            val appWidgetId = intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID,
            )
            if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                val widgetSize = WidgetSize.from(
                    intent.getStringExtra(WidgetContract.EXTRA_WIDGET_SIZE),
                )
                val direction = intent.getIntExtra(WidgetContract.EXTRA_PAGE_DIRECTION, 1)
                    .coerceIn(-1, 1)
                    .takeIf { it != 0 } ?: 1
                val widgetData = HomeWidgetPlugin.getData(context)
                val payload = WidgetPayload.from(
                    context,
                    widgetData.getString(WidgetContract.PAYLOAD_KEY, null),
                )
                val rowCount = when (widgetSize) {
                    WidgetSize.SMALL -> payload.small.courseRows.size
                    WidgetSize.MEDIUM -> payload.medium.courseRows.size
                }
                val pageCount = pageCount(rowCount)
                val currentPage = pageIndex(context, appWidgetId, widgetSize, rowCount)
                val nextPage = if (pageCount <= 1) {
                    0
                } else {
                    (currentPage + direction).floorMod(pageCount)
                }
                savePageIndex(context, appWidgetId, widgetSize, nextPage)
                updateWidget(
                    context = context,
                    appWidgetManager = AppWidgetManager.getInstance(context),
                    appWidgetId = appWidgetId,
                    widgetData = widgetData,
                    options = null,
                )
            }
            return
        }
        super.onReceive(context, intent)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        updateWidgets(context, appWidgetManager, appWidgetIds, widgetData, null)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateWidget(
            context = context,
            appWidgetManager = appWidgetManager,
            appWidgetId = appWidgetId,
            widgetData = HomeWidgetPlugin.getData(context),
            options = newOptions,
        )
    }

    private fun updateWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
        options: Bundle?,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId, widgetData, options)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        widgetData: SharedPreferences,
        options: Bundle?,
    ) {
        val payload = WidgetPayload.from(
            context,
            widgetData.getString(WidgetContract.PAYLOAD_KEY, null),
        )
        val isMedium = when (fixedWidgetSize) {
            WidgetSize.SMALL -> false
            WidgetSize.MEDIUM -> true
            null -> isMediumWidget(appWidgetManager, appWidgetId, options)
        }
        val layoutId = if (isMedium) R.layout.widget_medium else R.layout.widget_small
        val views = RemoteViews(context.packageName, layoutId).apply {
            setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
        }

        if (isMedium) {
            bindMedium(views, payload.medium, context, appWidgetId)
        } else {
            bindSmall(views, payload.small, context, appWidgetId)
        }
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun isMediumWidget(
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        options: Bundle?,
    ): Boolean {
        val resolved = options ?: appWidgetManager.getAppWidgetOptions(appWidgetId)
        val width = resolved.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH)
        return width >= 260
    }

    private fun bindSmall(
        views: RemoteViews,
        state: WidgetPanelState,
        context: Context,
        appWidgetId: Int,
    ) {
        val pageRows = pageRows(context, appWidgetId, WidgetSize.SMALL, state.courseRows)
        val showContent = state.status == PanelStatus.READY && pageRows.isNotEmpty()
        views.setTextViewText(
            R.id.widget_small_date,
            compactDateText(context, state.dateText.ifBlank { todayHeaderText(context) }),
        )
        views.setTextViewText(R.id.widget_small_week, state.weekText)
        views.setViewVisibility(R.id.widget_small_content, if (showContent) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.widget_small_empty, if (showContent) View.GONE else View.VISIBLE)

        if (showContent) {
            bindCourseSlot(
                views = views,
                context = context,
                row = pageRows.getOrNull(0),
                ids = CourseSlotIds(
                    root = R.id.widget_small_page_row_1,
                    start = R.id.widget_small_page_start_1,
                    name = R.id.widget_small_page_name_1,
                    detail = R.id.widget_small_page_detail_1,
                ),
                pendingIntent = pagePendingIntent(
                    context,
                    appWidgetId,
                    WidgetSize.SMALL,
                    direction = -1,
                ),
            )
            bindCourseSlot(
                views = views,
                context = context,
                row = pageRows.getOrNull(1),
                ids = CourseSlotIds(
                    root = R.id.widget_small_page_row_2,
                    start = R.id.widget_small_page_start_2,
                    name = R.id.widget_small_page_name_2,
                    detail = R.id.widget_small_page_detail_2,
                ),
                pendingIntent = pagePendingIntent(
                    context,
                    appWidgetId,
                    WidgetSize.SMALL,
                    direction = 1,
                ),
            )
        } else {
            views.setTextViewText(
                R.id.widget_small_empty_title,
                if (state.status == PanelStatus.FINISHED) {
                    context.getString(R.string.course_widget_finished_title)
                } else {
                    context.getString(R.string.course_widget_empty_title)
                },
            )
            views.setTextViewText(
                R.id.widget_small_empty_message,
                state.message.ifBlank { context.getString(R.string.course_widget_empty_message) },
            )
        }
    }

    private fun bindMedium(
        views: RemoteViews,
        state: WidgetPanelState,
        context: Context,
        appWidgetId: Int,
    ) {
        val pageRows = pageRows(context, appWidgetId, WidgetSize.MEDIUM, state.courseRows)
        val showContent = state.status == PanelStatus.READY && pageRows.isNotEmpty()
        views.setTextViewText(
            R.id.widget_medium_date,
            state.dateText.ifBlank { todayHeaderText(context) },
        )
        views.setTextViewText(R.id.widget_medium_week, state.weekText)
        views.setViewVisibility(R.id.widget_medium_content, if (showContent) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.widget_medium_empty, if (showContent) View.GONE else View.VISIBLE)

        if (showContent) {
            bindCourseSlot(
                views = views,
                context = context,
                row = pageRows.getOrNull(0),
                ids = CourseSlotIds(
                    root = R.id.widget_medium_page_row_1,
                    start = R.id.widget_medium_page_start_1,
                    name = R.id.widget_medium_page_name_1,
                    detail = R.id.widget_medium_page_detail_1,
                ),
                pendingIntent = pagePendingIntent(
                    context,
                    appWidgetId,
                    WidgetSize.MEDIUM,
                    direction = -1,
                ),
            )
            bindCourseSlot(
                views = views,
                context = context,
                row = pageRows.getOrNull(1),
                ids = CourseSlotIds(
                    root = R.id.widget_medium_page_row_2,
                    start = R.id.widget_medium_page_start_2,
                    name = R.id.widget_medium_page_name_2,
                    detail = R.id.widget_medium_page_detail_2,
                ),
                pendingIntent = pagePendingIntent(
                    context,
                    appWidgetId,
                    WidgetSize.MEDIUM,
                    direction = 1,
                ),
            )
        } else {
            views.setTextViewText(R.id.widget_medium_empty_title, context.getString(R.string.course_widget_empty_title))
            views.setTextViewText(
                R.id.widget_medium_empty_message,
                state.message.ifBlank { context.getString(R.string.course_widget_empty_message) },
            )
        }
    }

    private fun pageRows(
        context: Context,
        appWidgetId: Int,
        widgetSize: WidgetSize,
        rows: List<WidgetCourseRow>,
    ): List<WidgetCourseRow> {
        if (rows.isEmpty()) {
            savePageIndex(context, appWidgetId, widgetSize, 0)
            savePageSignature(context, appWidgetId, widgetSize, "")
            return emptyList()
        }
        val signature = pageSignature(rows)
        val previousSignature = pagePrefs(context).getString(
            pageSignatureKey(appWidgetId, widgetSize),
            null,
        )
        if (previousSignature != signature) {
            savePageIndex(context, appWidgetId, widgetSize, 0)
            savePageSignature(context, appWidgetId, widgetSize, signature)
        }
        val page = pageIndex(context, appWidgetId, widgetSize, rows.size)
        val start = page * WidgetContract.PAGE_SIZE
        return rows.drop(start).take(WidgetContract.PAGE_SIZE)
    }

    private fun bindCourseSlot(
        views: RemoteViews,
        context: Context,
        row: WidgetCourseRow?,
        ids: CourseSlotIds,
        pendingIntent: PendingIntent,
    ) {
        views.setViewVisibility(ids.root, if (row == null) View.INVISIBLE else View.VISIBLE)
        views.setOnClickPendingIntent(ids.root, pendingIntent)
        if (row == null) {
            views.setTextViewText(ids.start, "")
            views.setTextViewText(ids.name, "")
            views.setTextViewText(ids.detail, "")
            return
        }
        views.setTextViewText(ids.start, row.startTimeText.ifBlank { row.lessonText })
        views.setTextViewText(ids.name, row.name)
        views.setTextViewText(ids.detail, row.lessonDetailText(context))
    }

    private fun pagePendingIntent(
        context: Context,
        appWidgetId: Int,
        widgetSize: WidgetSize,
        direction: Int,
    ): PendingIntent {
        val intent = Intent(context, javaClass).apply {
            action = WidgetContract.ACTION_PAGE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            putExtra(WidgetContract.EXTRA_WIDGET_SIZE, widgetSize.name)
            putExtra(WidgetContract.EXTRA_PAGE_DIRECTION, direction)
        }
        val sizeOffset = if (widgetSize == WidgetSize.MEDIUM) 4 else 2
        val directionOffset = if (direction > 0) 1 else 0
        val requestCode = appWidgetId * 10 + sizeOffset + directionOffset
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun pageIndex(
        context: Context,
        appWidgetId: Int,
        widgetSize: WidgetSize,
        rowCount: Int,
    ): Int {
        val pageCount = pageCount(rowCount)
        if (pageCount <= 1) {
            savePageIndex(context, appWidgetId, widgetSize, 0)
            return 0
        }
        val stored = pagePrefs(context).getInt(pageKey(appWidgetId, widgetSize), 0)
        return stored.coerceIn(0, pageCount - 1)
    }

    private fun savePageIndex(
        context: Context,
        appWidgetId: Int,
        widgetSize: WidgetSize,
        page: Int,
    ) {
        pagePrefs(context)
            .edit()
            .putInt(pageKey(appWidgetId, widgetSize), page.coerceAtLeast(0))
            .apply()
    }

    private fun savePageSignature(
        context: Context,
        appWidgetId: Int,
        widgetSize: WidgetSize,
        signature: String,
    ) {
        pagePrefs(context)
            .edit()
            .putString(pageSignatureKey(appWidgetId, widgetSize), signature)
            .apply()
    }

    private fun pagePrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(WidgetContract.PAGE_PREFS, Context.MODE_PRIVATE)
    }

    private fun pageKey(appWidgetId: Int, widgetSize: WidgetSize): String {
        return "${WidgetContract.PAGE_KEY_PREFIX}_${widgetSize.name}_$appWidgetId"
    }

    private fun pageSignatureKey(appWidgetId: Int, widgetSize: WidgetSize): String {
        return "${WidgetContract.PAGE_SIGNATURE_KEY_PREFIX}_${widgetSize.name}_$appWidgetId"
    }

    private fun pageSignature(rows: List<WidgetCourseRow>): String {
        return rows.joinToString("|") {
            "${it.startTimeText},${it.name},${it.lessonText},${it.roomText}"
        }
    }
}

private fun todayHeaderText(context: Context): String {
    val weekdays = arrayOf(
        context.getString(R.string.course_widget_weekday_sunday),
        context.getString(R.string.course_widget_weekday_monday),
        context.getString(R.string.course_widget_weekday_tuesday),
        context.getString(R.string.course_widget_weekday_wednesday),
        context.getString(R.string.course_widget_weekday_thursday),
        context.getString(R.string.course_widget_weekday_friday),
        context.getString(R.string.course_widget_weekday_saturday),
    )
    val weekday = Calendar.getInstance().get(Calendar.DAY_OF_WEEK)
    return context.getString(
        R.string.course_widget_date_today_weekday,
        weekdays[(weekday - 1).coerceIn(0, weekdays.lastIndex)],
    )
}

private fun compactDateText(context: Context, raw: String): String {
    return raw
        .replace(" / ", "/")
        .replace(
            context.getString(R.string.course_widget_weekday_prefix),
            context.getString(R.string.course_widget_weekday_compact_prefix),
        )
}

private fun pageCount(rowCount: Int): Int {
    return if (rowCount <= 0) {
        0
    } else {
        (rowCount + WidgetContract.PAGE_SIZE - 1) / WidgetContract.PAGE_SIZE
    }
}

private fun Int.floorMod(modulus: Int): Int {
    return Math.floorMod(this, modulus)
}

class WidgetUpdateReceiver : CourseWidgetProvider() {
    override val fixedWidgetSize = WidgetSize.SMALL
}

class WidgetMediumReceiver : CourseWidgetProvider() {
    override val fixedWidgetSize = WidgetSize.MEDIUM
}

enum class WidgetSize {
    SMALL,
    MEDIUM;

    companion object {
        fun from(raw: String?): WidgetSize {
            return when (raw) {
                SMALL.name -> SMALL
                MEDIUM.name -> MEDIUM
                else -> MEDIUM
            }
        }
    }
}

private object WidgetContract {
    const val PAYLOAD_KEY = "course_widget_payload"
    const val EXTRA_WIDGET_SIZE = "widget_size"
    const val ACTION_PAGE = "io.github.tissyboxc.widget.ACTION_PAGE"
    const val EXTRA_PAGE_DIRECTION = "page_direction"
    const val PAGE_PREFS = "course_widget_page_state"
    const val PAGE_KEY_PREFIX = "course_widget_page"
    const val PAGE_SIGNATURE_KEY_PREFIX = "course_widget_page_signature"
    const val PAGE_SIZE = 2
}

private data class CourseSlotIds(
    val root: Int,
    val start: Int,
    val name: Int,
    val detail: Int,
)

private data class WidgetPayload(
    val small: WidgetPanelState,
    val medium: WidgetPanelState,
) {
    companion object {
        fun from(context: Context, raw: String?): WidgetPayload {
            if (raw.isNullOrBlank()) {
                return WidgetPayload(
                    small = WidgetPanelState.empty(context),
                    medium = WidgetPanelState.empty(context),
                )
            }

            return try {
                val json = JSONObject(raw)
                WidgetPayload(
                    small = WidgetPanelState.from(context, json.optJSONObject("small")),
                    medium = WidgetPanelState.from(context, json.optJSONObject("medium")),
                )
            } catch (_: Exception) {
                WidgetPayload(
                    small = WidgetPanelState.error(
                        context.getString(R.string.course_widget_sync_failed),
                    ),
                    medium = WidgetPanelState.error(
                        context.getString(R.string.course_widget_sync_failed),
                    ),
                )
            }
        }
    }
}

private data class WidgetPanelState(
    val status: PanelStatus,
    val message: String = "",
    val dateText: String = "",
    val weekText: String = "",
    val nextCourse: WidgetCourse? = null,
    val courseRows: List<WidgetCourseRow> = emptyList(),
) {
    companion object {
        fun from(context: Context, json: JSONObject?): WidgetPanelState {
            if (json == null) {
                return empty(context)
            }

            val status = PanelStatus.from(json.optString("status"))
            val message = json.optString("message")
            val dateText = json.optString("dateText")
            val weekText = json.optString("weekText")
            val nextCourse = json.optJSONObject("nextCourse")?.let(WidgetCourse::from)
            val rows = json.optJSONArray("courseRows")?.let(WidgetCourseRow::from) ?: emptyList()
            return WidgetPanelState(status, message, dateText, weekText, nextCourse, rows)
        }

        fun empty(context: Context): WidgetPanelState {
            return WidgetPanelState(
                PanelStatus.EMPTY,
                context.getString(R.string.course_widget_no_courses_today),
            )
        }

        fun error(message: String): WidgetPanelState {
            return WidgetPanelState(PanelStatus.ERROR, message)
        }
    }
}

private enum class PanelStatus {
    READY,
    EMPTY,
    FINISHED,
    MISSING_TIMES,
    ERROR;

    companion object {
        fun from(raw: String?): PanelStatus {
            return when (raw?.lowercase()) {
                "ready" -> READY
                "empty" -> EMPTY
                "finished" -> FINISHED
                "missingtimes", "missing_times" -> MISSING_TIMES
                "error" -> ERROR
                else -> EMPTY
            }
        }
    }
}

private data class WidgetCourse(
    val name: String,
    val startTimeText: String,
    val timeText: String,
    val lessonText: String,
    val roomText: String,
    val remainingText: String,
) {
    fun lessonDetailText(context: Context): String {
        return listOf(lessonText, roomText)
            .filter {
                it.isNotBlank() &&
                    it != context.getString(R.string.course_widget_room_not_filled)
            }
            .joinToString("  ·  ")
            .ifBlank { timeText }
    }

    companion object {
        fun from(json: JSONObject?): WidgetCourse {
            return WidgetCourse(
                name = json?.optString("name").orEmpty(),
                startTimeText = json?.optString("startTimeText").orEmpty(),
                timeText = json?.optString("timeText").orEmpty(),
                lessonText = json?.optString("lessonText").orEmpty(),
                roomText = json?.optString("roomText").orEmpty(),
                remainingText = json?.optString("remainingText").orEmpty(),
            )
        }
    }
}

private data class WidgetCourseRow(
    val name: String,
    val startTimeText: String,
    val timeText: String,
    val lessonText: String,
    val roomText: String,
) {
    fun lessonDetailText(context: Context): String {
        return listOf(lessonText, roomText)
            .filter {
                it.isNotBlank() &&
                    it != context.getString(R.string.course_widget_room_not_filled)
            }
            .joinToString("  ·  ")
            .ifBlank { timeText }
    }

    companion object {
        fun from(array: JSONArray): List<WidgetCourseRow> {
            val rows = mutableListOf<WidgetCourseRow>()
            for (index in 0 until array.length()) {
                rows += from(array.optJSONObject(index))
            }
            return rows
        }

        private fun from(json: JSONObject?): WidgetCourseRow {
            return WidgetCourseRow(
                name = json?.optString("name").orEmpty(),
                startTimeText = json?.optString("startTimeText").orEmpty(),
                timeText = json?.optString("timeText").orEmpty(),
                lessonText = json?.optString("lessonText").orEmpty(),
                roomText = json?.optString("roomText").orEmpty(),
            )
        }
    }
}
