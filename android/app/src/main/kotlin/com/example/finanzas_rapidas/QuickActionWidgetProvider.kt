package com.example.finanzas_rapidas

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class QuickActionWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.quick_action_widget).apply {
                val expenseIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("finanzasrapidas://addExpense")
                )
                setOnClickPendingIntent(R.id.btn_add_expense, expenseIntent)

                val incomeIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("finanzasrapidas://addIncome")
                )
                setOnClickPendingIntent(R.id.btn_add_income, incomeIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
