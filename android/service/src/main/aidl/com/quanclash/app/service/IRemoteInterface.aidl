// IRemoteInterface.aidl
package com.quanclash.app.service;

import com.quanclash.app.service.ICallbackInterface;
import com.quanclash.app.service.IEventInterface;
import com.quanclash.app.service.IResultInterface;
import com.quanclash.app.service.IVoidInterface;
import com.quanclash.app.service.models.VpnOptions;
import com.quanclash.app.service.models.NotificationParams;

interface IRemoteInterface {
    void invokeAction(in String data, in ICallbackInterface callback);
    void quickSetup(in String initParamsString, in String setupParamsString, in ICallbackInterface callback, in IVoidInterface onStarted);
    void updateNotificationParams(in NotificationParams params);
    void startService(in VpnOptions options, in long runTime, in IResultInterface result);
    void stopService(in IResultInterface result);
    void setEventListener(in IEventInterface event);
    void setCrashlytics(in boolean enable);
    long getRunTime();
}