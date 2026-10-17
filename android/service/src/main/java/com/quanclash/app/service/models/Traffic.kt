package com.quanclash.app.service.models

import com.quanclash.app.common.GlobalState
import com.quanclash.app.common.formatBytes
import com.quanclash.app.core.Core
import com.google.gson.Gson

data class Traffic(
    val up: Long,
    val down: Long,
)

val Traffic.speedText: String
    get() = "${up.formatBytes}/s↑  ${down.formatBytes}/s↓"

fun Core.getSpeedTrafficText(onlyStatisticsProxy: Boolean): String {
    try {
        val res = getTraffic(onlyStatisticsProxy)
        val traffic = Gson().fromJson(res, Traffic::class.java)
        return traffic.speedText
    } catch (e: Exception) {
        GlobalState.log(e.message + "")
        return ""
    }
}