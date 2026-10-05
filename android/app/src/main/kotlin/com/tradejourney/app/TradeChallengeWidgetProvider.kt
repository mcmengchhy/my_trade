package com.tradejourney.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class TradeChallengeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val challengeName = widgetData.getString("challenge_name", "Trade Journey")
                val currentBalance = widgetData.getString("current_balance", "$0.00")
                val requiredToday = widgetData.getString("required_today", "+$0.00 req.")
                val paceStatus = widgetData.getString("pace_status", "On Track")
                val traderLevel = widgetData.getString("trader_level", "Lvl 1 Novice")
                val chartPath = widgetData.getString("chart_path", null)

                setTextViewText(R.id.widget_title, challengeName)
                setTextViewText(R.id.widget_balance, currentBalance)
                setTextViewText(R.id.widget_required, requiredToday)
                setTextViewText(R.id.widget_pace, paceStatus)
                setTextViewText(R.id.widget_level, traderLevel)

                val isNoActiveChallenge = challengeName == "No Active Challenge" || challengeName == "Widget Disabled"

                if (!isNoActiveChallenge && !chartPath.isNullOrEmpty()) {
                    val bitmap = BitmapFactory.decodeFile(chartPath)
                    if (bitmap != null) {
                        setImageViewBitmap(R.id.widget_chart_image, bitmap)
                        setViewVisibility(R.id.widget_chart_image, View.VISIBLE)
                        setViewVisibility(R.id.widget_balance_layout, View.GONE)
                    } else {
                        setViewVisibility(R.id.widget_chart_image, View.GONE)
                        setViewVisibility(R.id.widget_balance_layout, View.VISIBLE)
                    }
                } else {
                    setViewVisibility(R.id.widget_chart_image, View.GONE)
                    setViewVisibility(R.id.widget_balance_layout, View.VISIBLE)
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
