// ICallbackInterface.aidl
package com.quanclash.app.service;

import com.quanclash.app.service.IAckInterface;

interface ICallbackInterface {
    oneway void onResult(in byte[] data,in boolean isSuccess, in IAckInterface ack);
}