package com.studytrack.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class StudyTrackWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val todayLabel = widgetData.getString("studytrack_widget_today_label", "No classes today")
          ?: "No classes today"
      val nextExam = widgetData.getString("studytrack_widget_next_exam", "No upcoming exam")
          ?: "No upcoming exam"
      val streak = widgetData.getInt("studytrack_widget_streak", 0)

      val views = RemoteViews(context.packageName, R.layout.studytrack_widget).apply {
        setTextViewText(R.id.widget_today_classes_value, todayLabel)
        setTextViewText(R.id.widget_next_exam_value, nextExam)
        setTextViewText(R.id.widget_streak_value, "$streak day streak")
      }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
