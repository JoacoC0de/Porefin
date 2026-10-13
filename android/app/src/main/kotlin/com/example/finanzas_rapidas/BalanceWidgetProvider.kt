package com.example.finanzas_rapidas

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class BalanceWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.balance_widget).apply {
                val balance = widgetData.getString("balance", "Bs 0,00")
                val income = widgetData.getString("income", "Bs 0,00")
                val expense = widgetData.getString("expense", "Bs 0,00")

                setTextViewText(R.id.tv_balance, balance)
                setTextViewText(R.id.tv_income, income)
                setTextViewText(R.id.tv_expense, expense)

                val openIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("finanzasrapidas://open")
                )
                setOnClickPendingIntent(R.id.widget_container, openIntent)

                val addExpenseIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("finanzasrapidas://addExpense")
                )
                setOnClickPendingIntent(R.id.btn_quick_add, addExpenseIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
