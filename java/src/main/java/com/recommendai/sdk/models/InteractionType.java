package com.recommendai.sdk.models;

/**
 * Type of user interaction with a catalogue item.
 */
public enum InteractionType {

    VIEW        ("view"),
    CLICK       ("click"),
    PURCHASE    ("purchase"),
    LIKE        ("like"),
    DISLIKE     ("dislike"),
    RATING      ("rating"),
    CART_ADD    ("cart_add"),
    CART_REMOVE ("cart_remove");

    private final String value;

    InteractionType(String value) { this.value = value; }

    /** The string value sent to / received from the API. */
    public String getValue() { return value; }

    @Override
    public String toString() { return value; }
}
