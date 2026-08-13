package com.example.be_yourself

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class QuoteWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        try {
            appWidgetIds.forEach { widgetId ->
                val views = RemoteViews(context.packageName, R.layout.widget_quote_layout).apply {
                    val quoteText = widgetData.getString("quote_text", "Kendine inan, yapabileceklerinin sınırı yoktur.")
                    val quoteAuthor = widgetData.getString("quote_author", "BeYourself")
                    val quoteCategory = widgetData.getString("quote_category", "Günün Alıntısı")
                    val quoteId = widgetData.getString("quote_id", "")

                    setTextViewText(R.id.widget_quote_text, "\"$quoteText\"")
                    setTextViewText(R.id.widget_quote_author, "— $quoteAuthor")
                    setTextViewText(R.id.widget_quote_category, quoteCategory)

                    // Launch app with deep link uri on widget click
                    val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("beyourself://quote?id=$quoteId")
                    )
                    setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                }
                appWidgetManager.updateAppWidget(widgetId, views)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
