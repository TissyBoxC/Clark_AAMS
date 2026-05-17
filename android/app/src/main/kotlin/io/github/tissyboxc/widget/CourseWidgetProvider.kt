package io.github.tissyboxc.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
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

open class CourseWidgetProvider : HomeWidgetProvider() {
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
        val payload = WidgetPayload.from(widgetData.getString(WidgetContract.PAYLOAD_KEY, null))
        val isMedium = isMediumWidget(appWidgetManager, appWidgetId, options)
        val layoutId = if (isMedium) R.layout.widget_medium else R.layout.widget_small
        val views = RemoteViews(context.packageName, layoutId).apply {
            setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
        }

        if (isMedium) {
            bindMedium(views, payload.medium, context)
        } else {
            bindSmall(views, payload.small, context)
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
        val height = resolved.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT)
        return width >= 260 || height >= 170
    }

    private fun bindSmall(
        views: RemoteViews,
        state: WidgetPanelState,
        context: Context,
    ) {
        val showContent = state.status == PanelStatus.READY && state.nextCourse != null
        views.setViewVisibility(R.id.widget_small_content, if (showContent) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.widget_small_empty, if (showContent) View.GONE else View.VISIBLE)

        if (showContent) {
            val nextCourse = state.nextCourse ?: return
            views.setTextViewText(
                R.id.widget_small_section,
                context.getString(R.string.course_widget_small_title),
            )
            views.setTextViewText(R.id.widget_small_course_name, nextCourse.name)
            views.setTextViewText(R.id.widget_small_course_time, nextCourse.timeText)
            views.setTextViewText(R.id.widget_small_course_room, nextCourse.roomText)
            views.setTextViewText(R.id.widget_small_course_remaining, nextCourse.remainingText)
        } else {
            views.setTextViewText(R.id.widget_small_empty_title, context.getString(R.string.course_widget_empty_title))
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
    ) {
        val showContent = state.status == PanelStatus.READY && state.courseRows.isNotEmpty()
        views.setViewVisibility(R.id.widget_medium_content, if (showContent) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.widget_medium_empty, if (showContent) View.GONE else View.VISIBLE)

        if (showContent) {
            views.setTextViewText(
                R.id.widget_medium_section,
                context.getString(R.string.course_widget_medium_title),
            )

            val rows = listOf(
                RowIds(R.id.widget_medium_row_1, R.id.widget_medium_name_1, R.id.widget_medium_detail_1),
                RowIds(R.id.widget_medium_row_2, R.id.widget_medium_name_2, R.id.widget_medium_detail_2),
                RowIds(R.id.widget_medium_row_3, R.id.widget_medium_name_3, R.id.widget_medium_detail_3),
                RowIds(R.id.widget_medium_row_4, R.id.widget_medium_name_4, R.id.widget_medium_detail_4),
            )

            rows.forEachIndexed { index, rowIds ->
                val row = state.courseRows.getOrNull(index)
                if (row == null) {
                    views.setViewVisibility(rowIds.containerId, View.GONE)
                } else {
                    views.setViewVisibility(rowIds.containerId, View.VISIBLE)
                    views.setTextViewText(rowIds.nameId, row.name)
                    views.setTextViewText(rowIds.detailId, "${row.timeText}  ·  ${row.roomText}")
                }
            }
        } else {
            views.setTextViewText(R.id.widget_medium_empty_title, context.getString(R.string.course_widget_empty_title))
            views.setTextViewText(
                R.id.widget_medium_empty_message,
                state.message.ifBlank { context.getString(R.string.course_widget_empty_message) },
            )
        }
    }
}

class WidgetUpdateReceiver : CourseWidgetProvider()

private object WidgetContract {
    const val PAYLOAD_KEY = "course_widget_payload"
}

private data class WidgetPayload(
    val small: WidgetPanelState,
    val medium: WidgetPanelState,
) {
    companion object {
        fun from(raw: String?): WidgetPayload {
            if (raw.isNullOrBlank()) {
                return WidgetPayload(
                    small = WidgetPanelState.empty(),
                    medium = WidgetPanelState.empty(),
                )
            }

            return try {
                val json = JSONObject(raw)
                WidgetPayload(
                    small = WidgetPanelState.from(json.optJSONObject("small")),
                    medium = WidgetPanelState.from(json.optJSONObject("medium")),
                )
            } catch (_: Exception) {
                WidgetPayload(
                    small = WidgetPanelState.error("数据同步失败"),
                    medium = WidgetPanelState.error("数据同步失败"),
                )
            }
        }
    }
}

private data class WidgetPanelState(
    val status: PanelStatus,
    val message: String = "",
    val nextCourse: WidgetCourse? = null,
    val courseRows: List<WidgetCourseRow> = emptyList(),
) {
    companion object {
        fun from(json: JSONObject?): WidgetPanelState {
            if (json == null) {
                return empty()
            }

            val status = PanelStatus.from(json.optString("status"))
            val message = json.optString("message")
            val nextCourse = json.optJSONObject("nextCourse")?.let(WidgetCourse::from)
            val rows = json.optJSONArray("courseRows")?.let(WidgetCourseRow::from) ?: emptyList()
            return WidgetPanelState(status, message, nextCourse, rows)
        }

        fun empty(): WidgetPanelState {
            return WidgetPanelState(PanelStatus.EMPTY, "今天暂无课程")
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
    val timeText: String,
    val roomText: String,
    val remainingText: String,
) {
    companion object {
        fun from(json: JSONObject?): WidgetCourse {
            return WidgetCourse(
                name = json?.optString("name").orEmpty(),
                timeText = json?.optString("timeText").orEmpty(),
                roomText = json?.optString("roomText").orEmpty(),
                remainingText = json?.optString("remainingText").orEmpty(),
            )
        }
    }
}

private data class WidgetCourseRow(
    val name: String,
    val timeText: String,
    val roomText: String,
) {
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
                timeText = json?.optString("timeText").orEmpty(),
                roomText = json?.optString("roomText").orEmpty(),
            )
        }
    }
}

private data class RowIds(
    val containerId: Int,
    val nameId: Int,
    val detailId: Int,
)
