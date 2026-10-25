package io.github.tissyboxc.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import es.antonborri.home_widget.HomeWidgetPlugin
import io.github.tissyboxc.R
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.concurrent.TimeUnit
import kotlin.math.max
import kotlin.math.min

class CourseWidgetRefreshWorker(
    context: Context,
    params: WorkerParameters,
) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        CourseWidgetScheduler.refreshAndSchedule(applicationContext)
        return Result.success()
    }
}

class CourseWidgetAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        CourseWidgetScheduler.ensureScheduled(context)
        CourseWidgetScheduler.refreshAndSchedule(context)
    }
}

object CourseWidgetScheduler {
    private const val WORK_NAME = "course_widget_periodic_refresh"
    private const val ACTION_REFRESH = "io.github.tissyboxc.widget.ACTION_REFRESH"
    private const val PAYLOAD_KEY = "course_widget_payload"
    private const val SETTINGS_KEY = "course_widget_settings"
    private const val COURSES_KEY = "course_widget_courses"
    private const val MIN_ALARM_DELAY_MS = 60_000L
    private const val FALLBACK_INTERVAL_MS = 30L * 60L * 1000L

    fun ensureScheduled(context: Context) {
        val appContext = context.applicationContext
        val work = PeriodicWorkRequestBuilder<CourseWidgetRefreshWorker>(
            30,
            TimeUnit.MINUTES,
        ).build()
        WorkManager.getInstance(appContext).enqueueUniquePeriodicWork(
            WORK_NAME,
            ExistingPeriodicWorkPolicy.UPDATE,
            work,
        )
        scheduleNextAlarm(appContext)
    }

    fun cancel(context: Context) {
        val appContext = context.applicationContext
        WorkManager.getInstance(appContext).cancelUniqueWork(WORK_NAME)
        val alarmManager = appContext.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(alarmIntent(appContext))
    }

    fun refreshAndSchedule(context: Context) {
        val appContext = context.applicationContext
        rebuildPayload(appContext)
        requestWidgetUpdates(appContext)
        scheduleNextAlarm(appContext)
    }

    private fun rebuildPayload(context: Context) {
        val prefs = HomeWidgetPlugin.getData(context)
        val settings = WidgetSettings.from(prefs.getString(SETTINGS_KEY, null))
        val courses = WidgetCourseData.listFrom(prefs.getString(COURSES_KEY, null))
        if (settings == null || courses.isEmpty()) {
            return
        }

        val now = Calendar.getInstance()
        val todayCourses = courses
            .filter { it.dayOfWeek == appDayOfWeek(now) && it.matchesWeek(currentWeek(settings, now)) }
            .sortedWith(compareBy<WidgetCourseData> { it.dayOfWeek }.thenBy { it.startLesson })

        val small = buildPanelState(context, settings, todayCourses, now)
        val medium = buildPanelState(context, settings, todayCourses, now)
        val payload = JSONObject()
            .put("small", small)
            .put("medium", medium)
            .toString()
        prefs.edit().putString(PAYLOAD_KEY, payload).apply()
    }

    private fun buildPanelState(
        context: Context,
        settings: WidgetSettings,
        todayCourses: List<WidgetCourseData>,
        now: Calendar,
    ): JSONObject {
        val state = JSONObject()
            .put("dateText", todayWithWeekday(context, now))
            .put("weekText", context.getString(R.string.course_widget_week_text, currentWeek(settings, now)))

        if (todayCourses.isEmpty()) {
            return state
                .put("status", "empty")
                .put("message", context.getString(R.string.course_widget_no_courses_today))
        }

        val hasUsableTime = todayCourses.any {
            minuteForLesson(settings, it.startLesson) != null &&
                minuteForLesson(settings, it.endLesson) != null
        }
        val visibleCourses = if (hasUsableTime) {
            val currentMinute = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
            todayCourses.filter {
                val endMinute = minuteForLesson(settings, it.endLesson)
                endMinute != null && currentMinute <= endMinute
            }
        } else {
            todayCourses
        }

        if (hasUsableTime && visibleCourses.isEmpty()) {
            return state
                .put("status", "finished")
                .put("message", context.getString(R.string.course_widget_finished_title))
        }

        return state
            .put("status", "ready")
            .put("courseRows", JSONArray().apply {
                visibleCourses.forEach { put(it.toRowJson(context, settings)) }
            })
            .apply {
                visibleCourses.firstOrNull()?.let {
                    put("nextCourse", it.toCourseJson(context, settings, now))
                }
            }
    }

