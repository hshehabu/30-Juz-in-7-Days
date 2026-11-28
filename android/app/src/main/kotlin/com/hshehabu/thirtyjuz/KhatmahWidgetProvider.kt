package com.hshehabu.thirtyjuz

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import org.json.JSONObject

/**
 * Home-screen widget showing today's portion, a 7-day progress strip and a
 * "Mark done" pill. The Flutter side pre-computes localized content for every
 * date of the khatmah, so this provider only picks the entry for today and the
 * widget rolls over at midnight without the app running.
 */
class KhatmahWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val entry = currentEntry(widgetData.getString(DATA_KEY, null))

    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.khatmah_widget).apply {
            setOnClickPendingIntent(
                android.R.id.background,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )

            setTextViewText(
                R.id.widget_header,
                entry.optString("header").ifBlank { context.getString(R.string.widget_name) },
            )
            setTextViewText(
                R.id.widget_range,
                entry.optString("range").ifBlank { context.getString(R.string.widget_open_app) },
            )

            val detail = entry.optString("detail")
            setTextViewText(R.id.widget_detail, detail)
            setViewVisibility(R.id.widget_detail, if (detail.isBlank()) View.GONE else View.VISIBLE)

            // Follow the app language, not the device locale.
            setInt(
                android.R.id.background,
                "setLayoutDirection",
                if (entry.optBoolean("rtl", false)) View.LAYOUT_DIRECTION_RTL
                else View.LAYOUT_DIRECTION_LTR,
            )

            val progressLabel = entry.optString("progressLabel")
            setTextViewText(R.id.widget_progress_label, progressLabel)
            setViewVisibility(
                R.id.widget_progress_label,
                if (progressLabel.isBlank()) View.GONE else View.VISIBLE,
            )

            // One segment per day: c = read, t = today, anything else = not yet.
            val days = entry.optString("days")
            if (days.length == SEGMENT_IDS.size) {
              setViewVisibility(R.id.widget_segments, View.VISIBLE)
              SEGMENT_IDS.forEachIndexed { i, id ->
                setImageViewResource(
                    id,
                    when (days[i]) {
                      'c' -> R.drawable.widget_segment_done
                      't' -> R.drawable.widget_segment_today
                      else -> R.drawable.widget_segment_pending
                    },
                )
              }
            } else {
              setViewVisibility(R.id.widget_segments, View.INVISIBLE)
            }

            val day = entry.optInt("day", 0)
            if (entry.optBoolean("canMark", false) && day > 0) {
              setViewVisibility(R.id.widget_mark_button, View.VISIBLE)
              setTextViewText(
                  R.id.widget_mark_button,
                  entry.optString("markLabel").ifBlank { context.getString(R.string.widget_mark_done) },
              )
              setOnClickPendingIntent(
                  R.id.widget_mark_button,
                  HomeWidgetBackgroundIntent.getBroadcast(
                      context,
                      Uri.parse("thirtyjuz://markdone?day=$day"),
                  ),
              )
            } else {
              setViewVisibility(R.id.widget_mark_button, View.GONE)
            }
          }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  companion object {
    private const val DATA_KEY = "khatmah_widget"

    private val SEGMENT_IDS =
        intArrayOf(
            R.id.widget_seg_1,
            R.id.widget_seg_2,
            R.id.widget_seg_3,
            R.id.widget_seg_4,
            R.id.widget_seg_5,
            R.id.widget_seg_6,
            R.id.widget_seg_7,
        )

    /** Picks today's entry, or the before/after state outside the 7 days. */
    fun currentEntry(raw: String?): JSONObject {
      if (raw.isNullOrBlank()) return JSONObject()
      return try {
        val root = JSONObject(raw)
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val dates = root.optJSONObject("dates")
        val start = root.optString("start")
        when {
          dates != null && dates.has(today) -> dates.getJSONObject(today)
          start.isNotEmpty() && today < start -> root.optJSONObject("before") ?: JSONObject()
          else -> root.optJSONObject("after") ?: JSONObject()
        }
      } catch (e: Exception) {
        JSONObject()
      }
    }
  }
}
