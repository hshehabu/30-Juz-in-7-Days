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
 * Home-screen widget showing today's portion, overall progress and a
 * "Mark done" button. The Flutter side pre-computes localized content for every
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
                R.id.widget_root,
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

            val progressLabel = entry.optString("progressLabel")
            val showProgress = progressLabel.isNotBlank()
            setTextViewText(R.id.widget_progress_label, progressLabel)
            setViewVisibility(R.id.widget_progress_label, if (showProgress) View.VISIBLE else View.GONE)
            setProgressBar(R.id.widget_progress, 100, entry.optInt("progress", 0), false)
            setViewVisibility(R.id.widget_progress, if (showProgress) View.VISIBLE else View.GONE)

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
