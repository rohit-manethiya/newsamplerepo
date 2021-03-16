/**
 * This will be used as a single class with generic methods for new UI messages and changes
 */
public with sharing class UIDesignHelper {
    /**
     * This is used to show user friendly warning message if a user do not have access to the object (access, query, create, update, delete, ...)
     *
     * @param objectLabelName name of the object, for instance; Schema.SObjectType.Git_Org_Commit__c.getLabel()
     */
    public static void warningMessageOLSFLS(String objectLabelName) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Insufficient_Access_Rights));
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Related_Object + ' ' + objectLabelName));
    }

    /**
     * This method is in use to show page messages based on your needs dynamically
     *
     * @param severityLevel the level of your message - usage exp: ApexPages.Severity.Warning
     * available options for severityLevel parameter : Confirm, info, fatal, warning, error
     * @param message2Show the message that will appear on the page
     */
    public static void genericWarningMessage(ApexPages.Severity severityLevel, Object message2Show) {
        ApexPages.addMessage(new ApexPages.Message(severityLevel, message2Show.toString()));
    }

    /**
     * This method is in use to show page messages based on your needs dynamically
     *
     * @param severityLevel the level of your message - usage exp: ApexPages.Severity.Warning
     * available options for severityLevel parameter : Confirm, info, fatal, warning, error
     * @param message2ShowList messages that will appear on the page
     */
    public static void genericWarningMessage(ApexPages.Severity severityLevel, List<Object> message2ShowList) {
        for(Object msg : message2ShowList) {
            ApexPages.addMessage(new ApexPages.Message(severityLevel, msg.toString()));
        }
    }

    /**
     * This method is in use to show page messages based on your needs dynamically
     *
     * @param severityLevel the level of your message - usage exp: 'success' 'warning' 'error'
     * @param message2ShowList messages that will appear on the page
     */
    public static Map<String, List<Object>> genericWarningMessage(String severityLevel, List<Object> message2ShowList) {
        Map<String, List<Object>> pageMessagesMap = new Map<String, List<Object>>();
        pageMessagesMap.put(severityLevel, message2ShowList);
        return pageMessagesMap;
    }

    /**
     * This method is in use to show page messages based on your needs dynamically
     *
     * @param severityLevel the level of your message - usage exp: 'success' 'warning' 'error'
     * @param message2ShowList messages that will appear on the page
     * @param existingMessageMap messages map that will be checked and returned back after new messages added
     */
    public static Map<String, Set<Object>> accumulativeGenericWarningMessage(String severityLevel, List<Object> message2ShowList, Map<String, Set<Object>> existingMessageMap) {
        if(existingMessageMap.containsKey(severityLevel)) {
            existingMessageMap.get(severityLevel).addAll(message2ShowList);
        } else {
            Set<Object> messagesSet = new Set<Object>();
            messagesSet.addAll(message2ShowList);
            existingMessageMap.put(severityLevel, messagesSet);
        }
        return existingMessageMap;
    }

    /**
     * This is used to show user friendly error message if job fail in try{} code block
     *
     * @param ex Catch exception
     *
     * @return String value of the stacktrace
     */
    public static String catchExceptionMessage(Exception ex) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        return ex.getStackTraceString();
    }

    /**
     * This method is used to clear page messages
     */
    public static void clearPageMessages() {
        ApexPages.getMessages().clear();
    }

    /**
     * Wrapper class for custom exception data
     */
    public class CustomExceptionData {
        public ApexPages.Severity severityLevel;
        public String generalMessage;
        public List<String> stepsToFix;
        public Integer codeLine;
        public String stackTrace;
        public String actionName;

        public CustomExceptionData() {
        }

        public CustomExceptionData(ApexPages.Severity sLevel, String msg, List<String> stepsList, Integer cLine, String sTrace, String actName) {
            this.severityLevel = sLevel;
            this.generalMessage = msg;
            this.stepsToFix = stepsList;
            this.codeLine = cLine;
            this.stackTrace = sTrace;
            this.actionName = actName;
        }
    }
}