    private fun requestWidgetUpdates(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        listOf(WidgetUpdateReceiver::class.java, WidgetMediumReceiver::class.java).forEach { cls ->
            val ids = manager.getAppWidgetIds(ComponentName(context, cls))
            if (ids.isNotEmpty()) {
                context.sendBroadcast(Intent(context, cls).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                    putExtra(HomeWidgetPlugin.TRIGGERED_FROM_HOME_WIDGET, true)
                })
            }
        }
    }

    private fun scheduleNextAlarm(context: Context) {
        val triggerAt = nextRefreshTime(context)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.setWindow(
            AlarmManager.RTC_WAKEUP,
            triggerAt,
            5L * 60L * 1000L,
            alarmIntent(context),
        )
    }

    private fun nextRefreshTime(context: Context): Long {
        val prefs = HomeWidgetPlugin.getData(context)
        val settings = WidgetSettings.from(prefs.getString(SETTINGS_KEY, null))
        val courses = WidgetCourseData.listFrom(prefs.getString(COURSES_KEY, null))
        val now = Calendar.getInstance()
        val nowMillis = now.timeInMillis
        val candidates = mutableListOf<Long>()

        if (settings != null && courses.isNotEmpty()) {
            val todayCourses = courses.filter {
                it.dayOfWeek == appDayOfWeek(now) && it.matchesWeek(currentWeek(settings, now))
            }
            for (course in todayCourses) {
                minuteForLesson(settings, course.startLesson)?.let {
                    candidates += todayAtMinute(now, it).timeInMillis
                }
                minuteForLesson(settings, course.endLesson)?.let {
                    candidates += todayAtMinute(now, it).timeInMillis
                }
            }
        }

        val tomorrow = now.clone() as Calendar
        tomorrow.add(Calendar.DAY_OF_YEAR, 1)
        tomorrow.set(Calendar.HOUR_OF_DAY, 0)
        tomorrow.set(Calendar.MINUTE, 1)
        tomorrow.set(Calendar.SECOND, 0)
        tomorrow.set(Calendar.MILLISECOND, 0)
        candidates += tomorrow.timeInMillis

        return candidates
            .filter { it > nowMillis + MIN_ALARM_DELAY_MS }
            .minOrNull()
            ?: (nowMillis + FALLBACK_INTERVAL_MS)
    }

    private fun alarmIntent(context: Context): PendingIntent {
        return PendingIntent.getBroadcast(
            context,
            7301,
            Intent(context, CourseWidgetAlarmReceiver::class.java).setAction(ACTION_REFRESH),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}

private data class WidgetSettings(
    val maxWeeks: Int,
    val durationPerLesson: Int,
    val startTimes: List<String>,
    val termStartDate: String,
) {
    companion object {
        fun from(raw: String?): WidgetSettings? {
            if (raw.isNullOrBlank()) return null
            return try {
                val json = JSONObject(raw)
                val startTimes = mutableListOf<String>()
                val array = json.optJSONArray("startTimes")
                if (array != null) {
                    for (i in 0 until array.length()) {
                        startTimes += array.optString(i)
                    }
                }
                WidgetSettings(
                    maxWeeks = json.optInt("maxWeeks", 18),
                    durationPerLesson = json.optInt("durationPerLesson", 45),
                    startTimes = startTimes,
                    termStartDate = json.optString("termStartDate"),
                )
            } catch (_: Exception) {
                null
            }
        }
    }
}

private data class WidgetCourseData(
    val name: String,
    val startWeek: Int,
    val endWeek: Int,
    val dayOfWeek: Int,
    val startLesson: Int,
    val endLesson: Int,
    val location: String,
    val activeWeeks: List<Int>,
) {
    fun matchesWeek(week: Int): Boolean {
        return if (activeWeeks.isNotEmpty()) {
            activeWeeks.contains(week)
        } else {
            week in startWeek..endWeek
        }
    }

    fun toRowJson(context: Context, settings: WidgetSettings): JSONObject {
        return JSONObject()
            .put("name", name.ifBlank { context.getString(R.string.course_widget_unnamed_course) })
            .put("startTimeText", formatMinute(minuteForLesson(settings, startLesson)))
            .put("timeText", timeRange(settings, this).ifBlank {
                context.getString(R.string.course_widget_time_not_configured)
            })
            .put("lessonText", lessonText(context, this))
            .put("roomText", location.ifBlank { context.getString(R.string.course_widget_room_not_filled) })
    }

    fun toCourseJson(context: Context, settings: WidgetSettings, now: Calendar): JSONObject {
        val startMinute = minuteForLesson(settings, startLesson)
        val endMinute = minuteForLesson(settings, endLesson)
        val currentMinute = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        val targetMinute = if (startMinute != null && currentMinute < startMinute) {
            startMinute
        } else {
            endMinute ?: startMinute ?: currentMinute
        }
        val remaining = targetMinute - currentMinute
        val startText = formatMinute(startMinute)
        val endText = formatMinute(endMinute)
        return toRowJson(context, settings)
            .put(
                "timeText",
                if (startText.isNotEmpty() && endText.isNotEmpty()) {
                    "$startText-$endText"
                } else {
                    context.getString(R.string.course_widget_time_not_configured)
                },
            )
            .put(
                "remainingText",
                if (remaining <= 0) {
                    context.getString(R.string.course_widget_started)
                } else {
                    context.getString(
                        R.string.course_widget_remaining,
                        formatDuration(context, remaining),
                    )
                },
            )
    }

    companion object {
        fun listFrom(raw: String?): List<WidgetCourseData> {
            if (raw.isNullOrBlank()) return emptyList()
            return try {
                val array = JSONArray(raw)
                buildList {
                    for (i in 0 until array.length()) {
                        val json = array.optJSONObject(i) ?: continue
                        val weeks = mutableListOf<Int>()
                        val weekArray = json.optJSONArray("weeks")
                        if (weekArray != null) {
                            for (j in 0 until weekArray.length()) {
                                weeks += weekArray.optInt(j)
                            }
                        }
                        add(
                            WidgetCourseData(
                                name = json.optString("name").trim(),
                                startWeek = json.optInt("startWeek", weeks.firstOrNull() ?: 1),
                                endWeek = json.optInt("endWeek", weeks.lastOrNull() ?: 1),
                                dayOfWeek = json.optInt("dayOfWeek", json.optInt("day", 1)),
                                startLesson = json.optInt("startLesson", json.optInt("startSection", 1)),
                                endLesson = json.optInt("endLesson", json.optInt("endSection", 1)),
                                location = json.optString("location", json.optString("position")).trim(),
                                activeWeeks = weeks.distinct().sorted(),
                            ),
                        )
                    }
                }
            } catch (_: Exception) {
                emptyList()
            }
        }
    }
}

private fun appDayOfWeek(date: Calendar): Int {
    return when (date.get(Calendar.DAY_OF_WEEK)) {
        Calendar.SUNDAY -> 7
        else -> date.get(Calendar.DAY_OF_WEEK) - 1
    }
}

private fun currentWeek(settings: WidgetSettings, today: Calendar): Int {
    if (settings.termStartDate.isBlank()) return 1
    val parts = settings.termStartDate.split("-")
    if (parts.size != 3) return 1
    val start = Calendar.getInstance().apply {
        set(parts[0].toIntOrNull() ?: today.get(Calendar.YEAR), parts[1].toIntOrNull()?.minus(1) ?: 0, parts[2].toIntOrNull() ?: 1, 0, 0, 0)
        set(Calendar.MILLISECOND, 0)
    }
    val todayStart = (today.clone() as Calendar).apply {
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }
    val diffDays = ((todayStart.timeInMillis - start.timeInMillis) / (24L * 60L * 60L * 1000L)).toInt()
    return min(max(diffDays / 7 + 1, 1), settings.maxWeeks)
}

private fun minuteForLesson(settings: WidgetSettings, lesson: Int): Int? {
    val raw = settings.startTimes.getOrNull(lesson - 1)?.replace('：', ':')?.trim().orEmpty()
    val parts = raw.split(":")
    if (parts.size != 2) return null
    val hour = parts[0].toIntOrNull() ?: return null
    val minute = parts[1].toIntOrNull() ?: return null
    if (hour !in 0..24 || minute !in 0..59 || (hour == 24 && minute != 0)) return null
    return hour * 60 + minute
}

private fun todayAtMinute(now: Calendar, minute: Int): Calendar {
    return (now.clone() as Calendar).apply {
        set(Calendar.HOUR_OF_DAY, minute / 60)
        set(Calendar.MINUTE, minute % 60)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }
}

private fun formatMinute(minute: Int?): String {
    if (minute == null || minute < 0) return ""
    return "${(minute / 60).toString().padStart(2, '0')}:${(minute % 60).toString().padStart(2, '0')}"
}

private fun timeRange(settings: WidgetSettings, course: WidgetCourseData): String {
    val start = minuteForLesson(settings, course.startLesson) ?: return ""
    val endStart = minuteForLesson(settings, course.endLesson) ?: return ""
    val end = endStart + settings.durationPerLesson
    return "${formatMinute(start)}-${formatMinute(end % (24 * 60))}"
}

private fun lessonText(context: Context, course: WidgetCourseData): String {
    return if (course.startLesson == course.endLesson) {
        context.getString(R.string.course_widget_lesson_text, course.startLesson)
    } else {
        context.getString(R.string.course_widget_lesson_range_text, course.startLesson, course.endLesson)
    }
}

private fun formatDuration(context: Context, minute: Int): String {
    val hours = minute / 60
    val minutes = minute % 60
    return when {
        hours <= 0 -> context.getString(R.string.course_widget_minutes, minutes)
        minutes <= 0 -> context.getString(R.string.course_widget_hours, hours)
        else -> context.getString(R.string.course_widget_hours_minutes, hours, minutes)
    }
}

private fun todayWithWeekday(context: Context, date: Calendar): String {
    val weekdays = arrayOf(
        context.getString(R.string.course_widget_weekday_sunday),
        context.getString(R.string.course_widget_weekday_monday),
        context.getString(R.string.course_widget_weekday_tuesday),
        context.getString(R.string.course_widget_weekday_wednesday),
        context.getString(R.string.course_widget_weekday_thursday),
        context.getString(R.string.course_widget_weekday_friday),
        context.getString(R.string.course_widget_weekday_saturday),
    )
    return context.getString(
        R.string.course_widget_date_today_weekday,
        weekdays[(date.get(Calendar.DAY_OF_WEEK) - 1).coerceIn(0, weekdays.lastIndex)],
    )
}
