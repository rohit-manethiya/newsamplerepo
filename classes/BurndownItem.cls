/**
 * Created by ferhatozsavran on 5/31/18.
 */

public with sharing class BurndownItem {
    // Wrapper class
    public String dates { get; set; }
    public Decimal idealValue { get; set; }
    public Decimal actualValue { get; set; }

    public burndownItem(){}

    public burndownItem(String dt, Decimal ideal, Decimal actual) {
        this.dates = dt;
        this.idealValue = ideal;
        this.actualValue = actual;
    }
}