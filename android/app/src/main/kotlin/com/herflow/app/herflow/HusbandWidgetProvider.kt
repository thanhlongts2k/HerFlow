package com.herflow.app.herflow

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * HusbandWidgetProvider — AppWidget Provider cho Home Screen Widget của Chồng.
 *
 * Widget hiển thị trạng thái chu kỳ và tâm trạng của Vợ hôm nay trực tiếp
 * trên màn hình chính của Chồng. Dữ liệu được đồng bộ qua home_widget plugin
 * (SharedPreferences nội bộ) sau mỗi lần PartnerSyncController đẩy trạng thái mới.
 *
 * Cấu trúc dữ liệu SharedPreferences (key - value):
 *   "phase_name"   → String: tên giai đoạn hiện tại (ví dụ: "Giai Đoạn Nang Trứng")
 *   "mood_summary" → String: tóm tắt tâm trạng (ví dụ: "Năng lượng cao 🌟")
 *   "tip_for_today"→ String: lời khuyên cho Chồng hôm nay
 */
class HusbandWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)

            val phaseName   = widgetData.getString("phase_name", "Chưa có dữ liệu") ?: "Chưa có dữ liệu"
            val moodSummary = widgetData.getString("mood_summary", "") ?: ""
            val tip         = widgetData.getString("tip_for_today", "Hãy quan tâm đến vợ hôm nay 💕") ?: ""

            val displayText = buildString {
                append(phaseName)
                if (moodSummary.isNotEmpty()) append(" • $moodSummary")
            }
            val tipText = tip.take(80) // Cắt ngắn để không tràn widget

            val views = RemoteViews(context.packageName, R.layout.husband_widget_layout).apply {
                setTextViewText(R.id.widget_title, displayText)
                setTextViewText(R.id.widget_phase, tipText)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
