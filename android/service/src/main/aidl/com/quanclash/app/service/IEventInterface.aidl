// IEventInterface.aidl
package com.quanclash.app.service;

import com.quanclash.app.service.IAckInterface;

interface IEventInterface {
    oneway void onEvent(in String id, in byte[] data,in boolean isSuccess, in IAckInterface ack);
}