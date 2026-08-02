package com.soldesk.dto;

public class SseSendRequest {
    String eventName;
    Object message;
    public String getEventName() {
        return eventName;
    }
    public void setEventName(String eventName) {
        this.eventName = eventName;
    }
    public Object getMessage() {
        return message;
    }
    public void setMessage(Object message) {
        this.message = message;
    }

}
